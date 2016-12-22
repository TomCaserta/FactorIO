import glob from "glob";
import fs from "fs";
import cheerio from "cheerio";
import camelcase from "camelcase";

let docLoc = process.argv[2] || "./doc-html/";

let outputTop = `
local messages = {};
local messageI = 1;
function debugLog (message, immediate)
  messages[messageI] = message;
  messageI = messageI+1;
  if immediate then
    dumpLog();
  end
end
_G["debugLog"] = debugLog;

function dumpLog ()
  local str = "";
  for k, v in ipairs(messages) do
    str = str .. "\\n ["..tostring(k).."]" .. tostring(v);
  end
  game.write_file("debug-serializer.log", str, true);
  messages = {};
  messageI = 1;
end
_G["dumpLog"] = dumpLog; -- Great naming

function serializeArrayOf (arr, serializationFunc, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end;
  breakIterator(iterations, tree);

  if levelsDeep <= 0 then return nil end

  if not arr then return nil end

  local tab = {};

  for key in #arr do
    local value = arr[key]
    if isParent(tree, value) then
      tab[key] = nil;
    else
      tab[key] = serializationFunc(value, levelsDeep-1, getNewChildTree(tree, value), iterations+1);
    end
  end
  return tab;
end
_G['serializeArrayOf'] = serializeArrayOf;

-- Similar to array of but needed to use pairs for custom dictionaries
function serializeTable (arr, serializationFunc, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end;
  breakIterator(iterations, tree);

  if levelsDeep <= 0 then return nil end

  if not arr then return nil end

  local tab = {};
  for key,value in pairs(arr) do
      if (isParent(tree, value)) then
        tab[key] = nil;
      else
        tab[key] = serializationFunc(value, levelsDeep-1, getNewChildTree(tree, value), iterations+1);
      end
  end
  return tab;
end
_G['serializeTable'] = serializeTable;

function breakIterator (i, tree)
  if (i > 1000) then
    game.write_file("cycle-debug.log", serpent.dump(tree, { indent = " " }));
    error("Possible cycle issue, 1000 iterations reached... Debug log saved to cycle-debug.log");
  end
end
_G["breakIterator"] = breakIterator;

-- Check if this is a table of __self with userdata and
-- they match.
function compareSelf (objOne, objTwo)
  return objOne["__self"] == objTwo["__self"];
end
_G["compareSelf"] = compareSelf;

function isParent (tree, obj)
  if (tree == nil) then return false end
  if (obj == nil) then return false; end

  local t = type(obj);
  -- TODO find out lua base types and use it here:
  if (t == "string" or t == "boolean" or t == "float" or t == "number") then
    return false;
  end

  local parent = tree["__parent"];

  if (tree["__parent"] ~= nil) then
    local child = parent["__child"];
    if (child == obj) then
      return true
    end

    if (child ~= nil) then
      local status, res = pcall(compareSelf, child, obj)
      if not status then
        return isParent(parent, obj)
      end
      if res then return res end
    end

    return isParent(parent, obj);
  end
  return false;
end
_G["isParent"] = isParent;

function getNewChildTree (tree, obj)
  local childT = { __parent = tree, __child = obj};
  return childT;
end
_G["getNewChildTree"] = getNewChildTree;

function _getValue (object, key)
  return object[key];
end
_G["_getValue"] = _getValue;

-- The docs are not perfect, sometimes properties
-- do not actually exist. catching the error to avoid issues.
function getValue(object, key)
 status, result = pcall(_getValue, object, key)
 if not status then
   return nil;
 end
 return result;
end
_G["getValue"] = getValue;

function serializeLocalisedString (localisedString)
 if (localisedString == nil) then return nil; end;
 if (type(localisedString) == "table") then
  return tostring(localisedString[1]);
 else
  return tostring(localisedString);
 end
end
_G["serializeLocalisedString"] = serializeLocalisedString;

function mergeTable (t1, t2)
  if (t2 == nil) then return t1; end;
  if (t1 == nil) then return t2; end;
  for k,v in pairs(t2) do t1[k] = v end
  return t1;
end
_G["mergeTable"] = mergeTable;
`;

