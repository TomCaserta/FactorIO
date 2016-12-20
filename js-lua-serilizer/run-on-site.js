import glob from "glob";
import fs from "fs";
import cheerio from "cheerio";
import camelcase from "camelcase";

let docLoc = process.argv[2] || "./doc-html/";

let outputTop = `
function serializeArrayOf (arr, serializationFunc)
  if (arr == nil) then return nil; end;
  local tab = {};
  for key,value in ipairs(arr) do
      tab[key] = seralizationFunc(value);
  end
  return tab;
end

-- Similar to array of but needed to use pairs for custom dictionaries
function serializeTable (arr, serializationFunc)
  if (arr == nil)  then return nil; end;
  local tab = {};
  for key,value in pairs(arr) do
      tab[key] = seralizationFunc(value);
  end
  return tab;
end


function mergeTable (t1, t2)
  if (t2 == nil) then return t1; end;
  if (t1 == nil) then return t2; end;
  for k,v in pairs(t2) do t1[k] = v end
end
`;
let templateExtends = `
function %function_name% (%variable_name%)
  if (%variable_name% == nil) then return nil; end;

  local %variable_name%Table = {
%table%
  }

  return mergeTable(%extends_function_name%(%variable_name%), %variable_name%Table);
end
_G['%function_name%'] = %function_name%;
`;
let template = `
function %function_name% (%variable_name%)
  if (%variable_name% == nil) then return nil; end;
  return {
%table%
  }
end
_G['%function_name%'] = %function_name%;
`;

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

function serializeType (varName, attrName, type) {
  switch (type) {
    case "float":
    case "double":
    case "int":
    case "uint":
    case "uint64":
    case "string":
    case "boolean":
        return varName + "." + attrName;
        break;
    default:
        return getFunctionName(type) + "("+varName + "." + attrName+")";
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
        elements[attrN] = "serializeArrayOf("+varName + "." + attrN+", "+getFunctionName(a)+")";
      }
      else {
          elements[attrN] = varName + "." + attrN;
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
          elements[attrN] = "serializeTable("+varName + "." + attrN+", "+getFunctionName(definitionTwoType)+")";
        }
        else {
          elements[attrN] = varName + "." + attrN;
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
    temp = templateExtends;
  }
  fullStr += temp.replace(/(%.+?%)/ig, function (match) {
      switch (match) {
        case "%table%":
        return serializeTable(elements);
        case "%function_name%":
        return funcName;
        case "%variable_name%":
        return varName;
        case "%extends_function_name%":
        return getFunctionName(extending);
        default:
        return "__UNKNOWN__";
        break;
      }
   });
});

console.log(fullStr);
