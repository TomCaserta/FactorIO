import config from "config";

/**
 * Fetches a config value by [key] returns [def] if none exists
 * @param  {string}  key The key to find
 * @param  {dynamic} def The default value
 * @return {dynamic}     The config value if it exists, default if not.
 */
export default function configDefault(key, def) {
  if (config.has(key)) return config.get(key)
  else return def;
}
