
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
    str = str .. "\n ["..tostring(k).."]" .. tostring(v);
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

function serializeBootstrap (bootstrap, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not bootstrap then return nil end

  if isParent(tree, bootstrap) then
    return nil
  end
  return {

  }
end
_G['serializeBootstrap'] = serializeBootstrap;
  
function serializeChunkIterator (chunkIterator, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not chunkIterator then return nil end

  if isParent(tree, chunkIterator) then
    return nil
  end
  return {
    valid = getValue(chunkIterator,'valid')
  }
end
_G['serializeChunkIterator'] = serializeChunkIterator;
  
 -- TODO: Manual help needed for wire_type as it is not yet implemented. (:: defines.wire_type)
 -- TODO: Manual help needed for circuit_connector_id as it is not yet implemented. (:: defines.circuit_connector_id)
function serializeCircuitNetwork (circuitNetwork, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not circuitNetwork then return nil end

  if isParent(tree, circuitNetwork) then
    return nil
  end
  return {
    entity  = serializeEntity(getValue(circuitNetwork,'entity'), levelsDeep-1, getNewChildTree(tree, circuitNetwork), iterations+1),
    signals = serializeArrayOf(getValue(circuitNetwork,'signals'), serializeSignal, levelsDeep, getNewChildTree(tree, circuitNetwork), iterations+1),
    valid   = getValue(circuitNetwork,'valid')
  }
end
_G['serializeCircuitNetwork'] = serializeCircuitNetwork;
  
 -- Warning: Null type specified, assuming is built in convertable table however this should be fixed.
function serializeControl (control, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not control then return nil end

  if isParent(tree, control) then
    return nil
  end
  return {
    surface                                       = serializeSurface(getValue(control,'surface'), levelsDeep-1, getNewChildTree(tree, control), iterations+1),
    position                                      = serializePosition(getValue(control,'position'), levelsDeep-1, getNewChildTree(tree, control), iterations+1),
    vehicle                                       = serializeEntity(getValue(control,'vehicle'), levelsDeep-1, getNewChildTree(tree, control), iterations+1),
    force                                         = serializeForce(getValue(control,'force'), levelsDeep-1, getNewChildTree(tree, control), iterations+1),
    selected                                      = serializeEntity(getValue(control,'selected'), levelsDeep-1, getNewChildTree(tree, control), iterations+1),
    opened                                        = serializeEntity(getValue(control,'opened'), levelsDeep-1, getNewChildTree(tree, control), iterations+1),
    crafting_queue_size                           = getValue(control,'crafting_queue_size'),
    cursor_stack                                  = serializeItemStack(getValue(control,'cursor_stack'), levelsDeep-1, getNewChildTree(tree, control), iterations+1),
    driving                                       = getValue(control,'driving'),
    crafting_queue                                = getValue(control,'crafting_queue'),
    cheat_mode                                    = getValue(control,'cheat_mode'),
    character_crafting_speed_modifier             = getValue(control,'character_crafting_speed_modifier'),
    character_mining_speed_modifier               = getValue(control,'character_mining_speed_modifier'),
    character_running_speed_modifier              = getValue(control,'character_running_speed_modifier'),
    character_build_distance_bonus                = getValue(control,'character_build_distance_bonus'),
    character_item_drop_distance_bonus            = getValue(control,'character_item_drop_distance_bonus'),
    character_reach_distance_bonus                = getValue(control,'character_reach_distance_bonus'),
    character_resource_reach_distance_bonus       = getValue(control,'character_resource_reach_distance_bonus'),
    character_item_pickup_distance_bonus          = getValue(control,'character_item_pickup_distance_bonus'),
    character_loot_pickup_distance_bonus          = getValue(control,'character_loot_pickup_distance_bonus'),
    quickbar_count_bonus                          = getValue(control,'quickbar_count_bonus'),
    character_inventory_slots_bonus               = getValue(control,'character_inventory_slots_bonus'),
    character_logistic_slot_count_bonus           = getValue(control,'character_logistic_slot_count_bonus'),
    character_trash_slot_count_bonus              = getValue(control,'character_trash_slot_count_bonus'),
    character_maximum_following_robot_count_bonus = getValue(control,'character_maximum_following_robot_count_bonus'),
    character_health_bonus                        = getValue(control,'character_health_bonus'),
    auto_trash_filters                            = getValue(control,'auto_trash_filters')
  }
end
_G['serializeControl'] = serializeControl;
  
 -- TODO: Manual help needed for type as it is not yet implemented. (:: defines.control_behavior.type)
function serializeControlBehavior (controlBehavior, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not controlBehavior then return nil end

  if isParent(tree, controlBehavior) then
    return nil
  end
  return {
    entity = serializeEntity(getValue(controlBehavior,'entity'), levelsDeep-1, getNewChildTree(tree, controlBehavior), iterations+1)
  }
end
_G['serializeControlBehavior'] = serializeControlBehavior;
  
 -- LuaAccumulatorControlBehavior extends LuaControlBehavior
function serializeAccumulatorControlBehavior (accumulatorControlBehavior, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end;
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not accumulatorControlBehavior then return nil end

  if isParent(tree, accumulatorControlBehavior) then
    return nil;
  end
  local accumulatorControlBehaviorTable = {
    valid = getValue(accumulatorControlBehavior,'valid')
  }

  return mergeTable(serializeControlBehavior(accumulatorControlBehavior, levelsDeep, tree, iterations+1), accumulatorControlBehaviorTable);
end
_G['serializeAccumulatorControlBehavior'] = serializeAccumulatorControlBehavior;

 -- LuaCombinatorControlBehavior extends LuaControlBehavior
function serializeCombinatorControlBehavior (combinatorControlBehavior, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end;
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not combinatorControlBehavior then return nil end

  if isParent(tree, combinatorControlBehavior) then
    return nil;
  end
  local combinatorControlBehaviorTable = {
    signals_last_tick = serializeArrayOf(getValue(combinatorControlBehavior,'signals_last_tick'), serializeSignal, levelsDeep, getNewChildTree(tree, combinatorControlBehavior), iterations+1)
  }

  return mergeTable(serializeControlBehavior(combinatorControlBehavior, levelsDeep, tree, iterations+1), combinatorControlBehaviorTable);
end
_G['serializeCombinatorControlBehavior'] = serializeCombinatorControlBehavior;

 -- LuaConstantCombinatorControlBehavior extends LuaControlBehavior
function serializeConstantCombinatorControlBehavior (constantCombinatorControlBehavior, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end;
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not constantCombinatorControlBehavior then return nil end

  if isParent(tree, constantCombinatorControlBehavior) then
    return nil;
  end
  local constantCombinatorControlBehaviorTable = {
    parameters = serializeConstantCombinatorParameters(getValue(constantCombinatorControlBehavior,'parameters'), levelsDeep-1, getNewChildTree(tree, constantCombinatorControlBehavior), iterations+1),
    enabled    = getValue(constantCombinatorControlBehavior,'enabled'),
    valid      = getValue(constantCombinatorControlBehavior,'valid')
  }

  return mergeTable(serializeControlBehavior(constantCombinatorControlBehavior, levelsDeep, tree, iterations+1), constantCombinatorControlBehaviorTable);
end
_G['serializeConstantCombinatorControlBehavior'] = serializeConstantCombinatorControlBehavior;

 -- LuaContainerControlBehavior extends LuaControlBehavior
function serializeContainerControlBehavior (containerControlBehavior, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end;
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not containerControlBehavior then return nil end

  if isParent(tree, containerControlBehavior) then
    return nil;
  end
  local containerControlBehaviorTable = {
    valid = getValue(containerControlBehavior,'valid')
  }

  return mergeTable(serializeControlBehavior(containerControlBehavior, levelsDeep, tree, iterations+1), containerControlBehaviorTable);
end
_G['serializeContainerControlBehavior'] = serializeContainerControlBehavior;

 -- LuaGenericOnOffControlBehavior extends LuaControlBehavior
function serializeGenericOnOffControlBehavior (genericOnOffControlBehavior, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end;
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not genericOnOffControlBehavior then return nil end

  if isParent(tree, genericOnOffControlBehavior) then
    return nil;
  end
  local genericOnOffControlBehaviorTable = {
    disabled                    = getValue(genericOnOffControlBehavior,'disabled'),
    circuit_condition           = serializeCircuitConditionSpecification(getValue(genericOnOffControlBehavior,'circuit_condition'), levelsDeep-1, getNewChildTree(tree, genericOnOffControlBehavior), iterations+1),
    logistic_condition          = serializeCircuitConditionSpecification(getValue(genericOnOffControlBehavior,'logistic_condition'), levelsDeep-1, getNewChildTree(tree, genericOnOffControlBehavior), iterations+1),
    connect_to_logistic_network = getValue(genericOnOffControlBehavior,'connect_to_logistic_network'),
    valid                       = getValue(genericOnOffControlBehavior,'valid')
  }

  return mergeTable(serializeControlBehavior(genericOnOffControlBehavior, levelsDeep, tree, iterations+1), genericOnOffControlBehaviorTable);
end
_G['serializeGenericOnOffControlBehavior'] = serializeGenericOnOffControlBehavior;

 -- LuaLogisticContainerControlBehavior extends LuaControlBehavior
 -- TODO: Manual help needed for circuit_mode_of_operation as it is not yet implemented. (:: defines.control_behavior.logistic_container.circuit_mode_of_operation)
function serializeLogisticContainerControlBehavior (logisticContainerControlBehavior, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end;
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not logisticContainerControlBehavior then return nil end

  if isParent(tree, logisticContainerControlBehavior) then
    return nil;
  end
  local logisticContainerControlBehaviorTable = {
    valid = getValue(logisticContainerControlBehavior,'valid')
  }

  return mergeTable(serializeControlBehavior(logisticContainerControlBehavior, levelsDeep, tree, iterations+1), logisticContainerControlBehaviorTable);
end
_G['serializeLogisticContainerControlBehavior'] = serializeLogisticContainerControlBehavior;

 -- LuaRailSignalControlBehavior extends LuaControlBehavior
function serializeRailSignalControlBehavior (railSignalControlBehavior, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end;
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not railSignalControlBehavior then return nil end

  if isParent(tree, railSignalControlBehavior) then
    return nil;
  end
  local railSignalControlBehaviorTable = {
    valid = getValue(railSignalControlBehavior,'valid')
  }

  return mergeTable(serializeControlBehavior(railSignalControlBehavior, levelsDeep, tree, iterations+1), railSignalControlBehaviorTable);
end
_G['serializeRailSignalControlBehavior'] = serializeRailSignalControlBehavior;

 -- LuaRoboportControlBehavior extends LuaControlBehavior
 -- TODO: Manual help needed for mode_of_operations as it is not yet implemented. (:: defines.control_behavior.roboport.circuit_mode_of_operation)
function serializeRoboportControlBehavior (roboportControlBehavior, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end;
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not roboportControlBehavior then return nil end

  if isParent(tree, roboportControlBehavior) then
    return nil;
  end
  local roboportControlBehaviorTable = {
    available_logistic_output_signal     = serializeSignalID(getValue(roboportControlBehavior,'available_logistic_output_signal'), levelsDeep-1, getNewChildTree(tree, roboportControlBehavior), iterations+1),
    total_logistic_output_signal         = serializeSignalID(getValue(roboportControlBehavior,'total_logistic_output_signal'), levelsDeep-1, getNewChildTree(tree, roboportControlBehavior), iterations+1),
    available_construction_output_signal = serializeSignalID(getValue(roboportControlBehavior,'available_construction_output_signal'), levelsDeep-1, getNewChildTree(tree, roboportControlBehavior), iterations+1),
    total_construction_output_signal     = serializeSignalID(getValue(roboportControlBehavior,'total_construction_output_signal'), levelsDeep-1, getNewChildTree(tree, roboportControlBehavior), iterations+1),
    valid                                = getValue(roboportControlBehavior,'valid')
  }

  return mergeTable(serializeControlBehavior(roboportControlBehavior, levelsDeep, tree, iterations+1), roboportControlBehaviorTable);
end
_G['serializeRoboportControlBehavior'] = serializeRoboportControlBehavior;

 -- LuaStorageTankControlBehavior extends LuaControlBehavior
function serializeStorageTankControlBehavior (storageTankControlBehavior, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end;
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not storageTankControlBehavior then return nil end

  if isParent(tree, storageTankControlBehavior) then
    return nil;
  end
  local storageTankControlBehaviorTable = {
    valid = getValue(storageTankControlBehavior,'valid')
  }

  return mergeTable(serializeControlBehavior(storageTankControlBehavior, levelsDeep, tree, iterations+1), storageTankControlBehaviorTable);
end
_G['serializeStorageTankControlBehavior'] = serializeStorageTankControlBehavior;

 -- LuaTrainStopControlBehavior extends LuaControlBehavior
function serializeTrainStopControlBehavior (trainStopControlBehavior, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end;
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not trainStopControlBehavior then return nil end

  if isParent(tree, trainStopControlBehavior) then
    return nil;
  end
  local trainStopControlBehaviorTable = {
    send_to_train = getValue(trainStopControlBehavior,'send_to_train'),
    valid         = getValue(trainStopControlBehavior,'valid')
  }

  return mergeTable(serializeControlBehavior(trainStopControlBehavior, levelsDeep, tree, iterations+1), trainStopControlBehaviorTable);
end
_G['serializeTrainStopControlBehavior'] = serializeTrainStopControlBehavior;

 -- LuaWallControlBehavior extends LuaControlBehavior
function serializeWallControlBehavior (wallControlBehavior, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end;
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not wallControlBehavior then return nil end

  if isParent(tree, wallControlBehavior) then
    return nil;
  end
  local wallControlBehaviorTable = {
    circuit_condition = serializeCircuitConditionSpecification(getValue(wallControlBehavior,'circuit_condition'), levelsDeep-1, getNewChildTree(tree, wallControlBehavior), iterations+1),
    valid             = getValue(wallControlBehavior,'valid')
  }

  return mergeTable(serializeControlBehavior(wallControlBehavior, levelsDeep, tree, iterations+1), wallControlBehaviorTable);
end
_G['serializeWallControlBehavior'] = serializeWallControlBehavior;

 -- LuaArithmeticCombinatorControlBehavior extends LuaCombinatorControlBehavior
function serializeArithmeticCombinatorControlBehavior (arithmeticCombinatorControlBehavior, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end;
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not arithmeticCombinatorControlBehavior then return nil end

  if isParent(tree, arithmeticCombinatorControlBehavior) then
    return nil;
  end
  local arithmeticCombinatorControlBehaviorTable = {
    parameters = serializeArithmeticCombinatorParameters(getValue(arithmeticCombinatorControlBehavior,'parameters'), levelsDeep-1, getNewChildTree(tree, arithmeticCombinatorControlBehavior), iterations+1),
    valid      = getValue(arithmeticCombinatorControlBehavior,'valid')
  }

  return mergeTable(serializeCombinatorControlBehavior(arithmeticCombinatorControlBehavior, levelsDeep, tree, iterations+1), arithmeticCombinatorControlBehaviorTable);
end
_G['serializeArithmeticCombinatorControlBehavior'] = serializeArithmeticCombinatorControlBehavior;

 -- LuaDeciderCombinatorControlBehavior extends LuaCombinatorControlBehavior
function serializeDeciderCombinatorControlBehavior (deciderCombinatorControlBehavior, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end;
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not deciderCombinatorControlBehavior then return nil end

  if isParent(tree, deciderCombinatorControlBehavior) then
    return nil;
  end
  local deciderCombinatorControlBehaviorTable = {
    parameters = serializeDeciderCombinatorParameters(getValue(deciderCombinatorControlBehavior,'parameters'), levelsDeep-1, getNewChildTree(tree, deciderCombinatorControlBehavior), iterations+1),
    valid      = getValue(deciderCombinatorControlBehavior,'valid')
  }

  return mergeTable(serializeCombinatorControlBehavior(deciderCombinatorControlBehavior, levelsDeep, tree, iterations+1), deciderCombinatorControlBehaviorTable);
end
_G['serializeDeciderCombinatorControlBehavior'] = serializeDeciderCombinatorControlBehavior;

 -- LuaInserterControlBehavior extends LuaGenericOnOffControlBehavior
 -- TODO: Manual help needed for circuit_mode_of_operation as it is not yet implemented. (:: defines.control_behavior.inserter.circuit_mode_of_operation)
 -- TODO: Manual help needed for circuit_hand_read_mode as it is not yet implemented. (:: defines.control_behavior.inserter.hand_read_mode)
function serializeInserterControlBehavior (inserterControlBehavior, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end;
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not inserterControlBehavior then return nil end

  if isParent(tree, inserterControlBehavior) then
    return nil;
  end
  local inserterControlBehaviorTable = {
    circuit_read_hand_contents = getValue(inserterControlBehavior,'circuit_read_hand_contents'),
    valid                      = getValue(inserterControlBehavior,'valid')
  }

  return mergeTable(serializeGenericOnOffControlBehavior(inserterControlBehavior, levelsDeep, tree, iterations+1), inserterControlBehaviorTable);
end
_G['serializeInserterControlBehavior'] = serializeInserterControlBehavior;

 -- LuaLampControlBehavior extends LuaGenericOnOffControlBehavior
function serializeLampControlBehavior (lampControlBehavior, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end;
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not lampControlBehavior then return nil end

  if isParent(tree, lampControlBehavior) then
    return nil;
  end
  local lampControlBehaviorTable = {
    use_colors = getValue(lampControlBehavior,'use_colors'),
    valid      = getValue(lampControlBehavior,'valid')
  }

  return mergeTable(serializeGenericOnOffControlBehavior(lampControlBehavior, levelsDeep, tree, iterations+1), lampControlBehaviorTable);
end
_G['serializeLampControlBehavior'] = serializeLampControlBehavior;

 -- LuaTransportBeltControlBehavior extends LuaGenericOnOffControlBehavior
function serializeTransportBeltControlBehavior (transportBeltControlBehavior, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end;
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not transportBeltControlBehavior then return nil end

  if isParent(tree, transportBeltControlBehavior) then
    return nil;
  end
  local transportBeltControlBehaviorTable = {
    valid = getValue(transportBeltControlBehavior,'valid')
  }

  return mergeTable(serializeGenericOnOffControlBehavior(transportBeltControlBehavior, levelsDeep, tree, iterations+1), transportBeltControlBehaviorTable);
end
_G['serializeTransportBeltControlBehavior'] = serializeTransportBeltControlBehavior;

function serializeCustomTable (customTable, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not customTable then return nil end

  if isParent(tree, customTable) then
    return nil
  end
  return {
    valid = getValue(customTable,'valid')
  }
end
_G['serializeCustomTable'] = serializeCustomTable;
  
function serializeDamagePrototype (damagePrototype, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not damagePrototype then return nil end

  if isParent(tree, damagePrototype) then
    return nil
  end
  return {
    name           = getValue(damagePrototype,'name'),
    order          = getValue(damagePrototype,'order'),
    localised_name = serializeLocalisedString(getValue(damagePrototype,'localised_name'), levelsDeep-1, getNewChildTree(tree, damagePrototype), iterations+1),
    valid          = getValue(damagePrototype,'valid')
  }
end
_G['serializeDamagePrototype'] = serializeDamagePrototype;
  
 -- LuaEntity extends LuaControl
 -- TODO: Manual help needed for direction as it is not yet implemented. (:: defines.direction)
 -- TODO: Manual help needed for ghost_prototype as it has an or definition. (:: LuaEntityPrototype or LuaTilePrototype)
 -- TODO: Manual help needed for neighbours as it has an or definition. (:: dictionary string → array of LuaEntity or array of LuaEntity or LuaEntity)
 -- TODO: Manual help needed for signal_state as it is not yet implemented. (:: defines.signal_state)
 -- Warning: Null type specified, assuming is built in convertable table however this should be fixed.
function serializeEntity (entity, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end;
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not entity then return nil end

  if isParent(tree, entity) then
    return nil;
  end
  local entityTable = {
    passenger                      = serializeEntity(getValue(entity,'passenger'), levelsDeep-1, getNewChildTree(tree, entity), iterations+1),
    name                           = getValue(entity,'name'),
    ghost_name                     = getValue(entity,'ghost_name'),
    localised_name                 = serializeLocalisedString(getValue(entity,'localised_name'), levelsDeep-1, getNewChildTree(tree, entity), iterations+1),
    ghost_localised_name           = serializeLocalisedString(getValue(entity,'ghost_localised_name'), levelsDeep-1, getNewChildTree(tree, entity), iterations+1),
    type                           = getValue(entity,'type'),
    ghost_type                     = getValue(entity,'ghost_type'),
    active                         = getValue(entity,'active'),
    destructible                   = getValue(entity,'destructible'),
    minable                        = getValue(entity,'minable'),
    rotatable                      = getValue(entity,'rotatable'),
    operable                       = getValue(entity,'operable'),
    health                         = getValue(entity,'health'),
    supports_direction             = getValue(entity,'supports_direction'),
    orientation                    = getValue(entity,'orientation'),
    amount                         = getValue(entity,'amount'),
    effectivity_modifier           = getValue(entity,'effectivity_modifier'),
    consumption_modifier           = getValue(entity,'consumption_modifier'),
    friction_modifier              = getValue(entity,'friction_modifier'),
    speed                          = getValue(entity,'speed'),
    stack                          = serializeItemStack(getValue(entity,'stack'), levelsDeep-1, getNewChildTree(tree, entity), iterations+1),
    prototype                      = serializeEntityPrototype(getValue(entity,'prototype'), levelsDeep-1, getNewChildTree(tree, entity), iterations+1),
    drop_position                  = serializePosition(getValue(entity,'drop_position'), levelsDeep-1, getNewChildTree(tree, entity), iterations+1),
    pickup_position                = serializePosition(getValue(entity,'pickup_position'), levelsDeep-1, getNewChildTree(tree, entity), iterations+1),
    drop_target                    = serializeEntity(getValue(entity,'drop_target'), levelsDeep-1, getNewChildTree(tree, entity), iterations+1),
    pickup_target                  = serializeEntity(getValue(entity,'pickup_target'), levelsDeep-1, getNewChildTree(tree, entity), iterations+1),
    selected_gun_index             = getValue(entity,'selected_gun_index'),
    energy                         = getValue(entity,'energy'),
    recipe                         = serializeRecipe(getValue(entity,'recipe'), levelsDeep-1, getNewChildTree(tree, entity), iterations+1),
    held_stack                     = serializeItemStack(getValue(entity,'held_stack'), levelsDeep-1, getNewChildTree(tree, entity), iterations+1),
    held_stack_position            = serializePosition(getValue(entity,'held_stack_position'), levelsDeep-1, getNewChildTree(tree, entity), iterations+1),
    train                          = serializeTrain(getValue(entity,'train'), levelsDeep-1, getNewChildTree(tree, entity), iterations+1),
    fluidbox                       = serializeFluidBox(getValue(entity,'fluidbox'), levelsDeep-1, getNewChildTree(tree, entity), iterations+1),
    backer_name                    = getValue(entity,'backer_name'),
    time_to_live                   = getValue(entity,'time_to_live'),
    color                          = serializeColor(getValue(entity,'color'), levelsDeep-1, getNewChildTree(tree, entity), iterations+1),
    chain_signal_state             = getValue(entity,'chain_signal_state'),
    to_be_looted                   = getValue(entity,'to_be_looted'),
    crafting_progress              = getValue(entity,'crafting_progress'),
    bonus_progress                 = getValue(entity,'bonus_progress'),
    belt_to_ground_type            = getValue(entity,'belt_to_ground_type'),
    loader_type                    = getValue(entity,'loader_type'),
    rocket_parts                   = getValue(entity,'rocket_parts'),
    logistic_network               = serializeLogisticNetwork(getValue(entity,'logistic_network'), levelsDeep-1, getNewChildTree(tree, entity), iterations+1),
    logistic_cell                  = serializeLogisticCell(getValue(entity,'logistic_cell'), levelsDeep-1, getNewChildTree(tree, entity), iterations+1),
    item_requests                  = getValue(entity,'item_requests'),
    player                         = serializePlayer(getValue(entity,'player'), levelsDeep-1, getNewChildTree(tree, entity), iterations+1),
    unit_group                     = serializeUnitGroup(getValue(entity,'unit_group'), levelsDeep-1, getNewChildTree(tree, entity), iterations+1),
    damage_dealt                   = getValue(entity,'damage_dealt'),
    kills                          = getValue(entity,'kills'),
    last_user                      = serializePlayer(getValue(entity,'last_user'), levelsDeep-1, getNewChildTree(tree, entity), iterations+1),
    electric_buffer_size           = getValue(entity,'electric_buffer_size'),
    electric_input_flow_limit      = getValue(entity,'electric_input_flow_limit'),
    electric_output_flow_limit     = getValue(entity,'electric_output_flow_limit'),
    electric_drain                 = getValue(entity,'electric_drain'),
    electric_emissions             = getValue(entity,'electric_emissions'),
    unit_number                    = getValue(entity,'unit_number'),
    mining_progress                = getValue(entity,'mining_progress'),
    bonus_mining_progress          = getValue(entity,'bonus_mining_progress'),
    power_production               = getValue(entity,'power_production'),
    power_usage                    = getValue(entity,'power_usage'),
    bounding_box                   = serializeBoundingBox(getValue(entity,'bounding_box'), levelsDeep-1, getNewChildTree(tree, entity), iterations+1),
    mining_target                  = serializeEntity(getValue(entity,'mining_target'), levelsDeep-1, getNewChildTree(tree, entity), iterations+1),
    circuit_connection_definitions = getValue(entity,'circuit_connection_definitions'),
    request_slot_count             = getValue(entity,'request_slot_count'),
    filter_slot_count              = getValue(entity,'filter_slot_count'),
    grid                           = serializeEquipmentGrid(getValue(entity,'grid'), levelsDeep-1, getNewChildTree(tree, entity), iterations+1),
    valid                          = getValue(entity,'valid')
  }

  return mergeTable(serializeControl(entity, levelsDeep, tree, iterations+1), entityTable);
end
_G['serializeEntity'] = serializeEntity;

 -- Warning: Null type specified, assuming is built in convertable table however this should be fixed.
function serializeEntityPrototype (entityPrototype, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not entityPrototype then return nil end

  if isParent(tree, entityPrototype) then
    return nil
  end
  return {
    type                      = getValue(entityPrototype,'type'),
    name                      = getValue(entityPrototype,'name'),
    localised_name            = serializeLocalisedString(getValue(entityPrototype,'localised_name'), levelsDeep-1, getNewChildTree(tree, entityPrototype), iterations+1),
    max_health                = getValue(entityPrototype,'max_health'),
    infinite_resource         = getValue(entityPrototype,'infinite_resource'),
    minimum_resource_amount   = getValue(entityPrototype,'minimum_resource_amount'),
    resource_category         = getValue(entityPrototype,'resource_category'),
    items_to_place_this       = getValue(entityPrototype,'items_to_place_this'),
    collision_box             = serializeBoundingBox(getValue(entityPrototype,'collision_box'), levelsDeep-1, getNewChildTree(tree, entityPrototype), iterations+1),
    selection_box             = serializeBoundingBox(getValue(entityPrototype,'selection_box'), levelsDeep-1, getNewChildTree(tree, entityPrototype), iterations+1),
    order                     = getValue(entityPrototype,'order'),
    group                     = serializeGroup(getValue(entityPrototype,'group'), levelsDeep-1, getNewChildTree(tree, entityPrototype), iterations+1),
    subgroup                  = serializeGroup(getValue(entityPrototype,'subgroup'), levelsDeep-1, getNewChildTree(tree, entityPrototype), iterations+1),
    healing_per_tick          = getValue(entityPrototype,'healing_per_tick'),
    emissions_per_tick        = getValue(entityPrototype,'emissions_per_tick'),
    corpses                   = getValue(entityPrototype,'corpses'),
    selectable_in_game        = getValue(entityPrototype,'selectable_in_game'),
    weight                    = getValue(entityPrototype,'weight'),
    resistances               = serializeResistances(getValue(entityPrototype,'resistances'), levelsDeep-1, getNewChildTree(tree, entityPrototype), iterations+1),
    fast_replaceable_group    = getValue(entityPrototype,'fast_replaceable_group'),
    loot                      = serializeLoot(getValue(entityPrototype,'loot'), levelsDeep-1, getNewChildTree(tree, entityPrototype), iterations+1),
    repair_speed_modifier     = getValue(entityPrototype,'repair_speed_modifier'),
    turret_range              = getValue(entityPrototype,'turret_range'),
    autoplace_specification   = serializeAutoplaceSpecification(getValue(entityPrototype,'autoplace_specification'), levelsDeep-1, getNewChildTree(tree, entityPrototype), iterations+1),
    collision_mask            = getValue(entityPrototype,'collision_mask'),
    belt_speed                = getValue(entityPrototype,'belt_speed'),
    underground_belt_distance = getValue(entityPrototype,'underground_belt_distance'),
    result_units              = getValue(entityPrototype,'result_units'),
    mining_drill_radius       = getValue(entityPrototype,'mining_drill_radius'),
    logistic_mode             = getValue(entityPrototype,'logistic_mode'),
    valid                     = getValue(entityPrototype,'valid')
  }
end
_G['serializeEntityPrototype'] = serializeEntityPrototype;
  
function serializeEquipment (equipment, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not equipment then return nil end

  if isParent(tree, equipment) then
    return nil
  end
  return {
    name            = getValue(equipment,'name'),
    type            = getValue(equipment,'type'),
    position        = serializePosition(getValue(equipment,'position'), levelsDeep-1, getNewChildTree(tree, equipment), iterations+1),
    shield          = getValue(equipment,'shield'),
    max_shield      = getValue(equipment,'max_shield'),
    max_solar_power = getValue(equipment,'max_solar_power'),
    movement_bonus  = getValue(equipment,'movement_bonus'),
    generator_power = getValue(equipment,'generator_power'),
    energy          = getValue(equipment,'energy'),
    max_energy      = getValue(equipment,'max_energy'),
    prototype       = serializeEquipmentPrototype(getValue(equipment,'prototype'), levelsDeep-1, getNewChildTree(tree, equipment), iterations+1),
    valid           = getValue(equipment,'valid')
  }
end
_G['serializeEquipment'] = serializeEquipment;
  
function serializeEquipmentGrid (equipmentGrid, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not equipmentGrid then return nil end

  if isParent(tree, equipmentGrid) then
    return nil
  end
  return {
    prototype              = serializeEquipmentGridPrototype(getValue(equipmentGrid,'prototype'), levelsDeep-1, getNewChildTree(tree, equipmentGrid), iterations+1),
    width                  = getValue(equipmentGrid,'width'),
    height                 = getValue(equipmentGrid,'height'),
    equipment              = serializeArrayOf(getValue(equipmentGrid,'equipment'), serializeEquipment, levelsDeep, getNewChildTree(tree, equipmentGrid), iterations+1),
    generator_energy       = getValue(equipmentGrid,'generator_energy'),
    max_solar_energy       = getValue(equipmentGrid,'max_solar_energy'),
    available_in_batteries = getValue(equipmentGrid,'available_in_batteries'),
    battery_capacity       = getValue(equipmentGrid,'battery_capacity'),
    valid                  = getValue(equipmentGrid,'valid')
  }
end
_G['serializeEquipmentGrid'] = serializeEquipmentGrid;
  
function serializeEquipmentGridPrototype (equipmentGridPrototype, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not equipmentGridPrototype then return nil end

  if isParent(tree, equipmentGridPrototype) then
    return nil
  end
  return {
    name                 = getValue(equipmentGridPrototype,'name'),
    order                = getValue(equipmentGridPrototype,'order'),
    localised_name       = serializeLocalisedString(getValue(equipmentGridPrototype,'localised_name'), levelsDeep-1, getNewChildTree(tree, equipmentGridPrototype), iterations+1),
    equipment_categories = getValue(equipmentGridPrototype,'equipment_categories'),
    width                = getValue(equipmentGridPrototype,'width'),
    height               = getValue(equipmentGridPrototype,'height'),
    valid                = getValue(equipmentGridPrototype,'valid')
  }
end
_G['serializeEquipmentGridPrototype'] = serializeEquipmentGridPrototype;
  
function serializeEquipmentPrototype (equipmentPrototype, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not equipmentPrototype then return nil end

  if isParent(tree, equipmentPrototype) then
    return nil
  end
  return {
    name                 = getValue(equipmentPrototype,'name'),
    type                 = getValue(equipmentPrototype,'type'),
    order                = getValue(equipmentPrototype,'order'),
    localised_name       = serializeLocalisedString(getValue(equipmentPrototype,'localised_name'), levelsDeep-1, getNewChildTree(tree, equipmentPrototype), iterations+1),
    take_result          = serializeItemPrototype(getValue(equipmentPrototype,'take_result'), levelsDeep-1, getNewChildTree(tree, equipmentPrototype), iterations+1),
    energy_production    = getValue(equipmentPrototype,'energy_production'),
    shield               = getValue(equipmentPrototype,'shield'),
    energy_per_shield    = getValue(equipmentPrototype,'energy_per_shield'),
    energy_consumption   = getValue(equipmentPrototype,'energy_consumption'),
    movement_bonus       = getValue(equipmentPrototype,'movement_bonus'),
    night_vision_tint    = serializeColor(getValue(equipmentPrototype,'night_vision_tint'), levelsDeep-1, getNewChildTree(tree, equipmentPrototype), iterations+1),
    equipment_categories = getValue(equipmentPrototype,'equipment_categories'),
    valid                = getValue(equipmentPrototype,'valid')
  }
end
_G['serializeEquipmentPrototype'] = serializeEquipmentPrototype;
  
 -- TODO: Manual help needed for input_counts as it has an or definition. (:: dictionary string → array of uint64 or double)
 -- TODO: Manual help needed for output_counts as it has an or definition. (:: dictionary string → array of uint64 or double)
function serializeFlowStatistics (flowStatistics, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not flowStatistics then return nil end

  if isParent(tree, flowStatistics) then
    return nil
  end
  return {
    force = serializeForce(getValue(flowStatistics,'force'), levelsDeep-1, getNewChildTree(tree, flowStatistics), iterations+1),
    valid = getValue(flowStatistics,'valid')
  }
end
_G['serializeFlowStatistics'] = serializeFlowStatistics;
  
function serializeFluidBox (fluidBox, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not fluidBox then return nil end

  if isParent(tree, fluidBox) then
    return nil
  end
  return {
    valid = getValue(fluidBox,'valid')
  }
end
_G['serializeFluidBox'] = serializeFluidBox;
  
function serializeFluidPrototype (fluidPrototype, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not fluidPrototype then return nil end

  if isParent(tree, fluidPrototype) then
    return nil
  end
  return {
    name                    = getValue(fluidPrototype,'name'),
    localised_name          = serializeLocalisedString(getValue(fluidPrototype,'localised_name'), levelsDeep-1, getNewChildTree(tree, fluidPrototype), iterations+1),
    default_temperature     = getValue(fluidPrototype,'default_temperature'),
    max_temperature         = getValue(fluidPrototype,'max_temperature'),
    heat_capacity           = getValue(fluidPrototype,'heat_capacity'),
    pressure_to_speed_ratio = getValue(fluidPrototype,'pressure_to_speed_ratio'),
    flow_to_energy_ratio    = getValue(fluidPrototype,'flow_to_energy_ratio'),
    max_push_amount         = getValue(fluidPrototype,'max_push_amount'),
    ratio_to_push           = getValue(fluidPrototype,'ratio_to_push'),
    order                   = getValue(fluidPrototype,'order'),
    group                   = serializeGroup(getValue(fluidPrototype,'group'), levelsDeep-1, getNewChildTree(tree, fluidPrototype), iterations+1),
    subgroup                = serializeGroup(getValue(fluidPrototype,'subgroup'), levelsDeep-1, getNewChildTree(tree, fluidPrototype), iterations+1),
    base_color              = serializeColor(getValue(fluidPrototype,'base_color'), levelsDeep-1, getNewChildTree(tree, fluidPrototype), iterations+1),
    flow_color              = serializeColor(getValue(fluidPrototype,'flow_color'), levelsDeep-1, getNewChildTree(tree, fluidPrototype), iterations+1),
    valid                   = getValue(fluidPrototype,'valid')
  }
end
_G['serializeFluidPrototype'] = serializeFluidPrototype;
  
 -- TODO: Manual help needed for technologies as it is not yet implemented. (:: custom dictionary string → LuaTechnology)
 -- TODO: Manual help needed for recipes as it is not yet implemented. (:: custom dictionary string → LuaRecipe)
 -- TODO: Manual help needed for current_research as it has an or definition. (:: LuaTechnology or string)
function serializeForce (force, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not force then return nil end

  if isParent(tree, force) then
    return nil
  end
  return {
    name                                    = getValue(force,'name'),
    manual_mining_speed_modifier            = getValue(force,'manual_mining_speed_modifier'),
    manual_crafting_speed_modifier          = getValue(force,'manual_crafting_speed_modifier'),
    laboratory_speed_modifier               = getValue(force,'laboratory_speed_modifier'),
    worker_robots_speed_modifier            = getValue(force,'worker_robots_speed_modifier'),
    worker_robots_storage_bonus             = getValue(force,'worker_robots_storage_bonus'),
    research_progress                       = getValue(force,'research_progress'),
    inserter_stack_size_bonus               = getValue(force,'inserter_stack_size_bonus'),
    stack_inserter_capacity_bonus           = getValue(force,'stack_inserter_capacity_bonus'),
    character_logistic_slot_count           = getValue(force,'character_logistic_slot_count'),
    character_trash_slot_count              = getValue(force,'character_trash_slot_count'),
    quickbar_count                          = getValue(force,'quickbar_count'),
    maximum_following_robot_count           = getValue(force,'maximum_following_robot_count'),
    ghost_time_to_live                      = getValue(force,'ghost_time_to_live'),
    players                                 = serializeArrayOf(getValue(force,'players'), serializePlayer, levelsDeep, getNewChildTree(tree, force), iterations+1),
    ai_controllable                         = getValue(force,'ai_controllable'),
    logistic_networks                       = serializeTable(getValue(force,'logistic_networks'), serializeLogisticNetwork, levelsDeep, getNewChildTree(tree, force), iterations+1),
    item_production_statistics              = serializeFlowStatistics(getValue(force,'item_production_statistics'), levelsDeep-1, getNewChildTree(tree, force), iterations+1),
    fluid_production_statistics             = serializeFlowStatistics(getValue(force,'fluid_production_statistics'), levelsDeep-1, getNewChildTree(tree, force), iterations+1),
    kill_count_statistics                   = serializeFlowStatistics(getValue(force,'kill_count_statistics'), levelsDeep-1, getNewChildTree(tree, force), iterations+1),
    item_resource_statistics                = serializeFlowStatistics(getValue(force,'item_resource_statistics'), levelsDeep-1, getNewChildTree(tree, force), iterations+1),
    fluid_resource_statistics               = serializeFlowStatistics(getValue(force,'fluid_resource_statistics'), levelsDeep-1, getNewChildTree(tree, force), iterations+1),
    entity_build_count_statistics           = serializeFlowStatistics(getValue(force,'entity_build_count_statistics'), levelsDeep-1, getNewChildTree(tree, force), iterations+1),
    character_running_speed_modifier        = getValue(force,'character_running_speed_modifier'),
    character_build_distance_bonus          = getValue(force,'character_build_distance_bonus'),
    character_item_drop_distance_bonus      = getValue(force,'character_item_drop_distance_bonus'),
    character_reach_distance_bonus          = getValue(force,'character_reach_distance_bonus'),
    character_resource_reach_distance_bonus = getValue(force,'character_resource_reach_distance_bonus'),
    character_item_pickup_distance_bonus    = getValue(force,'character_item_pickup_distance_bonus'),
    character_loot_pickup_distance_bonus    = getValue(force,'character_loot_pickup_distance_bonus'),
    character_inventory_slots_bonus         = getValue(force,'character_inventory_slots_bonus'),
    deconstruction_time_to_live             = getValue(force,'deconstruction_time_to_live'),
    character_health_bonus                  = getValue(force,'character_health_bonus'),
    auto_character_trash_slots              = getValue(force,'auto_character_trash_slots'),
    connected_players                       = serializeArrayOf(getValue(force,'connected_players'), serializePlayer, levelsDeep, getNewChildTree(tree, force), iterations+1),
    valid                                   = getValue(force,'valid')
  }
end
_G['serializeForce'] = serializeForce;
  
 -- TODO: Manual help needed for players as it has an or definition. (:: custom dictionary uint or string → LuaPlayer)
 -- TODO: Manual help needed for difficulty as it is not yet implemented. (:: defines.difficulty)
 -- TODO: Manual help needed for forces as it is not yet implemented. (:: custom dictionary string → LuaForce)
 -- TODO: Manual help needed for entity_prototypes as it is not yet implemented. (:: custom dictionary string → LuaEntityPrototype)
 -- TODO: Manual help needed for item_prototypes as it is not yet implemented. (:: custom dictionary string → LuaItemPrototype)
 -- TODO: Manual help needed for fluid_prototypes as it is not yet implemented. (:: custom dictionary string → LuaFluidPrototype)
 -- TODO: Manual help needed for tile_prototypes as it is not yet implemented. (:: custom dictionary string → LuaTilePrototype)
 -- TODO: Manual help needed for equipment_prototypes as it is not yet implemented. (:: custom dictionary string → LuaEquipmentPrototype)
 -- TODO: Manual help needed for damage_prototypes as it is not yet implemented. (:: custom dictionary string → LuaDamagePrototype)
 -- TODO: Manual help needed for virtual_signal_prototypes as it is not yet implemented. (:: custom dictionary string → LuaVirtualSignalPrototype)
 -- TODO: Manual help needed for equipment_grid_prototypes as it is not yet implemented. (:: custom dictionary string → LuaEquipmentGridPrototype)
 -- TODO: Manual help needed for surfaces as it is not yet implemented. (:: custom dictionary string → LuaSurface)
function serializeGameScript (gameScript, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not gameScript then return nil end

  if isParent(tree, gameScript) then
    return nil
  end
  return {
    player            = serializePlayer(getValue(gameScript,'player'), levelsDeep-1, getNewChildTree(tree, gameScript), iterations+1),
    evolution_factor  = getValue(gameScript,'evolution_factor'),
    map_settings      = serializeMapSettings(getValue(gameScript,'map_settings'), levelsDeep-1, getNewChildTree(tree, gameScript), iterations+1),
    tick              = getValue(gameScript,'tick'),
    finished          = getValue(gameScript,'finished'),
    speed             = getValue(gameScript,'speed'),
    active_mods       = getValue(gameScript,'active_mods'),
    connected_players = serializeArrayOf(getValue(gameScript,'connected_players'), serializePlayer, levelsDeep, getNewChildTree(tree, gameScript), iterations+1)
  }
end
_G['serializeGameScript'] = serializeGameScript;
  
function serializeGroup (group, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not group then return nil end

  if isParent(tree, group) then
    return nil
  end
  return {
    name      = getValue(group,'name'),
    type      = getValue(group,'type'),
    group     = serializeGroup(getValue(group,'group'), levelsDeep-1, getNewChildTree(tree, group), iterations+1),
    subgroups = serializeArrayOf(getValue(group,'subgroups'), serializeGroup, levelsDeep, getNewChildTree(tree, group), iterations+1),
    order     = getValue(group,'order'),
    valid     = getValue(group,'valid')
  }
end
_G['serializeGroup'] = serializeGroup;
  
function serializeGui (gui, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not gui then return nil end

  if isParent(tree, gui) then
    return nil
  end
  return {
    player = serializePlayer(getValue(gui,'player'), levelsDeep-1, getNewChildTree(tree, gui), iterations+1),
    top    = serializeGuiElement(getValue(gui,'top'), levelsDeep-1, getNewChildTree(tree, gui), iterations+1),
    left   = serializeGuiElement(getValue(gui,'left'), levelsDeep-1, getNewChildTree(tree, gui), iterations+1),
    center = serializeGuiElement(getValue(gui,'center'), levelsDeep-1, getNewChildTree(tree, gui), iterations+1),
    valid  = getValue(gui,'valid')
  }
end
_G['serializeGui'] = serializeGui;
  
 -- TODO: Manual help needed for style as it has an or definition. (:: LuaStyle or string)
function serializeGuiElement (guiElement, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not guiElement then return nil end

  if isParent(tree, guiElement) then
    return nil
  end
  return {
    gui                      = serializeGui(getValue(guiElement,'gui'), levelsDeep-1, getNewChildTree(tree, guiElement), iterations+1),
    parent                   = serializeGuiElement(getValue(guiElement,'parent'), levelsDeep-1, getNewChildTree(tree, guiElement), iterations+1),
    name                     = getValue(guiElement,'name'),
    caption                  = serializeLocalisedString(getValue(guiElement,'caption'), levelsDeep-1, getNewChildTree(tree, guiElement), iterations+1),
    value                    = getValue(guiElement,'value'),
    direction                = getValue(guiElement,'direction'),
    text                     = getValue(guiElement,'text'),
    children_names           = getValue(guiElement,'children_names'),
    state                    = getValue(guiElement,'state'),
    player_index             = getValue(guiElement,'player_index'),
    sprite                   = serializeSpritePath(getValue(guiElement,'sprite'), levelsDeep-1, getNewChildTree(tree, guiElement), iterations+1),
    tooltip                  = serializeLocalisedString(getValue(guiElement,'tooltip'), levelsDeep-1, getNewChildTree(tree, guiElement), iterations+1),
    vertical_scroll_policy   = getValue(guiElement,'vertical_scroll_policy'),
    horizontal_scroll_policy = getValue(guiElement,'horizontal_scroll_policy'),
    type                     = getValue(guiElement,'type'),
    valid                    = getValue(guiElement,'valid')
  }
end
_G['serializeGuiElement'] = serializeGuiElement;
  
function serializeInventory (inventory, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not inventory then return nil end

  if isParent(tree, inventory) then
    return nil
  end
  return {
    index = getValue(inventory,'index'),
    valid = getValue(inventory,'valid')
  }
end
_G['serializeInventory'] = serializeInventory;
  
function serializeItemPrototype (itemPrototype, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not itemPrototype then return nil end

  if isParent(tree, itemPrototype) then
    return nil
  end
  return {
    type                          = getValue(itemPrototype,'type'),
    name                          = getValue(itemPrototype,'name'),
    localised_name                = serializeLocalisedString(getValue(itemPrototype,'localised_name'), levelsDeep-1, getNewChildTree(tree, itemPrototype), iterations+1),
    localised_description         = serializeLocalisedString(getValue(itemPrototype,'localised_description'), levelsDeep-1, getNewChildTree(tree, itemPrototype), iterations+1),
    order                         = getValue(itemPrototype,'order'),
    place_result                  = serializeEntityPrototype(getValue(itemPrototype,'place_result'), levelsDeep-1, getNewChildTree(tree, itemPrototype), iterations+1),
    place_as_equipment_result     = serializeEquipmentPrototype(getValue(itemPrototype,'place_as_equipment_result'), levelsDeep-1, getNewChildTree(tree, itemPrototype), iterations+1),
    stackable                     = getValue(itemPrototype,'stackable'),
    default_request_amount        = getValue(itemPrototype,'default_request_amount'),
    stack_size                    = getValue(itemPrototype,'stack_size'),
    fuel_value                    = getValue(itemPrototype,'fuel_value'),
    subgroup                      = serializeGroup(getValue(itemPrototype,'subgroup'), levelsDeep-1, getNewChildTree(tree, itemPrototype), iterations+1),
    group                         = serializeGroup(getValue(itemPrototype,'group'), levelsDeep-1, getNewChildTree(tree, itemPrototype), iterations+1),
    flags                         = getValue(itemPrototype,'flags'),
    ammo_type                     = serializeAmmoType(getValue(itemPrototype,'ammo_type'), levelsDeep-1, getNewChildTree(tree, itemPrototype), iterations+1),
    magazine_size                 = getValue(itemPrototype,'magazine_size'),
    equipment_grid                = serializeEquipmentGridPrototype(getValue(itemPrototype,'equipment_grid'), levelsDeep-1, getNewChildTree(tree, itemPrototype), iterations+1),
    resistances                   = serializeResistances(getValue(itemPrototype,'resistances'), levelsDeep-1, getNewChildTree(tree, itemPrototype), iterations+1),
    inventory_size_bonus          = getValue(itemPrototype,'inventory_size_bonus'),
    capsule_action                = serializeCapsuleAction(getValue(itemPrototype,'capsule_action'), levelsDeep-1, getNewChildTree(tree, itemPrototype), iterations+1),
    attack_parameters             = serializeAttackParameters(getValue(itemPrototype,'attack_parameters'), levelsDeep-1, getNewChildTree(tree, itemPrototype), iterations+1),
    inventory_size                = getValue(itemPrototype,'inventory_size'),
    item_filters                  = getValue(itemPrototype,'item_filters'),
    group_filters                 = getValue(itemPrototype,'group_filters'),
    sub_group_filters             = getValue(itemPrototype,'sub_group_filters'),
    filter_mode                   = getValue(itemPrototype,'filter_mode'),
    insertion_priority_mode       = getValue(itemPrototype,'insertion_priority_mode'),
    localised_filter_message      = serializeLocalisedString(getValue(itemPrototype,'localised_filter_message'), levelsDeep-1, getNewChildTree(tree, itemPrototype), iterations+1),
    extend_inventory_by_default   = getValue(itemPrototype,'extend_inventory_by_default'),
    default_label_color           = serializeColor(getValue(itemPrototype,'default_label_color'), levelsDeep-1, getNewChildTree(tree, itemPrototype), iterations+1),
    draw_label_for_cursor_render  = getValue(itemPrototype,'draw_label_for_cursor_render'),
    speed                         = getValue(itemPrototype,'speed'),
    attack_result                 = serializeArrayOf(getValue(itemPrototype,'attack_result'), serializeTriggerItem, levelsDeep, getNewChildTree(tree, itemPrototype), iterations+1),
    attack_range                  = getValue(itemPrototype,'attack_range'),
    module_effects                = getValue(itemPrototype,'module_effects'),
    category                      = getValue(itemPrototype,'category'),
    tier                          = getValue(itemPrototype,'tier'),
    limitations                   = getValue(itemPrototype,'limitations'),
    limitation_message_key        = getValue(itemPrototype,'limitation_message_key'),
    straight_rail                 = serializeEntityPrototype(getValue(itemPrototype,'straight_rail'), levelsDeep-1, getNewChildTree(tree, itemPrototype), iterations+1),
    curved_rail                   = serializeEntityPrototype(getValue(itemPrototype,'curved_rail'), levelsDeep-1, getNewChildTree(tree, itemPrototype), iterations+1),
    repair_result                 = serializeArrayOf(getValue(itemPrototype,'repair_result'), serializeTriggerItem, levelsDeep, getNewChildTree(tree, itemPrototype), iterations+1),
    selection_border_color        = serializeColor(getValue(itemPrototype,'selection_border_color'), levelsDeep-1, getNewChildTree(tree, itemPrototype), iterations+1),
    alt_selection_border_color    = serializeColor(getValue(itemPrototype,'alt_selection_border_color'), levelsDeep-1, getNewChildTree(tree, itemPrototype), iterations+1),
    selection_mode_flags          = serializeSelectionModeFlags(getValue(itemPrototype,'selection_mode_flags'), levelsDeep-1, getNewChildTree(tree, itemPrototype), iterations+1),
    alt_selection_mode_flags      = serializeSelectionModeFlags(getValue(itemPrototype,'alt_selection_mode_flags'), levelsDeep-1, getNewChildTree(tree, itemPrototype), iterations+1),
    selection_cursor_box_type     = getValue(itemPrototype,'selection_cursor_box_type'),
    alt_selection_cursor_box_type = getValue(itemPrototype,'alt_selection_cursor_box_type'),
    always_include_tiles          = getValue(itemPrototype,'always_include_tiles'),
    durability_description_key    = getValue(itemPrototype,'durability_description_key'),
    durability                    = getValue(itemPrototype,'durability'),
    valid                         = getValue(itemPrototype,'valid')
  }
end
_G['serializeItemPrototype'] = serializeItemPrototype;
  
 -- Warning: Null type specified, assuming is built in convertable table however this should be fixed.
 -- Warning: Null type specified, assuming is built in convertable table however this should be fixed.
function serializeItemStack (itemStack, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not itemStack then return nil end

  if isParent(tree, itemStack) then
    return nil
  end
  return {
    valid_for_read            = getValue(itemStack,'valid_for_read'),
    prototype                 = serializeItemPrototype(getValue(itemStack,'prototype'), levelsDeep-1, getNewChildTree(tree, itemStack), iterations+1),
    name                      = getValue(itemStack,'name'),
    type                      = getValue(itemStack,'type'),
    count                     = getValue(itemStack,'count'),
    grid                      = serializeEquipmentGrid(getValue(itemStack,'grid'), levelsDeep-1, getNewChildTree(tree, itemStack), iterations+1),
    health                    = getValue(itemStack,'health'),
    durability                = getValue(itemStack,'durability'),
    ammo                      = getValue(itemStack,'ammo'),
    blueprint_icons           = getValue(itemStack,'blueprint_icons'),
    label                     = getValue(itemStack,'label'),
    label_color               = serializeColor(getValue(itemStack,'label_color'), levelsDeep-1, getNewChildTree(tree, itemStack), iterations+1),
    allow_manual_label_change = getValue(itemStack,'allow_manual_label_change'),
    cost_to_build             = getValue(itemStack,'cost_to_build'),
    extends_inventory         = getValue(itemStack,'extends_inventory'),
    prioritize_insertion_mode = getValue(itemStack,'prioritize_insertion_mode'),
    default_icons             = getValue(itemStack,'default_icons'),
    valid                     = getValue(itemStack,'valid')
  }
end
_G['serializeItemStack'] = serializeItemStack;
  
function serializeLogisticCell (logisticCell, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not logisticCell then return nil end

  if isParent(tree, logisticCell) then
    return nil
  end
  return {
    logistic_radius                    = getValue(logisticCell,'logistic_radius'),
    construction_radius                = getValue(logisticCell,'construction_radius'),
    stationed_logistic_robot_count     = getValue(logisticCell,'stationed_logistic_robot_count'),
    stationed_construction_robot_count = getValue(logisticCell,'stationed_construction_robot_count'),
    mobile                             = getValue(logisticCell,'mobile'),
    transmitting                       = getValue(logisticCell,'transmitting'),
    charge_approach_distance           = getValue(logisticCell,'charge_approach_distance'),
    charging_robot_count               = getValue(logisticCell,'charging_robot_count'),
    to_charge_robot_count              = getValue(logisticCell,'to_charge_robot_count'),
    owner                              = serializeEntity(getValue(logisticCell,'owner'), levelsDeep-1, getNewChildTree(tree, logisticCell), iterations+1),
    logistic_network                   = serializeLogisticNetwork(getValue(logisticCell,'logistic_network'), levelsDeep-1, getNewChildTree(tree, logisticCell), iterations+1),
    neighbours                         = serializeArrayOf(getValue(logisticCell,'neighbours'), serializeLogisticCell, levelsDeep, getNewChildTree(tree, logisticCell), iterations+1),
    charging_robots                    = serializeArrayOf(getValue(logisticCell,'charging_robots'), serializeEntity, levelsDeep, getNewChildTree(tree, logisticCell), iterations+1),
    to_charge_robots                   = serializeArrayOf(getValue(logisticCell,'to_charge_robots'), serializeEntity, levelsDeep, getNewChildTree(tree, logisticCell), iterations+1),
    valid                              = getValue(logisticCell,'valid')
  }
end
_G['serializeLogisticCell'] = serializeLogisticCell;
  
function serializeLogisticNetwork (logisticNetwork, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not logisticNetwork then return nil end

  if isParent(tree, logisticNetwork) then
    return nil
  end
  return {
    available_logistic_robots     = getValue(logisticNetwork,'available_logistic_robots'),
    all_logistic_robots           = getValue(logisticNetwork,'all_logistic_robots'),
    available_construction_robots = getValue(logisticNetwork,'available_construction_robots'),
    all_construction_robots       = getValue(logisticNetwork,'all_construction_robots'),
    robot_limit                   = getValue(logisticNetwork,'robot_limit'),
    cells                         = serializeArrayOf(getValue(logisticNetwork,'cells'), serializeLogisticCell, levelsDeep, getNewChildTree(tree, logisticNetwork), iterations+1),
    providers                     = serializeArrayOf(getValue(logisticNetwork,'providers'), serializeEntity, levelsDeep, getNewChildTree(tree, logisticNetwork), iterations+1),
    empty_providers               = serializeArrayOf(getValue(logisticNetwork,'empty_providers'), serializeEntity, levelsDeep, getNewChildTree(tree, logisticNetwork), iterations+1),
    requesters                    = serializeArrayOf(getValue(logisticNetwork,'requesters'), serializeEntity, levelsDeep, getNewChildTree(tree, logisticNetwork), iterations+1),
    full_or_satisfied_requesters  = serializeArrayOf(getValue(logisticNetwork,'full_or_satisfied_requesters'), serializeEntity, levelsDeep, getNewChildTree(tree, logisticNetwork), iterations+1),
    storages                      = serializeArrayOf(getValue(logisticNetwork,'storages'), serializeEntity, levelsDeep, getNewChildTree(tree, logisticNetwork), iterations+1),
    logistic_members              = serializeArrayOf(getValue(logisticNetwork,'logistic_members'), serializeEntity, levelsDeep, getNewChildTree(tree, logisticNetwork), iterations+1),
    valid                         = getValue(logisticNetwork,'valid')
  }
end
_G['serializeLogisticNetwork'] = serializeLogisticNetwork;
  
 -- LuaPlayer extends LuaControl
 -- TODO: Manual help needed for controller_type as it is not yet implemented. (:: defines.controllers)
function serializePlayer (player, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end;
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not player then return nil end

  if isParent(tree, player) then
    return nil;
  end
  local playerTable = {
    character          = serializeEntity(getValue(player,'character'), levelsDeep-1, getNewChildTree(tree, player), iterations+1),
    index              = getValue(player,'index'),
    gui                = serializeGui(getValue(player,'gui'), levelsDeep-1, getNewChildTree(tree, player), iterations+1),
    opened_self        = getValue(player,'opened_self'),
    game_view_settings = serializeGameViewSettings(getValue(player,'game_view_settings'), levelsDeep-1, getNewChildTree(tree, player), iterations+1),
    minimap_enabled    = getValue(player,'minimap_enabled'),
    color              = serializeColor(getValue(player,'color'), levelsDeep-1, getNewChildTree(tree, player), iterations+1),
    name               = getValue(player,'name'),
    tag                = getValue(player,'tag'),
    connected          = getValue(player,'connected'),
    admin              = getValue(player,'admin'),
    entity_copy_source = serializeEntity(getValue(player,'entity_copy_source'), levelsDeep-1, getNewChildTree(tree, player), iterations+1),
    afk_time           = getValue(player,'afk_time'),
    online_time        = getValue(player,'online_time'),
    cursor_position    = serializePosition(getValue(player,'cursor_position'), levelsDeep-1, getNewChildTree(tree, player), iterations+1),
    zoom               = getValue(player,'zoom'),
    valid              = getValue(player,'valid')
  }

  return mergeTable(serializeControl(player, levelsDeep, tree, iterations+1), playerTable);
end
_G['serializePlayer'] = serializePlayer;

function serializeRecipe (recipe, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not recipe then return nil end

  if isParent(tree, recipe) then
    return nil
  end
  return {
    enabled        = getValue(recipe,'enabled'),
    name           = getValue(recipe,'name'),
    localised_name = serializeLocalisedString(getValue(recipe,'localised_name'), levelsDeep-1, getNewChildTree(tree, recipe), iterations+1),
    category       = getValue(recipe,'category'),
    ingredients    = serializeArrayOf(getValue(recipe,'ingredients'), serializeIngredient, levelsDeep, getNewChildTree(tree, recipe), iterations+1),
    products       = serializeArrayOf(getValue(recipe,'products'), serializeProduct, levelsDeep, getNewChildTree(tree, recipe), iterations+1),
    hidden         = getValue(recipe,'hidden'),
    energy         = getValue(recipe,'energy'),
    order          = getValue(recipe,'order'),
    group          = serializeGroup(getValue(recipe,'group'), levelsDeep-1, getNewChildTree(tree, recipe), iterations+1),
    subgroup       = serializeGroup(getValue(recipe,'subgroup'), levelsDeep-1, getNewChildTree(tree, recipe), iterations+1),
    force          = serializeForce(getValue(recipe,'force'), levelsDeep-1, getNewChildTree(tree, recipe), iterations+1),
    valid          = getValue(recipe,'valid')
  }
end
_G['serializeRecipe'] = serializeRecipe;
  
 -- TODO: Manual help needed for interfaces as it is a dictionary of dictionaries or something unknown (:: dictionary string → dictionary string → boolean)
function serializeRemote (remote, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not remote then return nil end

  if isParent(tree, remote) then
    return nil
  end
  return {

  }
end
_G['serializeRemote'] = serializeRemote;
  
function serializeStyle (style, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not style then return nil end

  if isParent(tree, style) then
    return nil
  end
  return {
    gui                 = serializeGui(getValue(style,'gui'), levelsDeep-1, getNewChildTree(tree, style), iterations+1),
    name                = getValue(style,'name'),
    minimal_width       = getValue(style,'minimal_width'),
    maximal_width       = getValue(style,'maximal_width'),
    minimal_height      = getValue(style,'minimal_height'),
    maximal_height      = getValue(style,'maximal_height'),
    top_padding         = getValue(style,'top_padding'),
    right_padding       = getValue(style,'right_padding'),
    bottom_padding      = getValue(style,'bottom_padding'),
    left_padding        = getValue(style,'left_padding'),
    font_color          = serializeColor(getValue(style,'font_color'), levelsDeep-1, getNewChildTree(tree, style), iterations+1),
    font                = getValue(style,'font'),
    resize_row_to_width = getValue(style,'resize_row_to_width'),
    cell_spacing        = getValue(style,'cell_spacing'),
    horizontal_spacing  = getValue(style,'horizontal_spacing'),
    vertical_spacing    = getValue(style,'vertical_spacing'),
    visible             = getValue(style,'visible'),
    valid               = getValue(style,'valid')
  }
end
_G['serializeStyle'] = serializeStyle;
  
function serializeSurface (surface, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not surface then return nil end

  if isParent(tree, surface) then
    return nil
  end
  return {
    name                    = getValue(surface,'name'),
    index                   = getValue(surface,'index'),
    map_gen_settings        = serializeMapGenSettings(getValue(surface,'map_gen_settings'), levelsDeep-1, getNewChildTree(tree, surface), iterations+1),
    always_day              = getValue(surface,'always_day'),
    daytime                 = getValue(surface,'daytime'),
    darkness                = getValue(surface,'darkness'),
    wind_speed              = getValue(surface,'wind_speed'),
    wind_orientation        = getValue(surface,'wind_orientation'),
    wind_orientation_change = getValue(surface,'wind_orientation_change'),
    peaceful_mode           = getValue(surface,'peaceful_mode'),
    valid                   = getValue(surface,'valid')
  }
end
_G['serializeSurface'] = serializeSurface;
  
function serializeTechnology (technology, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not technology then return nil end

  if isParent(tree, technology) then
    return nil
  end
  return {
    force                     = serializeForce(getValue(technology,'force'), levelsDeep-1, getNewChildTree(tree, technology), iterations+1),
    name                      = getValue(technology,'name'),
    localised_name            = serializeLocalisedString(getValue(technology,'localised_name'), levelsDeep-1, getNewChildTree(tree, technology), iterations+1),
    enabled                   = getValue(technology,'enabled'),
    upgrade                   = getValue(technology,'upgrade'),
    researched                = getValue(technology,'researched'),
    prerequisites             = getValue(technology,'prerequisites'),
    research_unit_ingredients = serializeArrayOf(getValue(technology,'research_unit_ingredients'), serializeIngredient, levelsDeep, getNewChildTree(tree, technology), iterations+1),
    effects                   = serializeArrayOf(getValue(technology,'effects'), serializeModifier, levelsDeep, getNewChildTree(tree, technology), iterations+1),
    research_unit_count       = getValue(technology,'research_unit_count'),
    research_unit_energy      = getValue(technology,'research_unit_energy'),
    order                     = getValue(technology,'order'),
    valid                     = getValue(technology,'valid')
  }
end
_G['serializeTechnology'] = serializeTechnology;
  
function serializeTile (tile, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not tile then return nil end

  if isParent(tree, tile) then
    return nil
  end
  return {
    name        = getValue(tile,'name'),
    prototype   = serializeTilePrototype(getValue(tile,'prototype'), levelsDeep-1, getNewChildTree(tree, tile), iterations+1),
    position    = serializePosition(getValue(tile,'position'), levelsDeep-1, getNewChildTree(tree, tile), iterations+1),
    hidden_tile = getValue(tile,'hidden_tile'),
    valid       = getValue(tile,'valid')
  }
end
_G['serializeTile'] = serializeTile;
  
function serializeTilePrototype (tilePrototype, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not tilePrototype then return nil end

  if isParent(tree, tilePrototype) then
    return nil
  end
  return {
    name                           = getValue(tilePrototype,'name'),
    order                          = getValue(tilePrototype,'order'),
    localised_name                 = serializeLocalisedString(getValue(tilePrototype,'localised_name'), levelsDeep-1, getNewChildTree(tree, tilePrototype), iterations+1),
    collision_mask                 = getValue(tilePrototype,'collision_mask'),
    layer                          = getValue(tilePrototype,'layer'),
    walking_speed_modifier         = getValue(tilePrototype,'walking_speed_modifier'),
    vehicle_friction_modifier      = getValue(tilePrototype,'vehicle_friction_modifier'),
    map_color                      = serializeColor(getValue(tilePrototype,'map_color'), levelsDeep-1, getNewChildTree(tree, tilePrototype), iterations+1),
    decorative_removal_probability = getValue(tilePrototype,'decorative_removal_probability'),
    allowed_neighbors              = getValue(tilePrototype,'allowed_neighbors'),
    items_to_place_this            = getValue(tilePrototype,'items_to_place_this'),
    can_be_part_of_blueprint       = getValue(tilePrototype,'can_be_part_of_blueprint'),
    emissions_per_tick             = getValue(tilePrototype,'emissions_per_tick'),
    autoplace_specification        = serializeAutoplaceSpecification(getValue(tilePrototype,'autoplace_specification'), levelsDeep-1, getNewChildTree(tree, tilePrototype), iterations+1),
    valid                          = getValue(tilePrototype,'valid')
  }
end
_G['serializeTilePrototype'] = serializeTilePrototype;
  
 -- TODO: Manual help needed for state as it is not yet implemented. (:: defines.train_state)
 -- TODO: Manual help needed for rail_direction_from_front_rail as it is not yet implemented. (:: defines.rail_direction)
 -- TODO: Manual help needed for rail_direction_from_back_rail as it is not yet implemented. (:: defines.rail_direction)
function serializeTrain (train, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not train then return nil end

  if isParent(tree, train) then
    return nil
  end
  return {
    manual_mode  = getValue(train,'manual_mode'),
    speed        = getValue(train,'speed'),
    carriages    = serializeArrayOf(getValue(train,'carriages'), serializeEntity, levelsDeep, getNewChildTree(tree, train), iterations+1),
    locomotives  = serializeTable(getValue(train,'locomotives'), serializeEntity, levelsDeep, getNewChildTree(tree, train), iterations+1),
    cargo_wagons = serializeArrayOf(getValue(train,'cargo_wagons'), serializeEntity, levelsDeep, getNewChildTree(tree, train), iterations+1),
    schedule     = serializeTrainSchedule(getValue(train,'schedule'), levelsDeep-1, getNewChildTree(tree, train), iterations+1),
    front_rail   = serializeEntity(getValue(train,'front_rail'), levelsDeep-1, getNewChildTree(tree, train), iterations+1),
    back_rail    = serializeEntity(getValue(train,'back_rail'), levelsDeep-1, getNewChildTree(tree, train), iterations+1),
    front_stock  = serializeEntity(getValue(train,'front_stock'), levelsDeep-1, getNewChildTree(tree, train), iterations+1),
    back_stock   = serializeEntity(getValue(train,'back_stock'), levelsDeep-1, getNewChildTree(tree, train), iterations+1),
    station      = serializeEntity(getValue(train,'station'), levelsDeep-1, getNewChildTree(tree, train), iterations+1),
    valid        = getValue(train,'valid')
  }
end
_G['serializeTrain'] = serializeTrain;
  
function serializeTransportLine (transportLine, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not transportLine then return nil end

  if isParent(tree, transportLine) then
    return nil
  end
  return {
    owner = serializeEntity(getValue(transportLine,'owner'), levelsDeep-1, getNewChildTree(tree, transportLine), iterations+1),
    valid = getValue(transportLine,'valid')
  }
end
_G['serializeTransportLine'] = serializeTransportLine;
  
 -- TODO: Manual help needed for state as it is not yet implemented. (:: defines.group_state)
function serializeUnitGroup (unitGroup, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not unitGroup then return nil end

  if isParent(tree, unitGroup) then
    return nil
  end
  return {
    members  = serializeArrayOf(getValue(unitGroup,'members'), serializeEntity, levelsDeep, getNewChildTree(tree, unitGroup), iterations+1),
    position = serializePosition(getValue(unitGroup,'position'), levelsDeep-1, getNewChildTree(tree, unitGroup), iterations+1),
    force    = serializeForce(getValue(unitGroup,'force'), levelsDeep-1, getNewChildTree(tree, unitGroup), iterations+1),
    surface  = serializeSurface(getValue(unitGroup,'surface'), levelsDeep-1, getNewChildTree(tree, unitGroup), iterations+1),
    valid    = getValue(unitGroup,'valid')
  }
end
_G['serializeUnitGroup'] = serializeUnitGroup;
  
function serializeVirtualSignalPrototype (virtualSignalPrototype, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not virtualSignalPrototype then return nil end

  if isParent(tree, virtualSignalPrototype) then
    return nil
  end
  return {
    name           = getValue(virtualSignalPrototype,'name'),
    order          = getValue(virtualSignalPrototype,'order'),
    localised_name = serializeLocalisedString(getValue(virtualSignalPrototype,'localised_name'), levelsDeep-1, getNewChildTree(tree, virtualSignalPrototype), iterations+1),
    special        = getValue(virtualSignalPrototype,'special'),
    subgroup       = serializeGroup(getValue(virtualSignalPrototype,'subgroup'), levelsDeep-1, getNewChildTree(tree, virtualSignalPrototype), iterations+1),
    valid          = getValue(virtualSignalPrototype,'valid')
  }
end
_G['serializeVirtualSignalPrototype'] = serializeVirtualSignalPrototype;
  
function serializePosition (position, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not position then return nil end

  if isParent(tree, position) then
    return nil
  end
  return {
    x = getValue(position,'x'),
    y = getValue(position,'y')
  }
end
_G['serializePosition'] = serializePosition;
  
function serializeChunkPosition (chunkPosition, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not chunkPosition then return nil end

  if isParent(tree, chunkPosition) then
    return nil
  end
  return {
    x = getValue(chunkPosition,'x'),
    y = getValue(chunkPosition,'y')
  }
end
_G['serializeChunkPosition'] = serializeChunkPosition;
  
function serializeVector (vector, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not vector then return nil end

  if isParent(tree, vector) then
    return nil
  end
  return {
    [1] = getValue(vector,'1'),
    [2] = getValue(vector,'2')
  }
end
_G['serializeVector'] = serializeVector;
  
function serializeBoundingBox (boundingBox, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not boundingBox then return nil end

  if isParent(tree, boundingBox) then
    return nil
  end
  return {
    left_top     = serializePosition(getValue(boundingBox,'left_top'), levelsDeep-1, getNewChildTree(tree, boundingBox), iterations+1),
    right_bottom = serializePosition(getValue(boundingBox,'right_bottom'), levelsDeep-1, getNewChildTree(tree, boundingBox), iterations+1)
  }
end
_G['serializeBoundingBox'] = serializeBoundingBox;
  
function serializeColor (color, levelsDeep, tree, iterations)
  if not iterations then iterations=1 end
  breakIterator(iterations, tree)

  if levelsDeep <= 0 then return nil end

  if not color then return nil end

  if isParent(tree, color) then
    return nil
  end
  return {
    r = getValue(color,'r'),
    g = getValue(color,'g'),
    b = getValue(color,'b'),
    a = getValue(color,'a')
  }
end
_G['serializeColor'] = serializeColor;
  
-- TODO: Implement function serializeGameViewSettings
function serializeGameViewSettings (notImpl)
  return nil;
end
_G['serializeGameViewSettings'] = serializeGameViewSettings;

-- TODO: Implement function serializeTileProperties
function serializeTileProperties (notImpl)
  return nil;
end
_G['serializeTileProperties'] = serializeTileProperties;

-- TODO: Implement function serializeMapSettings
function serializeMapSettings (notImpl)
  return nil;
end
_G['serializeMapSettings'] = serializeMapSettings;

-- TODO: Implement function serializeIngredient
function serializeIngredient (notImpl)
  return nil;
end
_G['serializeIngredient'] = serializeIngredient;

-- TODO: Implement function serializeProduct
function serializeProduct (notImpl)
  return nil;
end
_G['serializeProduct'] = serializeProduct;

-- TODO: Implement function serializeLoot
function serializeLoot (notImpl)
  return nil;
end
_G['serializeLoot'] = serializeLoot;

-- TODO: Implement function serializeModifier
function serializeModifier (notImpl)
  return nil;
end
_G['serializeModifier'] = serializeModifier;

-- TODO: Implement function serializeAutoplaceSpecification
function serializeAutoplaceSpecification (notImpl)
  return nil;
end
_G['serializeAutoplaceSpecification'] = serializeAutoplaceSpecification;

-- TODO: Implement function serializeResistances
function serializeResistances (notImpl)
  return nil;
end
_G['serializeResistances'] = serializeResistances;

-- TODO: Implement function serializeMapGenSize
function serializeMapGenSize (notImpl)
  return nil;
end
_G['serializeMapGenSize'] = serializeMapGenSize;

-- TODO: Implement function serializeMapGenSettings
function serializeMapGenSettings (notImpl)
  return nil;
end
_G['serializeMapGenSettings'] = serializeMapGenSettings;

-- TODO: Implement function serializeSignalID
function serializeSignalID (notImpl)
  return nil;
end
_G['serializeSignalID'] = serializeSignalID;

-- TODO: Implement function serializeSignal
function serializeSignal (notImpl)
  return nil;
end
_G['serializeSignal'] = serializeSignal;

-- TODO: Implement function serializeArithmeticCombinatorParameters
function serializeArithmeticCombinatorParameters (notImpl)
  return nil;
end
_G['serializeArithmeticCombinatorParameters'] = serializeArithmeticCombinatorParameters;

-- TODO: Implement function serializeConstantCombinatorParameters
function serializeConstantCombinatorParameters (notImpl)
  return nil;
end
_G['serializeConstantCombinatorParameters'] = serializeConstantCombinatorParameters;

-- TODO: Implement function serializeDeciderCombinatorParameters
function serializeDeciderCombinatorParameters (notImpl)
  return nil;
end
_G['serializeDeciderCombinatorParameters'] = serializeDeciderCombinatorParameters;

-- TODO: Implement function serializeCircuitCondition
function serializeCircuitCondition (notImpl)
  return nil;
end
_G['serializeCircuitCondition'] = serializeCircuitCondition;

-- TODO: Implement function serializeCircuitConditionSpecification
function serializeCircuitConditionSpecification (notImpl)
  return nil;
end
_G['serializeCircuitConditionSpecification'] = serializeCircuitConditionSpecification;

-- TODO: Implement function serializeFilter
function serializeFilter (notImpl)
  return nil;
end
_G['serializeFilter'] = serializeFilter;

-- TODO: Implement function serializeSimpleItemStack
function serializeSimpleItemStack (notImpl)
  return nil;
end
_G['serializeSimpleItemStack'] = serializeSimpleItemStack;

-- TODO: Implement function serializeCommand
function serializeCommand (notImpl)
  return nil;
end
_G['serializeCommand'] = serializeCommand;

-- TODO: Implement function serializeSurfaceSpecification
function serializeSurfaceSpecification (notImpl)
  return nil;
end
_G['serializeSurfaceSpecification'] = serializeSurfaceSpecification;

-- TODO: Implement function serializeWaitCondition
function serializeWaitCondition (notImpl)
  return nil;
end
_G['serializeWaitCondition'] = serializeWaitCondition;

-- TODO: Implement function serializeTrainScheduleRecord
function serializeTrainScheduleRecord (notImpl)
  return nil;
end
_G['serializeTrainScheduleRecord'] = serializeTrainScheduleRecord;

-- TODO: Implement function serializeTrainSchedule
function serializeTrainSchedule (notImpl)
  return nil;
end
_G['serializeTrainSchedule'] = serializeTrainSchedule;

-- TODO: Implement function serializeGuiArrowSpecification
function serializeGuiArrowSpecification (notImpl)
  return nil;
end
_G['serializeGuiArrowSpecification'] = serializeGuiArrowSpecification;

-- TODO: Implement function serializeAmmoType
function serializeAmmoType (notImpl)
  return nil;
end
_G['serializeAmmoType'] = serializeAmmoType;

-- TODO: Implement function serializeSpritePath
function serializeSpritePath (notImpl)
  return nil;
end
_G['serializeSpritePath'] = serializeSpritePath;

-- TODO: Implement function serializeModConfigurationChangedData
function serializeModConfigurationChangedData (notImpl)
  return nil;
end
_G['serializeModConfigurationChangedData'] = serializeModConfigurationChangedData;

-- TODO: Implement function serializeConfigurationChangedData
function serializeConfigurationChangedData (notImpl)
  return nil;
end
_G['serializeConfigurationChangedData'] = serializeConfigurationChangedData;

-- TODO: Implement function serializeEffectValue
function serializeEffectValue (notImpl)
  return nil;
end
_G['serializeEffectValue'] = serializeEffectValue;

-- TODO: Implement function serializeEntityPrototypeFlags
function serializeEntityPrototypeFlags (notImpl)
  return nil;
end
_G['serializeEntityPrototypeFlags'] = serializeEntityPrototypeFlags;

-- TODO: Implement function serializeCollisionMask
function serializeCollisionMask (notImpl)
  return nil;
end
_G['serializeCollisionMask'] = serializeCollisionMask;

-- TODO: Implement function serializeTriggerEffectItem
function serializeTriggerEffectItem (notImpl)
  return nil;
end
_G['serializeTriggerEffectItem'] = serializeTriggerEffectItem;

-- TODO: Implement function serializeTriggerDelivery
function serializeTriggerDelivery (notImpl)
  return nil;
end
_G['serializeTriggerDelivery'] = serializeTriggerDelivery;

-- TODO: Implement function serializeTriggerItem
function serializeTriggerItem (notImpl)
  return nil;
end
_G['serializeTriggerItem'] = serializeTriggerItem;

-- TODO: Implement function serializeAttackParameters
function serializeAttackParameters (notImpl)
  return nil;
end
_G['serializeAttackParameters'] = serializeAttackParameters;

-- TODO: Implement function serializeCapsuleAction
function serializeCapsuleAction (notImpl)
  return nil;
end
_G['serializeCapsuleAction'] = serializeCapsuleAction;

-- TODO: Implement function serializeSelectionModeFlags
function serializeSelectionModeFlags (notImpl)
  return nil;
end
_G['serializeSelectionModeFlags'] = serializeSelectionModeFlags;

