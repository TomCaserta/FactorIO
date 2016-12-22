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
    this.cutLine = "";
    this.awaiting = {};
    this.expectChunkNumber = 1;
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
    this.on('start', () => {

      setTimeout(() => {
        this.send(new LuaCommand("print(1)", { isSilent: false, serverOnly: false}));
        this.send(new LuaCommand("print(1)", { isSilent: false, serverOnly: false}));
        this.send(new LuaCommand("_G.isServer = true;", { isSilent: true, serverOnly: false}));
        // Load the command splitter
        this.loadLuaFile("interface/spliter.lua");
        // Load the json encoder for bootstrap to work.
        this.loadLuaFile("interface/json_encoder.lua");
        // Load the interface lua script
        this.loadLuaFile("interface/bootstrap.lua");
        // load the serializers
        this.loadLuaFile("interface/serialize.lua");
        setTimeout(() => {
          this.emit("ready", 1);
        }, 100);
      }, 1000);
    });
  }

  /** Functions **/

  send (command) {
    let packets =  command.getPackets();
    packets.forEach((packet) => {
      console.log("ProjectIO> ", packet,"\n");
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
    //console.log(line);
    if (words.length >= 3) {
      if (words[1] == "Factorio" && words[2] == "initialised") {
        this.emit("start", 1);
      }
    }
    if (line.indexOf("Cannot execute command.") != -1) {
      console.error(line);
    }
    let isStartJSON = words[0] == "FACTORIO_JSON";
    if (this.debug) {
      //console.log(arguments);
      if( this.debugLines-- <= 0) {
        this.debug = false;
      }
    }
    if (isStartJSON) {
      let chunk = line.substr(words[0].length+words[1].length+2, line.length-1);
      let amountIndication = words[1].split("/");
      let portion = parseInt(amountIndication[0]);
      let total = parseInt(amountIndication[1]);
      let json = this.cutLine + chunk;
      console.log("<RECIEVED< JSON PART",portion,"OF",total,"LENGTH",line.length, "SUBSTR", words[0].length+words[1].length+2, line.length-1);
      if (portion != this.expectChunkNumber) {
        throw "JSON Mismatch received chunk "+portion+" expected "+this.expectChunkNumber;
      }
      this.expectChunkNumber = portion+1;
      if (portion != total && line.length < 2000) { // Magic number to be replaced.
        console.log("Enabling debug mode for the next 10 lines, mismatch of length of json found.");
        console.log(arguments);
        this.debug = true;
        this.debugLines = 10;
      }
      if (portion >= total) {
        console.log("<RECIEVED< FULL JSON RESPONSE RECEIVED, PARSING");
        try {
          let results = JSON.parse(json);
          this.cutLine = "";
          if (this.awaiting.hasOwnProperty(results.id)){
            let responder = this.awaiting[results.id];
            responder.resolve(results.result);
            delete this.awaiting[results.id];
          }
          //console.log("<RECIEVED<",json);
        }
        catch(e) {
          const fs = require("fs");
           fs.writeFileSync("debug/json.json", json);
          console.log("Error in parsing JSON response", e, "dumped to debug output");
        }

          this.expectChunkNumber = 0;
      }
      else {
          this.cutLine = json;
      }
    }
  }

}
