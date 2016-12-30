import ProjectIOError from "./ProjectIOError";

export default class JsonParseError extends ProjectIOError {
  constructor (jsonError) {
    super(jsonError.message, false);
    this.jsonError = jsonError;
  }
}
