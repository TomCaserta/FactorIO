import fs from "fs";
import path from "path";

import config from "./config.js";
import baseConfig from "config";

let DIRECTORY_FOUND = false;
let FACTORIO_DIRECTORY = null;
let BINARY_NAME = config("binary_name", "factorio.exe");
let FACTORIO_LOCATION = null;
let WORKING_DIR = null;
let APP_DIR = config("data_path", resolve("%APPDATA%\\Factorio\\config"));

// TODO: Improve resolvers to be cross platform.
const search_directories = [
   '%appdata%\\Factorio',
   '%PROGRAMFILES%\\Steam\\steamapps\\common\\Factorio\\bin\\x64',
   '%PROGRAMFILES(x86)%\\Steam\\steamapps\\common\\Factorio\\bin\\x64'
];

/**
 * Gets the executable from the config, if none exists in the config
 * then it attempts to find it in the default install locations.
 * @return {string} The path of the factorio binary
 */
export function findExecutable () {
    if (DIRECTORY_FOUND) return FACTORIO_DIRECTORY;

    if (baseConfig.has("binary_path")) {
      FACTORIO_DIRECTORY = path.join(baseConfig.get("binary_path"), BINARY_NAME);
      DIRECTORY_FOUND = true;
      WORKING_DIR = baseConfig.get("binary_path");
      return FACTORIO_DIRECTORY;
    }

    search_directories.forEach(function (v) {
      const resolved = resolve(v);
      const binPath = path.join(resolved,BINARY_NAME);
      if (fs.existsSync(binPath)) {
        FACTORIO_LOCATION = binPath;
        WORKING_DIR = resolved;
      }
    });

    if (!FACTORIO_LOCATION) throw new Error("Factorio binary not found, if you've moved or installed to a non default location please edit the default config.");

   return FACTORIO_LOCATION;
}

/**
 * Finds the working directory for the executable to run in
 * @return {string} The directory factorio resides in
 */
export function findWorkingDirectory () {
    findExecutable();
    return WORKING_DIR;
}

/**
 * Gets the app directory from the config file or uses
 * default windows location
 * @return {string} The application data directory
 */
export function getAppDirectory () {
  return APP_DIR;
}

/**
 * Resolves a string using the process environment variables
 * @param  {string} str string to resolve
 * @return {string}     resolved string
 */
function resolve (str) {
  return str.replace(/%([^%]+)%/g, function(_,n) {
    return process.env[n];
  })
}
