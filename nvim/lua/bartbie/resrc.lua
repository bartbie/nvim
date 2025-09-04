local M = {}

--- read from resources
---@async
---@param name string
function M.read(name)
    local nio = require("nio")
    local path = require("bartbie.runtime").config_root("nvim", "resources", name)
    local f, err = nio.file.open(path)
    assert(err == nil) ---@cast f -nil
    local data, e = f.read()
    assert(e == nil)
    f.close()
    return data or ""
end

--- read json from resources
---@async
---@param name string
function M.read_json(name)
    local x = M.read(name)
    return vim.json.decode(x)
end

return M
