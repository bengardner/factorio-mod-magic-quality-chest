local M = {}

local util = require("__core__/lualib/util")

local constants = require "src.constants"

local function storage_init()
  if storage.entities == nil then
    storage.entities = {}
  end
  if storage.entity_data == nil then
    storage.entity_data = {}
  end
  if storage.service_queues == nil then
    storage.service_queues = {}
    storage.service_ticks = game.tick
    storage.service_index = 1 + (game.tick % constants.QUEUE_COUNT)
  end
end

function M.entity_register(entity)
  if entity ~= nil and entity.valid then
    storage_init()
    local unum = entity.unit_number
    if unum ~= nil then
      -- store a ref to the entity
      if storage.entities[unum] == nil then
        storage.entities[unum] = entity
      end

      -- create entity data, if needed
      local info = storage.entity_data[unum]
      if info == nil then
        info = { unit_number=unum, entity=entity }
        storage.entity_data[unum] = info
        log(string.format("%s: added %s", game.tick, info.unit_number))
      end

      M.entity_queue(info)
    end
  end
end

function M.entity_get_data(unit_number)
  return storage.entity_data[unit_number] or {}
end

function M.entity_queue(info)
  if info and info.unit_number and info.entity and info.entity.valid then
    local ticks = constants.SERVICE_TICKS
    local the_tick = game.tick + ticks
    local qidx = 1 + ((the_tick) % constants.QUEUE_COUNT)
    local qq = storage.service_queues[qidx]
    if qq == nil then
      qq = {}
      storage.service_queues[qidx] = qq
    end
    --log(string.format("%s: queued %s for tick %s @ %s", game.tick, info.unit_number, the_tick, qidx))
    qq[info.unit_number] = info
  end
end

-- Grabs the next expired entity.
-- returns the info table with { unit_number=entity.unit_number, entity=entity, ... }
function M.entity_next()
  storage_init()

  while game.tick >= storage.service_ticks do

    -- grab the first ready entity
    local qq = storage.service_queues[storage.service_index] or {}
    local unum, info = next(qq)
    if unum then
      -- remove from the slice
      qq[unum] = nil
      if info.entity and info.entity.valid then
        -- if still valid, re-add and return
        --log(string.format("%s: servicing %s @ %s", game.tick, unum, storage.service_index))
        M.entity_queue(info)
        return info
      end
      log(string.format("%s: removed %s", game.tick, unum))
      -- entity no longer valid, so forget about it
      storage.entities[unum] = nil
      -- NOTE: this would be a good spot for a cleanup callback
      storage.entity_data[unum] = nil
    end

    -- no entities, so advance to the next slice
    storage.service_ticks = storage.service_ticks + 1
    storage.service_index = 1 + (storage.service_ticks % constants.QUEUE_COUNT)
  end
end

local quality_cache = {} -- key=selected_index, val=localised_name
function M.get_quality_list()
  if #quality_cache == 0 then
    -- this is the first call, so gather the qualities and sort by level
    local ql = {}
    for _, qp in pairs(prototypes.quality) do
      if not qp.hidden then
        table.insert(ql, qp)
      end
    end
    table.sort(ql, function(a, b)
      return a.level < b.level
    end)
    for _, qq in ipairs(ql) do
      table.insert(quality_cache, qq)
    end
  end
  return quality_cache
end

return M
