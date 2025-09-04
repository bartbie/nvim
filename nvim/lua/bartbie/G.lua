local INDEX = "_bartbie"

---@param storage table<string, any>
local mkmetatable = function(storage)
    return {
        ---@param k string
        ---@return any
        __index = function(_, k)
            local res = rawget(storage, k)
            if res == nil then
                error("bartbie.G store doesn't have " .. k .. " global!")
            end
            return res
        end,
        ---@param k string
        ---@param v any
        ---@return any
        __newindex = function(_, k, v)
            if type(k) ~= "string" then
                error("bartbie.G store: key (" .. k .. ") is not a string!")
            end
            rawset(storage, k, v)
        end,
    }
end

if _G[INDEX] == nil then
    ---@type table<string, any>
    local g = {}
    g.is_nix = vim.g.is_nix or false
    g.is_nix_shim = g.is_nix and vim.g.is_nix_shim or false

    setmetatable(g, mkmetatable(g))

    _G[INDEX] = g
end
---@type table<string, any>
local G = _G[INDEX]

---@class bartbie.G
---@field get fun(k: string): any
---@field get fun(): table<string, any>
---@field set fun(k: string, v: any)
---@field is_nix boolean
---@field is_nix_shim boolean
---@field [string] any
local M = {}

function M.set(k, v)
    G[k] = v
end

function M.get(k)
    return k == nil and G or G[k]
end

setmetatable(M, mkmetatable(G))

return M
