import ProjectIOError from "./ProjectIOError";
import FactorioStatus from "../wrapper/FactorioStatus";

export default class InvalidStatusError extends ProjectIOError {
  constructor (status, cannotPerformOperation) {
    super(`Cannot ${cannotPerformOperation} when Factorio has a status of ${FactorioStatus.getName(status)}`, false);
  }
}
