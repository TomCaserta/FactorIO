import {connectToServer, startServerAndLoadMap} from "./load-factorio";
import {FactorioInterface} from "./interface";
import LuaCommand from "./commands/lua-command";
const factorioServer =  startServerAndLoadMap ({ mapName: "test" });
const factorioClient = connectToServer();
const inter = new FactorioInterface(factorioServer.factorio);

function getPlayers () {
  return inter.sendRespond("getPlayers()");
}

inter.on("ready", () => {

  inter.loadLuaFile("functions.lua");

  // todo: check players and then load this..
  inter.sendRespond("getSurfaceTiles(1)").then(function (data) {
    const fs = require("fs");
    fs.writeFileSync("./debug/debug-map.json", JSON.stringify(data, null, 2));
  });
});
