import luamin from "luamin";
import { text } from "node-text-chunk"
import jsesc from "jsesc";
import md5 from "md5";

export default class LuaCommand {
  constructor (code, {isSilent = true, minify = true, serverOnly = true } = {}) {
    this.code  = code;
    this.isSilent = isSilent;
    this.minify = minify;
    this.hasResponse = false;
    this.serverOnly = serverOnly;
  }


  wrapResponder (id) {
    if (this.hasResponse == true) return;
    // Responder runs only on server...
    this.serverOnly = true;
    // If you are sure you know what you are doing,
    // then you can manually set serverOnly to false
    // Providing you have read this comment.
    // The code to run here will desync the client
    // If it does not have the lua code present on the client.
    this.code = "respondTo("+this.code+",'"+id+"');";
  }

  getCommand () {
    if (!this.isSilent) return "/command ";
    return "/silent-command ";
  }

  getPackets () {
    let code = this.code;
    if (this.serverOnly) {
      code = "if (_G.isServer ~= nil) then;"+this.code+" end;"
    }
    if (this.minify) {
      code  = luamin.minify(code);
    }
    let packets = [];
    if (code.length < 4094) {
      packets.push(this.getCommand() +code);
    }
    else if (this.serverOnly) {
      let codeBefore = "if (_G.isServer ~= nil) then; buf.a('s','";
      let codeAfter  = "'); end;";

      let escaped = jsesc(code);
      let minifiedOutput = "";
      // TODO: Fix actual edge case where if the split code happens on an escaped boundary
      // it splits the code incorrectly and causes an error. For now I have split it
      // with 1000 characters to spare to avoid this.
      // So if there is a lot of escaping going on we might have an issue...
      const splitCode = text(code, 3094 - this.getCommand().length - codeBefore.length - codeAfter.length);

      for (let x = 0; x < splitCode.length; x++) {
        let uM = splitCode[x];
        minifiedOutput += uM;
        let curr = jsesc(uM);
        packets.push(this.getCommand() +codeBefore+curr+codeAfter);
      }
      packets.push(this.getCommand()+" if (_G.isServer ~= nil) then;  buf.e('s'); end;");
      //console.log("ProjectIO To Send> ",minifiedOutput);
      // Uncomment to debug
      const fs = require("fs");
      fs.writeFileSync("./debug/command-"+md5(code)+".min.lua", minifiedOutput);
    }
    else {
      throw new Exception("Cannot send lua as it is too large to send via console. Splitting requires having the splitter across all clients. This is not implemented yet.");
    }
    return packets;
  }
}
