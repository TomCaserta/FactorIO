import fs from "fs";

import uuid from "uuid/v4";
import luamin from "luamin";
import stripAnsi from "strip-ansi";
import EventEmitter from "event-emitter-es6";

import JsonChunk from "./JsonChunk";
import FactoriCommandError from "../errors/FactorioCommandError";
import JsonChunkIncompleteError from "../errors/JsonChunkIncompleteError";

// Commands
import LuaCommand from "../commands/lua-command";

export class FactorioInterface extends EventEmitter {

  constructor (child) {
    super();
    // The terminal process that factorio is spawned into
    this.proc = child;

    this.awaiting = {};

    // The current JSON line and next expected chunk number
    this.cutLine = "";
    this.expectChunkNumber = 1;

    this.processTerminalData();

    this.on('start', () => {
      this.initializeInterface();
    });
  }

  /** Functions **/

  send (packets) {
    packets.forEach((packet) => {
      this.emit("sent_packet", packet);
      this.proc.write(packet+"\r\n");
    });
  }

  sendCommand (code, options) {
    return this.send(new LuaCommand(code, options).getPackets());
  }

  loadLuaFile (fileName) {
    const code = fs.readFileSync("./lua-src/"+fileName);
    this.emit("lua_load", fileName)
    this.sendCommand(code.toString("utf8"));
  }

  sendRespond (code) {
    return new Promise((resolve, reject) => {
        const wrappedSource = new LuaCommand(code);
        const id = uuid();
        wrappedSource.wrapResponder(id);
        this.emit("awaiting", id, wrappedSource.getPackets());
        this.send(wrappedSource.getPackets());
        this.awaiting[id] = {
          command: code,
          id: id,
          reject: reject,
          resolve: resolve
        };
     });
  }

  activateConsoleCommands () {
    this.send(new LuaCommand("print(1)", { isSilent: false, serverOnly: false}));
    this.send(new LuaCommand("print(1)", { isSilent: false, serverOnly: false}));
  }

  initializeInterface () {
    this.activateConsoleCommands();

    // Set lua global isServer to be true, cannot set serverOnly to true as
    // the isServer global does not exist yet.
    this.send(new LuaCommand("_G.isServer = true;", { isSilent: true, serverOnly: false}));

    // Load the command splitter
    this.loadLuaFile("interface/spliter.lua");
    // Load the json encoder for bootstrap to work.
    this.loadLuaFile("interface/json_encoder.lua");
    // Load the interface lua script
    this.loadLuaFile("interface/bootstrap.lua");
    // load the serializers
    this.loadLuaFile("interface/serialize.lua");

    // Emit a ready event
    setTimeout(() => {
      this.emit("ready", 1);
    }, 1);
  }

  processTerminalData () {
    let linePart = "";
    this.proc.on("data",  (d) => {
        var lines = d.split(/\n/ig);
        for (let i = 0; i < lines.length; i++) {
          let line = lines[i];
          if (linePart != "") {
            line = linePart + line;
          }
          if (i != lines.length-1 || d.substr(-1) == "\n") {
            this.onReceive(stripAnsi(line).trim());
            linePart = "";
          }
          else {
            // We are waiting for the line to finish chunk it!
            linePart = line;
          }
        }
    });
  }

  isJsonBegin (str) {
    // TODO: Make this dynamic to remove the ability of
    // padding a chat message to 2000 characters
    // and sending a FACTORIO_JSON command to it.
    return str == "FACTORIO_JSON";
  }

  onReceive (line) {
    const words = line.split(" ");
    //console.log(line);
    if (words.length >= 3) {
      if (words[1] == "Factorio" && words[2] == "initialised") {
        this.emit("start", 1);
      }
    }

    if (line.indexOf("Cannot execute command.") != -1) {
      this.emit("error", new FactorioCommandError(line));
    }

    if (this.isJsonBegin(words[0])) {
      let chunk = line.substr(words[0].length+words[1].length+2, line.length-1);
      let amountIndication = words[1].split("/");
      let portion = parseInt(amountIndication[0]);
      let total = parseInt(amountIndication[1]);
      if (portion == 1) {
          if (this.currentJsonChunk != null && !this.currentJsonChunk.isComplete()) {
            let error = new JsonChunkIncompleteError(this.currentJsonChunk);
            this.emit("error", error);
          }
          this.currentJsonChunk = new JsonChunk(total);
      }
      this.currentJsonChunk.addChunk(chunk, portion);

      if (this.currentJsonChunk.isComplete()) {
        try {
          this.emit("json", this.currentJsonChunk);
          this.currentJsonChunk = null;
        }
        catch (e) {
          this.emit("error", new JsonParseError(e));
        }
      }
    }
  }

}
