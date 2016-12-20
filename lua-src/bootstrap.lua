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
  print("FACTORIO_JSON ".._G["JSON"]:encode(toEncode));
end

_G["respondTo"] = respondTo;
