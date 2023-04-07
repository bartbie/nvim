-- WARN:
-- utils.assets table should be used only after the plenaru is loaded;
-- lazy obviously after the lazy.vim

local LIB = require("bartbie.utils.lib")

--- PERF memory-wasteful but idc
local PRIVATE = {}

---@param path string | Path
---@return Asset
function PRIVATE.createAsset(path)
    local P = require("plenary.path")
    ---@type Path
    path = P:new(path)
    ---@class Asset
    local Asset = {
        ---@type string
        name = path.filename,
        ---@private
        __path = path,
    }

    function Asset:read()
        return self.__path:read()
    end

    ---@return string
    function Asset:string_path()
        return tostring(self.__path)
    end

    ---@return boolean
    function Asset:is_json()
        return require("plenary.filetype").detect(self:string_path(), {}) == "json"
    end

    ---@return table | nil
    function Asset:decode()
        return self:is_json() and vim.json.decode(self:read()) or nil
    end
    return Asset
end

---@param str boolean
---@return Path | string
---@overload fun(str: true): string
---@overload fun(str: false): Path
---@overload fun(): Path
function PRIVATE.lsp_configs_path(str)
    local path = require("plenary.path"):new(vim.fn.stdpath("config"), "assets", "lsp_configs")
    return str and tostring(path) or path
end

local M = {
    lib = LIB,
    ---@type { [string]: function }
    lazy = {},
    assets = {},
    os = {
        is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win32unix") == 1,
    },
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

---read lspconfigs
---@return Asset[]
function M.assets.lsp_configs()
    local IT = require("plenary.iterators")
    local scandir = require("plenary.scandir")
    local paths = scandir.scan_dir(PRIVATE.lsp_configs_path(true))
    return IT.iter(paths):map(PRIVATE.createAsset):tolist()
end

---get specific config
---@param filename string | Path
---@return Asset | nil
function M.assets.lsp_config(filename)
    ---@type Path
    local file = PRIVATE.lsp_configs_path():joinpath(filename)
    return file:exists() and PRIVATE.createAsset(file) or nil
end

return M
