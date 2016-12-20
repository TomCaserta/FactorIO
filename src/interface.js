import uuid from "uuid/v4";
import luamin from "luamin";
import fs from "fs";
import stripAnsi from "strip-ansi";
import EventEmitter from "event-emitter-es6";

import LuaCommand from "./commands/lua-command";

export class FactorioInterface extends EventEmitter {

  constructor (child) {
    super();
    this.proc = child;
    this.awaiting = {};
    this.proc.on("data",  (d) => {

        var lines = d.split(/\n/ig);
        for (let i = 0; i < lines.length; i++) {
          this.onReceive(stripAnsi(lines[i]).trim());
        }
    });
    this.on('start', () => {

      setTimeout(() => {
        this.send(new LuaCommand("print(1)", { isSilent: false, serverOnly: false}));
        this.send(new LuaCommand("print(1)", { isSilent: false, serverOnly: false}));
        this.send(new LuaCommand("_G.isServer = true;", { isSilent: true, serverOnly: false}));
        setTimeout(() => {
          this.emit("ready", 1);
        }, 100);
      }, 1000);
    });
  }

  send (command) {
    let packets =  command.getPackets();
    packets.forEach((packet) => {
      this.proc.write(packet+"\r\n");
    });
  }

  loadLuaFile (filename) {
    const code     = fs.readFileSync("./lua-src/"+filename);
    let wrappedSource = new LuaCommand(code.toString("utf8"));

    this.send(wrappedSource);
  }

  sendRespond (code) {
    return new Promise((resolve, reject) => {
        const wrappedSource = new LuaCommand(code);
        const id = uuid();
        wrappedSource.wrapResponder(id);
        this.send(wrappedSource);
        this.awaiting[id] = {
          command: code,
          id: id,
          reject: reject,
          resolve: resolve
        };
     });
  }

  /**
  * Event Handlers
  **/

  onReceive (line) {
    const words = line.split(" ");
    console.log(line);
    if (words.length >= 3) {
      if (words[1] == "Factorio" && words[2] == "initialised") {
        this.emit("start", 1);
      }
    }
    if (words[0] == "FACTORIO_JSON") {
      words.shift();
      try {
        let json = words.join(" ");
        let results = JSON.parse(json);
        if (this.awaiting.hasOwnProperty(results.id)){
          let responder = this.awaiting[results.id];
          responder.resolve(results.result);
          delete this.awaiting[results.id];
        }

      }
      catch(e) {
        console.error(e);
      }
    }
  }

}
