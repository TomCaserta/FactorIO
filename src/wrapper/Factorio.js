import pty from "pty.js";
import ini from "ini";
import fsp from "fs-promise";
import path from "path";
import EventEmitter from "event-emitter-es6";
import config from "../utils/config";

import ProjectIOError from "../errors/ProjectIOError";
import CannotCreateEnvironmentError from "../errors/CannotCreateEnvironmentError";
import InvalidStatusError from "../errors/InvalidStatusError";

import Logger from "../utils/log-stream.js";
import FactorioStatus from "./FactorioStatus";
import {findExecutable, findWorkingDirectory, getAppDirectory} from "../utils/find-factorio";

const FactorioLogger = Logger.create("Factorio");

// TODO: Remove config concern out of this file... Its nice for ease of loading, bad for componentizing
export default class Factorio extends EventEmitter {
  constructor (environment, isServer) {
    super();
    this.environmentName = environment;
    this.hasEnvironment = false;
    this.status = FactorioStatus.NOT_INITIALIZED;
    this.isServer = isServer;
    this.child = null;
    FactorioLogger.info("Created Factorio instantiator");
  }

  getChild() {
    return this.child;
  }

  setStatus (status, ...params) {
    if (!Number.isInteger(status)) {
      FactorioLogger.error("Status is invalid", status, "expected an integer value");
      throw new ProjectIOError(`Cannot set status to an ${typeof(status)} object. Make sure you are not passing a status array group.`,false);
    }
    FactorioLogger.info("Changed status from", FactorioStatus.getName(this.status), "to", FactorioStatus.getName(status));
    this.status = status;
    this.emit("status_change", status, ...params);
  }

  isStatus (...statuses) {
    return FactorioStatus.isStatus(this.status, statuses);
  }

  getStatusError (performedOperation) {
    return new InvalidStatusError(this.status, performedOperation);
  }

  async createEnvironment () {
    if (this.status != FactorioStatus.NOT_INITIALIZED) {
      throw this.getStatusError("create a new environment");
    }
    if (this.hasEnvironment) {
      return true;
    }
    this.setStatus(FactorioStatus.CREATING_ENVIRONMENT);
    let APP_DIR = getAppDirectory();
    const newConfigPath = path.join(APP_DIR,"config","config-"+this.environmentName+".ini");

    this.hasEnvironment = true; // Set this before reading/writing data to ensure its available ASAP.

    try {
      const iniData = await fsp.readFile(path.join(APP_DIR,"config","config.ini"), { encoding: "utf8" });
    }
    catch (e) {
      FactorioLogger.error("Cannot create a new environment");
      const error = new CannotCreateEnvironmentError(e)
      this.setStatus(FactorioStatus.ERROR, error);
      this.hasEnvironment = false;
      throw error;
    }

    const config = ini.parse(iniData);


    config.path["write-data"] = "__PATH__system-write-data__/"+this.environmentName;

    try {
      await fsp.writeFile(newConfigPath, ini.encode(config));
      this.setStatus(FactorioStatus.CREATED_ENVIRONMENT);
      FactorioLogger.info("Created a new environment at", newConfigPath);
      return true;
    }
    catch (e) {
      FactorioLogger.error("Cannot create a new environment");
      const error = new CannotCreateEnvironmentError(e)
      this.setStatus(FactorioStatus.ERROR, error);
      this.hasEnvironment = false;
      throw error;
    }
  }

  async start () {
    await this.createEnvironment();
    if (this.isServer) {
      return await this.startServer();
    }
    return await this.startClient();
  }

  startServer ({
    mapName = config("server.map", "_autoSave1"),
    host = config("server.host", "127.0.0.1"),
    port = config("server.port", 30322),
    rcon_port = config("server.rcon.port", 27083),
    rcon_password = config("server.rcon.password", null) } = {}) {

    FactorioLogger.info("Instantiating server at port", port, "on host", host);
    const environment = this.environmentName;

    if (this.isStatus(FactorioStatus.CAN_START)) {
        const APP_DIR = getAppDirectory();

        if (rcon_password == null) {
          FactorioLogger.warn("Creating a new unique random RCON password as none has been specified");
          rcon_password = Math.random().toString(36).slice(-8);
        }

        return {
          factorio: this._spawnFactorio({
            environment: "server-io" ,
            args: [
                "--port",port,
                "--rcon-port", rcon_port,
                "--rcon-password="+rcon_password,
                "--start-server",path.join(APP_DIR,"saves",mapName+".zip")],
          }),
          rcon: {
            password: rcon_password,
            port: rcon_port
          }
        }
    }
    else {
      throw this.getStatusError("start factorio server");
    }
  }


  startClient ({ host = "127.0.0.1", port = config("client.port",30322)} = {}) {
    const APP_DIR = getAppDirectory();
    FactorioLogger.info("Starting Factorio Client, connecting to port", port, "on host", host);
    return startFactorio({
      args: ["--mp-connect="+host+":"+port],
      cwd: APP_DIR
    });
  }

  _spawnFactorio ({ args = [], cwd = "" } = {}) {
    const WORKING_DIR = findWorkingDirectory();
    const FACTORIO_LOCATION = findExecutable();
    const APP_DIR = getAppDirectory();
    const environment = this.environmentName;

    if (environment != null) {
    ///  console.log(WORKING_DIR);
        args.unshift(path.join(APP_DIR,"config","config-"+environment+".ini"));
        args.unshift("-c");
    }
    // Make sure our args are strings
    for (let i = 0; i < args.length; i++) {
      if (typeof args[i] !== "string") {
        args[i] = args[i].toString();
      }
    }

  //  console.log("Starting factorio at ", FACTORIO_LOCATION, "with args:", args)
    /*
      Spawn a new pty.js instance and pass through the environment variables
      that Steam requires just in case this is a steam binary.
     */
    const factorio = pty.spawn(FACTORIO_LOCATION, args, {
      cwd: cwd,
      env: {
        SteamAppId: 427520,
        SteamAppUser: "FactorIO",
        SteamControllerAppId: 427520,
        SteamGameId: 427520,
        STEAMID: "000000000000000000",
        SteamPath: "C:\\Program Files (x86)\\Steam",
        SteamUser: "FactorIO",
        ValvePlatformMutex: "c:/program files (x86)/steam/steam.exe",
        INSTALLDIR: WORKING_DIR + "\\..\\..\\"
      },
      cols: config("advanced.term_width", 2000)
    });
    this.child = factorio;
    FactorioLogger.debug("Spawned new process:",factorio.process);
    return factorio;
  }

  write (data) {
    this.child.write(data);
  }
}
