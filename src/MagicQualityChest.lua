--[[
Handler for "magic-quality-chest".
]]
local GlobalState = require "src.GlobalState"
local constants = require "src.constants"

local lib = {}

local function entity_added(event)
  local entity = event.created_entity or event.entity or event.destination
  if entity == nil or not entity.valid then
    return
  end

  if entity.name == constants.CHEST_NAME then
    GlobalState.entity_register(entity)
  end
end

lib.events =
{
  [defines.events.on_built_entity] = entity_added,
  [defines.events.on_robot_built_entity] = entity_added,
  [defines.events.script_raised_revive] = entity_added,
  [defines.events.script_raised_built] = entity_added,
  [defines.events.on_entity_cloned] = entity_added,
  [defines.events.on_cancelled_deconstruction] = entity_added,
}

local function service_chest(info)
  local inv = info.entity.get_output_inventory()
  if not inv then
    return
  end
  --log(("service %s"):format(serpent.line(info)))

  local new_contents = {}
  local changed = false

  local function add_item(item_name, item_count)
    table.insert(new_contents, { name=item_name, count=item_count, quality=info.quality })
  end

  for idx=1, #inv do
    local stack = inv[idx]
    if stack.valid_for_read then

      -- decompose the grid contents
      if stack.grid then
        for _, equip in ipairs(stack.grid.get_contents()) do
          if equip.quality ~= info.quality then
            changed = true
          end
          add_item(equip.name, equip.count)
        end
      end

      -- add the item
      if stack.quality ~= nil and stack.quality.name ~= info.quality then
        changed = true
      end
      add_item(stack.name, stack.count)
    end
  end

  if changed then
    inv.clear()
    for _, item in ipairs(new_contents) do
      inv.insert(item)
    end
    --print(string.format("replaced [%s] %s", info.entity.unit_number, serpent.line(new_contents)))
  end
end

--[[
Upgrade the quality of items to legendary.
]]
local function service_chests()

  while true do
    local info = GlobalState.entity_next()
    if not info then
      -- end of the list for this tick
      return
    end
    if info.quality then
      service_chest(info)
    end
  end
end

lib.on_nth_tick = {
  [10] = service_chests,
}

return lib
