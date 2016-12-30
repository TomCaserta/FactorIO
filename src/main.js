import Factorio from "./wrapper/Factorio";
import FactorioInterface from "./wrapper/FactorioInterface";
import LuaCommand from "./commands/lua-command";
import config from "./utils/config";
import Logger from "./utils/log-stream.js";

const MainLogger = Logger.create("main");

const factorioServer = new Factorio(config("server.environment", "server-io"), true);
const factorioClient = new Factorio("", false);
let serverInterface = null;
factorioClient.start().then(function () {
  console.log("Started factorio client.");
});

function getPlayers () {
  return inter.sendRespond("getPlayers()");
}


factorioServer.start().then(function () {
  serverInterface = new FactorioInterface(factorioServer);

  serverInterface.on("ready", () => {

    serverInterface.loadLuaFile("functions.lua");

    // todo: check players and then load this..
    // inter.sendRespond("getSurfaceTiles(1)").then(function (data) {
    //   const fs = require("fs");
    //   fs.writeFileSync("./debug/debug-map.json", JSON.stringify(data, null, 2));
    // });
  });
}, function (e) {
  MainLogger.error(e);
});


export {
   factorioServer,
   factorioClient,
   serverInterface
 };
