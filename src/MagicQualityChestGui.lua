--[[
GUI for "magic-quality-chest".
Appends a quality selector to the right side of the container entity GUI.
]]
local GlobalState = require "src.GlobalState"
local constants = require "src.constants"
local GUI_CONTAINER_NAME = "magic-quality-chest-gui"
local GUI_SELBOX_NAME = GUI_CONTAINER_NAME .. "-selbox"

local lib = {}

-- destory the GUI
local function close_gui(player)
  local window = player.gui.relative[GUI_CONTAINER_NAME]
  if window then
    window.destroy()
  end
end

-- validate and return the entity and the player
local function preprocess_event(event)
  if event.gui_type ~= defines.gui_type.entity then
    return nil
  end
  local entity = event.entity
  if not entity or not entity.valid or entity.name ~= constants.CHEST_NAME then
    return nil
  end
  local player = game.players[event.player_index]
  if not player then
    return nil
  end
  return player, entity
end

-- get the 'items' and 'selected_index' for the drop-down for the entity
local function get_quality_info(unit_number)
  local data = GlobalState.entity_get_data(unit_number)
  local ql = GlobalState.get_quality_list()
  local sel_idx = 1 -- normal
  local items = {}
  for idx, qq in ipairs(ql) do
    table.insert(items, qq.localised_name)
    if qq.name == data.quality then
      sel_idx = idx
    end
  end
  return items, sel_idx
end

-- update the quality for the chest by selected_index
local function update_quality_by_index(unit_number, selected_index)
  local ql = GlobalState.get_quality_list()
  local qq = ql[selected_index]
  --log(("selbox %s %s"):format(selected_index, qq.name))
  local data = GlobalState.entity_get_data(unit_number)
  data.quality = qq.name
end

-- create the side GUI
local function on_gui_opened(event)
  local player, entity = preprocess_event(event)
  if not entity then
    return
  end

  --log(("on_gui_opened: %s"):format(serpent.line(event)))

  -- the gui has the unit_number in the tags, so we need a fresh GUI each time
  close_gui(player)

  local window = player.gui.relative.add({
    type = "frame",
    name = GUI_CONTAINER_NAME,
    direction = "vertical",
    anchor = {
      position = defines.relative_gui_position.right,
      gui = defines.relative_gui_type.container_gui,
    },
    caption = "Quality",
    tags = { entity_id = entity.unit_number }
  })
  local items, selected_index = get_quality_info(entity.unit_number)
  window.add({
    name=GUI_SELBOX_NAME,
    type="drop-down",
    items=items,
    tags={unit_number=entity.unit_number},
    selected_index=selected_index,
  })
end

local function on_gui_closed(event)
  local player, entity = preprocess_event(event)
  if not entity then
    return
  end
  --log(("on_gui_closed: %s"):format(serpent.line(event)))
  close_gui(player)
end

local function on_gui_selection_state_changed(event)
  local element = event.element
  if element and element.name == GUI_SELBOX_NAME then
    local unit_number = element.tags.unit_number
    if unit_number then
      update_quality_by_index(unit_number, element.selected_index)
    end
  end
end

-------------------------------------------------------------------------------

lib.events =
{
  [defines.events.on_gui_opened] = on_gui_opened,
  [defines.events.on_gui_closed] = on_gui_closed,
  [defines.events.on_gui_confirmed] = on_gui_closed,
  [defines.events.on_gui_selection_state_changed] = on_gui_selection_state_changed,
}

return lib
