function getPlayers ()
  local data = {};
  for i, v in ipairs(game.connected_players) do
    data[i] = serializePlayer(v);
  end
  return data;
end

function serializePlayer (player)
  if (player == nil) then return nil; end
  return {
    name = player.name,
    index = player.index,
    color = serializeColor(player.color),
    tag = player.tag,
    connected = player.connected,
    admin = player.admin,
    afk_time = player.afk_time,
    online_time = player.online_time,
    valid = player.valid
  };
end

function serializeControl (control)
  return {
    surface = serializeSurface(control.surface)
  };
end

function serializeSurface (surface)
  if (surface == nil) then return null; end
  return {
    name = surface.name,
    index = surface.index,
    map_gen_settings = serializeMapGenSettings(surface.map_gen_settings),
    always_day = surface.always_day,
    daytime = surface.daytime,
    darkness = surface.darkness,
    wind_speed = surface.wind_speed,
    wind_orientation = surface.wind_orientation,
    wind_orientation_change = surface.wind_orientation_change,
    peaceful_mode = surface.peaceful_mode,
    valid = surface.valid
  };
end

function serializePosition (position)
  if (position == nil) then return nil; end
  return {
    x = position.x,
    y = position.y
  };
end

function serializeColor (color)
  if (color == nil) then return nil; end
  return {
    r = color.r,
    g = color.g,
    b = color.b,
    a = color.a
  };
end

function mergeTable (t1, t2)
for k,v in pairs(t2) do t1[k] = v end
end
_G["getPlayers"] = getPlayers;
