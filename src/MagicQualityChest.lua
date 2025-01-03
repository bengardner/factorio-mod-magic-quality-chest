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
    --log(("create %s"):format(serpent.line(event)))
    local info = GlobalState.entity_register(entity)
    if info and event.tags and event.tags.quality then
      info.quality = event.tags.quality
    else
      info.quality = nil
    end
  end
end

local function entity_settings_pasted(event)
  local src = event.source
  local dst = event.destination
  if src and src.valid and src.name == constants.CHEST_NAME and
     dst and dst.valid and dst.name == constants.CHEST_NAME
  then
    local src_info = GlobalState.entity_get_data(src.unit_number)
    local dst_info = GlobalState.entity_register(dst)
    if src_info and dst_info then
      --log(("paste %s => %s"):format(serpent.line(src_info), serpent.line(dst_info)))
      dst_info.quality = src_info.quality
    end
  end
end

-- generic blueprint code copied from somewhere
local function get_blueprint(event)
  local player = game.get_player(event.player_index)
  if not player then
    return
  end

  local bp = player.blueprint_to_setup
  if bp and bp.valid_for_read then
    return bp
  end

  bp = player.cursor_stack
  if not bp or not bp.valid_for_read then
    return nil
  end

  if bp.type == "blueprint-book" then
    local item_inventory = bp.get_inventory(defines.inventory.item_main)
    if item_inventory then
      bp = item_inventory[bp.active_index]
    else
      return
    end
  end

  return bp
end

local function on_player_setup_blueprint(event)
  -- add a tag to the blueprint entity from the entity settings
  local blueprint = get_blueprint(event)
  if blueprint == nil then
    return
  end

  local entities = blueprint.get_blueprint_entities()
  if entities == nil then
    return
  end

  for _, entity in ipairs(entities) do
    -- clog("blueprint: [%s] %s @ %s", entity.entity_number, entity.name, serpent.line(entity.position))
    local real_entity = event.surface.find_entity(entity.name, entity.position)
    if real_entity ~= nil then
      local info = GlobalState.entity_get_data(real_entity.unit_number)
      if info ~= nil then
        blueprint.set_blueprint_entity_tag(entity.entity_number, 'quality', info.quality)
      end
    end
  end
end

lib.events =
{
  [defines.events.on_built_entity] = entity_added,
  [defines.events.on_robot_built_entity] = entity_added,
  [defines.events.on_space_platform_built_entity] = entity_added,
  [defines.events.script_raised_revive] = entity_added,
  [defines.events.script_raised_built] = entity_added,
  [defines.events.on_cancelled_deconstruction] = entity_added,

  [defines.events.on_entity_settings_pasted] = entity_settings_pasted,
  [defines.events.on_entity_cloned] = entity_settings_pasted,

  [defines.events.on_player_setup_blueprint] = on_player_setup_blueprint
}

local function service_chest(info)
  -- only service if not 'disabled'
  if info.quality == nil then
    return
  end

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

      -- TODO: attempt to update the grid contents in-place?
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
Upgrade the quality of items.
]]
local function service_chests()
  while true do
    local info = GlobalState.entity_next()
    if not info then
      -- end of the list for this tick
      return
    end
    service_chest(info)
  end
end

lib.on_nth_tick = {
  [10] = service_chests,
}

return lib
