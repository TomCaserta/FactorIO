import EventEmitter from "event-emitter-es6";

class LogStream extends EventEmitter {
  constructor () {
    super();
    this.loggers = [];
  }

  log (application, level, ...params) {
    this.emit("log", level, application, params);
  }

  create (name) {
    this.loggers.push(name);
    return {
      log: this.log.bind(this, name),
      info: this.log.bind(this, name, LogLevel.INFO),
      debug: this.log.bind(this, name, LogLevel.DEBUG),
      warn: this.log.bind(this, name, LogLevel.WARN),
      error: this.log.bind(this, name, LogLevel.ERROR),
    }
  }
}

export class LogLevel {
  static DEBUG = 1;
  static INFO = 2;
  static WARN = 3;
  static ERROR = 4;
}


const Logger = new LogStream();


export default Logger;
