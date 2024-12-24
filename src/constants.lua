--[[
Constant values that are shared between the stages.
]]
local M = {}

M.MODULE_NAME = "magic-quality-chest"
M.MODULE_PATH = "__" .. M.MODULE_NAME .. "__"

M.CHEST_NAME = "magic-quality-chest"

M.PATH_GRAPHICS = M.MODULE_PATH .. "/graphics"

function M.path_graphics(bn)
    return string.format("%s/%s", M.PATH_GRAPHICS, bn)
end

M.SERVICE_TICKS = 2*60
M.QUEUE_COUNT = M.SERVICE_TICKS + 16

return M
