-- https://github.com/justarandomgeek/cmdbuffer
-- Modified to make it workable without mods and without
-- remote calls and to minify code as much as possible
_G["buf"]={
  a = function(buffname, buffpart)
    -- create/append buffer
    if global[buffname] == nil then
      global[buffname] = buffpart
    else
      global[buffname] = global[buffname] .. buffpart
    end
    return true
	end,
  e = function(buffname)
		-- execute and clear the selected buffer
    local f = loadstring(global[buffname])
    global[buffname] = nil
    return f()
	end
};
