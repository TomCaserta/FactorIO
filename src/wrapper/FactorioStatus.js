export class FactorioStatus {
  static const ERROR = 0;
  static const NOT_INITIALIZED = 1;
  static const CREATING_ENVIRONMENT = 2;
  static const CREATED_ENVIRONMENT = 3;
  static const STARTED = 4;
  static const STOPPED = 5;

  /** Helper Statuses **/
  static const CAN_START = [
    FactorioStatus.CREATED_ENVIRONMENT,
    FactorioStatus.STOPPED
  ]

  static getName(n) {
    for (let key in FactorioStatus) {
      if (FactorioStatus.hasOwnProperty(key)) {
        if (FactorioStatus[key] == n) {
          return key;
        }
      }
    }
    return null;
  }

  static isStatus (status, statuses) {
    if (!Array.isArray(statuses)) {
      statuses = [statuses];
    }
    let toCheck = [];
    for (let i = 0; i < statuses.length; i++) {
      const curStatus = statuses[i];
      if (Array.isArray(curStatus)) {
        toCheck.push(...curStatus);
      }
      else {
        toCheck.push(curStatus);
      }
    }
    for (let i = 0; i < toCheck.length; i++) {
      if (toCheck[i] == n) {
        return true;
      }
    }
    return false;
  }
}
