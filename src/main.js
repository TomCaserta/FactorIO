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
  // Load the command splitter
  inter.loadLuaFile("spliter.lua");
  // Load the json encoder for bootstrap to work.
  inter.loadLuaFile("json_encoder.lua");
  // Load the interface lua script
  inter.loadLuaFile("bootstrap.lua");
  inter.loadLuaFile("serialize.lua");
  inter.loadLuaFile("functions.lua");

  // todo: check players and then load this..
  inter.sendRespond("getSurfaceTiles(1)").then(function (data) {
    const fs = require("fs");
    fs.writeFileSync("./debug/debug-map.json", JSON.stringify(data, null, 2));
  });
});
