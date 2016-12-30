import ProjectIOError from "./ProjectIOError";

export default class JsonChunkUnexpectedError extends ProjectIOError {
  constructor (jsonChunk, chunkReceived, totalChunks) {
    super(`Unexpected JSON Chunk received, received ${chunkReceived} out of ${totalChunks}`, false);
    this.jsonChunk = currentJson;
    this.chunkReceived = chunkReceived;
    this.totalChunks = totalChunks;
  }
}
