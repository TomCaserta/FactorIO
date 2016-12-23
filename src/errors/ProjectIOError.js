export default class ProjectIOError extends Error {
  constructor(message, isFactorioError) {
    super(message);
    this.name = this.constructor.name;
    this.message = message;
    this.isFactorioError = isFactorioError;

    if (typeof Error.captureStackTrace === 'function') {
      Error.captureStackTrace(this, this.constructor);
    } else {
      this.stack = (new Error(message)).stack;
    }
  }
}
