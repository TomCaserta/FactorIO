-- Provides some common functions
-- In order to allow the RPC connection
-- To send and receive a response from the game in a format it recognizes
function respondTo (result, id)
  -- Since its loaded in lua, the game will evaluate the code
  -- and result will be the actual value to print
  -- and send back.
  local toEncode = {
    result = result,
    id = id
  };
  local splitOn = 2000;
  local resp = _G["JSON"]:encode(toEncode):gsub("%\n", "\\n");
  local splitText = split(resp, splitOn)
  local count = math.ceil(resp:len() / splitOn)
  for i=1,#splitText do
    print("FACTORIO_JSON "..tostring(i).."/"..tostring(count).." "..splitText[i]);
  end
end
_G["respondTo"] = respondTo;

local function split(text, length)
    local strings = {}
    for i=1, #text, length do
        strings[#strings+1] = text:sub(i, i + length - 1)
    end
    return strings
end
_G["split"] = split;
