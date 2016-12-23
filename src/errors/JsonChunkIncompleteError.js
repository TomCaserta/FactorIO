import ProjectIOError from "ProjectIOError";

export default class JsonChunkIncompleteError extends ProjectIOError {
  constructor (chunk) {
    super(`Cannot parse JSON when the chunked JSON has not been fully received yet. Received ${chunk.getReceived()} out of ${chunk.getLength()}`, false);
    this.chunk = chunk;
  }
}