function notImplTemplate (className) {
  let functionName = getFunctionName(className);
return `
-- TODO: Implement function ${functionName}
function ${functionName} (notImpl)
  return nil;
end
_G['${functionName}'] = ${functionName};
`;
}
function extendsTemplate (functionName, variableName, table, extendsN) {
return `
function ${functionName} (${variableName}, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end;
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not ${variableName} then return nil end

  if isParent(tree, ${variableName}) then
    return nil;
  end
  local ${variableName}Table = {
${table}
  }

  return mergeTable(${extendsN}(${variableName}, levelsDeep, tree, iterations+1), ${variableName}Table);
end
_G['${functionName}'] = ${functionName};
`;
}


function template (functionName, variableName, table) {
  return `
function ${functionName} (${variableName}, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not ${variableName} then return nil end

  if isParent(tree, ${variableName}) then
    return nil
  end
  return {
${table}
  }
end
_G['${functionName}'] = ${functionName};
  `;
}

// Definitions not present in the docs...
let customDefinitions = [
  {
    name: "Position",
    table: {
      "x": getValue("position", "x"),
      "y": getValue("position", "y")
    }
  },
  {
    name: "ChunkPosition",
    table: {
      "x": getValue("chunkPosition", "x"),
      "y": getValue("chunkPosition", "y")
    }
  },
  {
    name: "Vector",
    table: {
      "[1]": getValue("vector", "1"),
      "[2]": getValue("vector", "2")
    }
  },
  {
    name: "BoundingBox",
    table: {
      "left_top": serializeType("boundingBox", "left_top", "Position"),
      "right_bottom": serializeType("boundingBox", "right_bottom", "Position")
    }
  },
  {
    name: "Color",
    table: {
      "r": getValue("color", "r"),
      "g": getValue("color", "g"),
      "b": getValue("color", "b"),
      "a": getValue("color", "a"),
    }
  }
];

// Types that I havent gotten arround to implement yet...
let notImplemented = [
  "GameViewSettings",
  "TileProperties",
  "MapSettings",
  "Ingredient",
  "Product",
  "Loot",
  "Modifier",
  "AutoplaceSpecification",
  "Resistances",
  "MapGenSize",
  "MapGenSettings",
  "SignalID",
  "Signal",
  "ArithmeticCombinatorParameters",
  "ConstantCombinatorParameters",
  "DeciderCombinatorParameters",
  "CircuitCondition",
  "CircuitConditionSpecification",
  "Filter",
  "SimpleItemStack",
  "Command",
  "SurfaceSpecification",
  "WaitCondition",
  "TrainScheduleRecord",
  "TrainSchedule",
  "GuiArrowSpecification",
  "AmmoType",
  "SpritePath",
  "ModConfigurationChangedData",
  "ConfigurationChangedData",
  "EffectValue",
  "EntityPrototypeFlags",
  "CollisionMask",
  "TriggerEffectItem",
  "TriggerDelivery",
  "TriggerItem",
  "AttackParameters",
  "CapsuleAction",
  "SelectionModeFlags",
];

function ucfirst (str) {
  return string.charAt(0).toUpperCase() + string.slice(1);
}

function deLua (name) {
  let nonLua = name.replace("Lua","");
  let camel = camelcase(nonLua);
  return {
    lower: camel,
    upper: nonLua
  }
}
function getVariableName (string) {
  return deLua(string).lower;
}
function getFunctionName (string) {
    return "serialize"+deLua(string).upper;
}

//
// glob("**/*.html", options, function (er, files) {
//
// })
//
// Load just the Control page.

function getValue(varName, attrName) {
  return "getValue("+varName+",'"+attrName+"')";
}

function serializeType (varName, attrName, type) {
  switch (type) {
    case "float":
    case "double":
    case "int":
    case "uint":
    case "uint64":
    case "string":
    case "boolean":
        return getValue(varName, attrName);
        break;
    default:
        return getFunctionName(type) + "("+getValue(varName, attrName)+", levelsDeep-1, getNewChildTree(tree, "+varName+"), iterations+1)";
  }
}

function isBuiltin (type) {

  switch (type) {
    case "float":
    case "double":
    case "int":
    case "uint":
    case "uint64":
    case "string":
    case "boolean":
      return true;
    case "":
      addComment("Warning: Null type specified, assuming is built in convertable table however this should be fixed.");
      return true;
    default:
      return false;
  }
}

var fullStr = outputTop;
function addComment (...args) {
  fullStr += "\n -- "+args.join(" ");
}

function addTemplate (code) {
  fullStr += code;
}

