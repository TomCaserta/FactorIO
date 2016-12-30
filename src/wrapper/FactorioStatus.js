export default class FactorioStatus {
  static ERROR = 0;
  static NOT_INITIALIZED = 1;
  static CREATING_ENVIRONMENT = 2;
  static CREATED_ENVIRONMENT = 3;
  static STARTED = 4;
  static STOPPED = 5;

  /** Helper Statuses **/
  static CAN_START = [
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
      if (toCheck[i] == status) {
        return true;
      }
    }
    return false;
  }
}
