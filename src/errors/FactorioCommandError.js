import ProjectIOError from "./ProjectIOError";

export default class FactorioCommandError extends ProjectIOError {
  constructor (commandLine) {
    super(commandLine, true);
  }
}
