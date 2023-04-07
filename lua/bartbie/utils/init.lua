local lib = require("bartbie.utils.lib")
local M = {
    lib = lib,
    ---@type { [string]: function }
    lazy = {},
}

--- check if plugin is on the plugin list
---@param plugin string
function M.lazy.has(plugin)
    return require("lazy.core.config").plugins[plugin] ~= nil
end

--- get plugin opts
---@param name string
function M.lazy.opts(name)
    local plugin = require("lazy.core.config").plugins[name]
    if not plugin then
        return {}
    end
    local Plugin = require("lazy.core.plugin")
    return Plugin.values(plugin, "opts", false)
end

return M