function serializeTable (bindings) {
  let table = "";
  let keys = Object.keys(bindings);
  let maxL = 0;
  for (let i = 0; i < keys.length; i++) {
    let key = keys[i];
    if (key.length > maxL) maxL = key.length;
  }

  for (let i = 0; i < keys.length; i++) {
    let key = keys[i];
    let padTo = (maxL+1) -key.length;
    if (i != 0)table+="\n";
    table += "    "+key+" ".repeat(padTo)+"= "+bindings[key];
    if (keys.length-1 !== i) table += ",";
  }
  return table;
}

const controlHtml = fs.readFileSync(docLoc+"Classes.html");
const $ = cheerio.load(controlHtml);
$(".type-name").each(function () {
  let className = $(this).text();
  let funcName = getFunctionName(className);
  let varName = getVariableName(className);


  let container = $(this).closest(".brief-listing");
  let attributes = container.find(".attribute-type");
  let extendText =container
    .clone()
    .children()
    .remove()
    .end()
    .text();
  let isExtension = extendText.indexOf("extends") != -1;
  let extending = container.find("a").eq(1).text().trim();
  if (isExtension) {
    addComment(className, "extends", extending);
  }

  var elements = {};
  attributes.each(function () {
    let attrN = $(this).parent().find(".element-name > a").text().trim();
    let a = $(this).find("a").text().trim();
    let isArray = $(this).text().indexOf("array of") != -1;
    let isDictionary = $(this).text().indexOf("dictionary") != -1;
    let customDictionary = $(this).text().indexOf("custom dictionary") != -1;
    let isOperator = attrN.indexOf("operator ") != -1;
    let hasOr = $(this).text().indexOf(" or ") != -1;
    let isDefinition = a.indexOf("defines.") != -1;

    //console.log(" -- Definition found:",attrN, $(this).text().trim());
    if (hasOr) {
      addComment("TODO: Manual help needed for",attrN,"as it has an or definition. ("+$(this).text().trim()+")");
      return;
    }
    if (isOperator) {
      return;
    }
    if (!isArray && !isDictionary && !isDefinition) {
      elements[attrN] = serializeType(varName, attrN, a);
    }
    else if (isArray && !isDefinition && !isDictionary) {
      if (!isBuiltin(a)) {
        elements[attrN] = "serializeArrayOf("+getValue(varName, attrN)+", "+getFunctionName(a)+", levelsDeep, getNewChildTree(tree, "+varName+"), iterations+1)";
      }
      else {
          elements[attrN] = getValue(varName, attrN);
      }
    }
    else if (isDictionary && !customDictionary) {
      let dictionaryInfo = $(this).text().split("→");
      let definitionOne = dictionaryInfo[0];
      let definitionTwo = dictionaryInfo[1];
      if (dictionaryInfo.length > 2) {
          addComment("TODO: Manual help needed for",attrN,"as it is a dictionary of dictionaries or something unknown ("+$(this).text().trim()+")");
        return;
      }
      let definitionOneType = definitionOne.replace(":: dictionary", "").trim();
      let definitionTwoType = definitionTwo.replace("array of", "").trim();
      let definitionTwoIsArray = definitionTwo.indexOf("array of") != -1;
      if (isBuiltin(definitionOneType)) {
        if (definitionTwoIsArray && !isBuiltin(definitionTwoType)) {
          elements[attrN] = "serializeTable("+getValue(varName, attrN)+", "+getFunctionName(definitionTwoType)+", levelsDeep, getNewChildTree(tree, "+varName+"), iterations+1)";
        }
        else {
          elements[attrN] = getValue(varName, attrN);
        }
      }
      else {
        addComment("TODO: Cannot serialize table with keys that are not built in. ("+$(this).text().trim()+")"); // Unsure if this will ever happen. but just in case.
      }

    }
    else {
        addComment("TODO: Manual help needed for",attrN,"as it is not yet implemented. ("+$(this).text().trim()+")");
    }
  });
  let temp = template;
  if (isExtension) {
    addTemplate(extendsTemplate(funcName, varName, serializeTable(elements), getFunctionName(extending)));
  }
  else {
    addTemplate(template(funcName, varName, serializeTable(elements)));
  }
});

customDefinitions.forEach(function (def) {
  addTemplate(template(getFunctionName(def.name), getVariableName(def.name), serializeTable(def.table)));
});

notImplemented.forEach(function (name) {
  addTemplate(notImplTemplate(name));
});

console.log(fullStr);
