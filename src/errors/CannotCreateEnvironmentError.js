import ProjectIOError from "./ProjectIOError";

export default class CannotCreateEnvironmentError extends ProjectIOError {
  constructor (wrappedError) {
    super(wrappedError.message, false);
    this.wrappedError = wrappedError;
  }
}
