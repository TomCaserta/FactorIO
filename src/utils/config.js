import config from "config";
import Logger from "./log-stream.js";

const ConfigLogger = Logger.create("Config");
/**
 * Fetches a config value by [key] returns [def] if none exists
 * @param  {string}  key The key to find
 * @param  {dynamic} def The default value
 * @return {dynamic}     The config value if it exists, default if not.
 */
export default function configDefault(key, def) {
  ConfigLogger.info("Fetching data for",key);
  if (config.has(key)) return config.get(key)
  else return def;
}
