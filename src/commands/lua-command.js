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
      let codeBefore = "buf.a('s','";
      let codeAfter  = "')";
      const splitCode = text(jsesc(code), 4094 - this.getCommand().length - codeBefore.length - codeAfter.length);
      for (let x = 0; x < splitCode.length; x++) {
        let curr = splitCode[x];
        packets.push(this.getCommand() +codeBefore+curr+codeAfter);
      }
      packets.push(this.getCommand()+"buf.e('s');");
    }
    else {
      throw new Exception("Cannot send lua as it is too large to send via console. Splitting requires having the splitter across all clients. This is not implemented yet.");
    }
    return packets;
  }
}
