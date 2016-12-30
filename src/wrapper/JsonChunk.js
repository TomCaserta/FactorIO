import JsonChunkUnexpectedError from "../errors/JsonChunkUnexpectedError";
import JsonChunkIncompleteError from "../errors/JsonChunkIncompleteError";

export default class JsonChunk {
  constructor (chunkAmount) {
    this.chunks = new Array(chunkAmount);
    this.length = chunkAmount;
    this.receivedChunks = 0;
  }

  isComplete () {
    if (this.receivedChunks == (this.length-1)) {
      return true;
    }
    return false;
  }

  getLength () {
    return this.length;
  }

  getReceived () {
    return this.receivedChunks;
  }

  getObject () {
    if (!this.isComplete()) {
      throw new JsonChunkIncompleteError(this);
    }
    return JSON.parse(this.chunks.join(""));
  }

  addChunk (line, chunkNumber) {
    const chunkIndex = chunkNumber - 1;
    if (chunkNumber > this.length || typeof this.chunks[chunkIndex] !== "undefined") {
      throw new JsonChunkUnexpectedError(this, line, chunkNumber);
    }
    this.chunks.splice(chunkNumber, 1, line);
    this.receivedChunks++;
  }
}
