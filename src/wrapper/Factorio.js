import pty from "pty.js";
import ini from "ini";
import fsp from "fs-promise";
import EventEmitter from "event-emitter-es6";
import config from "../utils/config";

import ProjectIOError from "../errors/ProjectIOError";
import CannotCreateEnvironmentError from "../errors/CannotCreateEnvironmentError";
import InvalidStatusError from "../errors/InvalidStatusError";

import FactorioStatus from "FactorioStatus";
import {findExecutableDirectory, findWorkingDirectory, getAppDirectory} from "../utils/find-factorio";



export default class Factorio extends EventEmitter {
  constructor (environment, isServer) {
    this.environmentName = environment;
    this.hasEnvironment = false;
    this.status = FactorioStatus.NOT_INITIALIZED;
    this.isServer = isServer;
    this.child = null;
  }

  setStatus (status, ...params) {
    if (Number.isInteger(status)) {
      throw new ProjectIOError(`Cannot set status to an ${typeof(status)} object. Make sure you are not passing a status array group.`,false);
    }
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

    let APP_DIR = getAppDirectory();
    const newConfigPath = APP_DIR+"\\config-"+this.environmentName+".ini";

    this.hasEnvironment = true; // Set this before reading/writing data to ensure its available ASAP.

    try {
      const iniData = await fsp.readFile(APP_DIR+"\\config.ini", { encoding: "utf8" });
    }
    catch (e) {
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
      return true;
    }
    catch (e) {
      const error = new CannotCreateEnvironmentError(e)
      this.setStatus(FactorioStatus.ERROR, error);
      this.hasEnvironment = false;
      throw error;
    }
  }

  async start () {
    await this.createEnvironment();

  }

  startServer ({
    environment = config("server.environment", "server-io"),
    mapName = config("server.map", "_autoSave1"),
    host = config("server.host", "127.0.0.1"),
    port = config("server.port", 30322),
    rcon_port = config("server.rcon.port", 27083),
    rcon_password = config("server.rcon.password", null) } = {}) {

    if (this.isStatus(FactorioStatus.CAN_START)) {
        const APP_DIR = getAppDirectory();

        if (rcon_password == null) rcon_password = Math.random().toString(36).slice(-8);

        return {
          factorio: this._spawnFactorio({
            environment: "server-io" ,
            args: [
                "--port",port,
                "--rcon-port", rconPort,
                "--rcon-password="+rcon_password,
                "--start-server",APP_DIR+"\\..\\saves\\"+mapName+".zip"],
          }),
          rcon: {
            password: rcon_password,
            port: rcon_port
          }
        }
    }
    else {
      throw this.getStatusError("start factorio");
    }
  }

  _spawnFactorio (options = { environment: null, args: [], cwd: "" }) {
    const WORKING_DIR = findWorkingDirectory();
    const FACTORIO_LOCATION = findExecutableDirectory();
    const { args, environment, cwd } = options;

    if (environment != null) {
        const configPath = setUpNewEnvironment(environment);
        args.unshift(configPath);
        args.unshift("-c");
    }
    // Make sure our args are strings
    for (let i = 0; i < args.length; i++) {
      if (typeof args[i] !== "string") {
        args[i] = args[i].toString();
      }
    }

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
    return factorio;
  }
}




export function startServerAndLoadMap ({ environment = null, mapName = "_autoSave1", host = "127.0.0.1", port = 30322, rcon_port = 27083, rcon_password = null } = {}) {
  const APP_DIR = getAppDirectory();


  if (rcon_password == null) rcon_password = Math.random().toString(36).slice(-8);

  return {
    factorio: startFactorio({
      environment: "server-io" ,
      args: ["--port",port, "--rcon-port", rcon_port, "--rcon-password="+rcon_password,"--start-server",APP_DIR+"\\..\\saves\\"+mapName+".zip"],

    }),
    rcon: {
      password: rcon_password,
      port: rcon_port
    }
  }
}


export function connectToServer (options = { host: "127.0.0.1", port: 30322}) {
  const APP_DIR = getAppDirectory();

  return startFactorio({
    args: ["--mp-connect="+options.host+":"+options.port],
    cwd: APP_DIR
  });
}
