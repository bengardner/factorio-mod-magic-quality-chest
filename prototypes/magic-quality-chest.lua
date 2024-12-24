--[[
Create a clone of the iron-chest.
]]
local constants = require "src.constants"

local name = constants.CHEST_NAME
local source_item_name = "requester-chest"
local source_prototype = "logistic-container"

local entity = table.deepcopy(data.raw[source_prototype][source_item_name])
entity.name = name
entity.animation.layers[1].filename = constants.path_graphics("entity/magic-quality-chest.png")
entity.minable.result = name
entity.se_allow_in_space = true
entity.render_not_in_network_icon = false
entity.use_exact_mode = true

local item = table.deepcopy(data.raw["item"][source_item_name])
item.name = name
item.place_result = name
item.icon = constants.path_graphics("icons/magic-quality-chest.png")
item.order = string.format("a[items]-b[%s]", constants.CHEST_NAME)
item.weight = 20000

local recipe = {
  name = name,
  type = "recipe",
  enabled = true,
  ingredients = {
    --{ name="iron-chest", amount=1, type="item" }
  },
  results = {
    { amount=1, name=name, type = "item" }
  }
}

data:extend({ entity, item, recipe })
