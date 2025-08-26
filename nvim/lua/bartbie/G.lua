local INDEX = "_bartbie"

local mkmetatable = function(storage)
    return {
        __index = function(_, k)
            local res = rawget(storage, k)
            if res == nil then
                error("bartbie.G store doesn't have " .. k .. " global!")
            end
            return res
        end,
        __newindex = function(_, k, v)
            if type(k) ~= "string" then
                error("bartbie.G store: key (" .. k .. ") is not a string!")
            end
            rawset(storage, k, v)
        end,
    }
end

if _G[INDEX] == nil then
    local g = {}
    setmetatable(g, mkmetatable(g))
    _G[INDEX] = g
end

local G = _G[INDEX]
local M = {}

---@param k string
---@param v any
function M.set(k, v)
    G[k] = v
end

---@param k string?
---@return any
function M.get(k)
    return k == nil and G or G[k]
end

setmetatable(M, mkmetatable(G))

return M
