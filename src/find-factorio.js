const fs = require("fs");

let DIRECTORY_FOUND = false;
let FACTORIO_DIRECTORY = null;
let BINARY_NAME = "factorio.exe";
let FACTORIO_LOCATION = null;
let WORKING_DIR = null;
let APP_DIR = resolve("%APPDATA%\\Factorio\\config");

const search_directories = [
   '%appdata%\\Factorio',
   '%PROGRAMFILES%\\Steam\\steamapps\\common\\Factorio\\bin\\x64',
   '%PROGRAMFILES(x86)%\\Steam\\steamapps\\common\\Factorio\\bin\\x64'
];


export function findExecutableDirectory () {
    if (DIRECTORY_FOUND) return FACTORIO_DIRECTORY;

    search_directories.forEach(function (v) {
      const resolved = resolve(v + "\\" + BINARY_NAME);
      if (fs.existsSync(resolved)) {
        FACTORIO_LOCATION = resolved;
        WORKING_DIR = resolve(v);
      }
    });

    if (!FACTORIO_LOCATION) throw new Error("Factorio binary not found, if you've moved or installed to a non default location please wait for a fix or symlink it yourself in the meantime.");

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
