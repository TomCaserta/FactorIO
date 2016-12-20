import {connectToServer, startServerAndLoadMap} from "./load-factorio";
import {FactorioInterface} from "./interface";
import LuaCommand from "./commands/lua-command";
const factorioServer =  startServerAndLoadMap ({ mapName: "test" });
const factorioClient = connectToServer();
const inter = new FactorioInterface(factorioServer.factorio);

inter.on("ready", () => {
  // Load the command splitter
  inter.loadLuaFile("spliter.lua");
  // Load the json encoder for bootstrap to work.
  inter.loadLuaFile("json_encoder.lua");
  // Load the interface lua script
  inter.loadLuaFile("bootstrap.lua");
  inter.loadLuaFile("functions.lua");

  setInterval(function () {
    inter.sendRespond("getPlayers()").then(function(resp) {
      console.log(resp);
    }, function (err) {
      console.log(err);
    });
  }, 10000);
});
