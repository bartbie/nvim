---@vararg string
local function g(...)
    -- NOTE: this could be a metatable hack but whatever, let's make this simple
    local args = { ... }
    return function(val)
        local str = "conjure#" .. vim.iter(args):join("#")
        vim.g[str] = val
    end
end

---@vararg string
local function mk_g(...)
    local parent = { ... }
    return function(...)
        local children = { ... }
        return g(unpack(vim.list_extend(vim.deepcopy(parent), children)))
    end
end

g("filetype", "scheme")("conjure.client.scheme.stdio")
local scheme_stdio = mk_g("client", "scheme", "stdio")
-- chez
scheme_stdio("command")("petite")
scheme_stdio("prompt_pattern")("> $")
scheme_stdio("value_prefix_pattern")(false)

local map = mk_g("mapping")
map("doc_word")("gk")
