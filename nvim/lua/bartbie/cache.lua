local M = {}

local function concat(list)
    return table.concat(list, "\0")
end

function M.memoized(fn)
    ---@type table<string, any>
    local cache = {}
    local wrapper = {}
    return setmetatable(wrapper, {
        __call = function(_self, ...)
            local key = concat({ ... })
            if cache[key] == nil then
                cache[key] = fn(...)
            end
            return cache[key]
        end,
        __index = {
            clear = function()
                cache = {}
            end,
            invalidate = function(_self, ...)
                local key = concat({ ... })
                cache[key] = nil
            end,
            stats = function()
                return vim.tbl_count(cache)
            end,
        },
    })
end

return M
