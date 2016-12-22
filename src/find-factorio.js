import fs from "fs";
import path from "path";

import config from "config.js";

let DIRECTORY_FOUND = false;
let FACTORIO_DIRECTORY = null;
let BINARY_NAME = "factorio.exe";
let FACTORIO_LOCATION = null;
let WORKING_DIR = null;
let APP_DIR = config("data_path", resolve("%APPDATA%\\Factorio\\config"));

// TODO: Improve resolvers to be cross platform.
const search_directories = [
   '%appdata%\\Factorio',
   '%PROGRAMFILES%\\Steam\\steamapps\\common\\Factorio\\bin\\x64',
   '%PROGRAMFILES(x86)%\\Steam\\steamapps\\common\\Factorio\\bin\\x64'
];


export function findExecutableDirectory () {
    if (DIRECTORY_FOUND) return FACTORIO_DIRECTORY;

    if (config.has("binary_path")) {
      FACTORIO_DIRECTORY = config.get("binary_path");
      DIRECTORY_FOUND = true;
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


export function findWorkingDirectory () {
    findExecutableDirectory();
    return WORKING_DIR;
}


export function getAppDirectory () {
  return APP_DIR;
}


function resolve (str) {
  return str.replace(/%([^%]+)%/g, function(_,n) {
    return process.env[n];
  })
}
