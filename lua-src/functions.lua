function getPlayers ()
  local data = serializeTable(game.connected_players, serializePlayer);
  -- dumpLog();
  return data;
end
_G["getPlayers"] = getPlayers;

function getSurfaces ()
  return serializeTable(game.surfaces, serializeSurface)
end

local tile_cache = {}
local tile_cache_arr = {}
local tile_cache_inc = 1
function getTileID (name)
  if not tile_cache[name] then
    tile_cache[name] = tile_cache_inc;
    tile_cache_arr[tile_cache_inc] = name;
    tile_cache_inc = tile_cache_inc+1
    return tile_cache_inc-2
  end
  return tile_cache[name]-1
end
function getTiles (surfaceIndex, chunkX, chunkY)
  local chunkSize = 32
  local tiles = {}
  local n = 1
  for x = 1, chunkSize do
    for y = 1, chunkSize do
      local tile = game.surfaces[surfaceIndex].get_tile((chunkX * chunkSize) + x, (chunkY * chunkSize) + y)
      tiles[n] = getTileID(tile.name)
      n = n + 1
    end
  end
  return tiles
end

function getSurfaceTiles (surfaceIndex)
  local map = { ids={}, tiles = {} }
  local surface = game.surfaces[surfaceIndex]
  local tiles = map["tiles"]
  for chunk in surface.get_chunks() do
    if surface.is_chunk_generated(chunk) then
      if max == 0 then
        break
      end
      if not tiles[chunk.x] then
        tiles[chunk.x] = {}
      end
      tiles[chunk.x..","..chunk.y] = getTiles(surfaceIndex, chunk.x, chunk.y)
    end
  end
  map["ids"] = tile_cache_arr
  return map
end
