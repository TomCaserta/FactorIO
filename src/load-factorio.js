import {findExecutableDirectory, findWorkingDirectory, getAppDirectory} from "./find-factorio";
import pty from "pty.js";
import ini from "ini";
import fs from "fs";

export function setUpNewEnvironment (name) {
  let APP_DIR = getAppDirectory();

  const newConfigPath = APP_DIR+"\\config-"+name+".ini";
  const config = ini.parse(fs.readFileSync(APP_DIR+"\\config.ini", { encoding: "utf8" }));

  config.path["write-data"] = "__PATH__system-write-data__/"+name;

  fs.writeFileSync(newConfigPath, ini.encode(config));

  return newConfigPath;
}

function startFactorio (options = { environment: null, args: [], cwd: "" }) {
  const WORKING_DIR = findWorkingDirectory();
  const FACTORIO_LOCATION = findExecutableDirectory();
  const { args, environment, cwd } = options;

  console.log("Starting factorio at", FACTORIO_LOCATION, args)
  if (environment != null) {
    console.log("Setting up environement ", environment);
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
  const factorio = pty.spawn(FACTORIO_LOCATION, args, {cwd: cwd, env: {
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
  cols: 200000
  });
  return factorio;
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
