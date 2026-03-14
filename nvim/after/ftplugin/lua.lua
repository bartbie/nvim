require("bartbie.runtime").run_once(function(this)
    local function find_parent(path, target)
        while path ~= "" do
            if path:match(target .. "$") then
                return path
            end
            path = path:gsub("/[^/]*$", "")
        end
        return nil
    end

    local cwd = vim.uv.cwd()
    local found = find_parent(cwd, "nvim/nvim")
    local this_parent = find_parent(this, "nvim/nvim")
    if found ~= nil and found == this_parent then
        vim.notify("hello from run_once, found you in config path", vim.log.levels.TRACE)
        return true
    end
    return false
end)
