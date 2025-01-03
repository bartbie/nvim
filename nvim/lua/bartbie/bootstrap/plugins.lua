local fs = vim.fs
local nix = require("bartbie.nix")

local M = {}

local function set_plugins_loader(base_path)
    table.insert(package.loaders, 2, function(module_name)
        local module_path = module_name:gsub("%.", "/")
        -- only run on require("plugins.*")
        if fs.dirname(module_path) ~= "plugins" then
            return nil
        end

        local parent = fs.joinpath(base_path, module_path)
        for _, ending in ipairs({ ".lua", "/init.lua" }) do
            local path = fs.normalize(parent .. ending)
            if vim.uv.fs_stat(path) then
                local chunk, error_msg = loadfile(path)
                if chunk then
                    return chunk
                else
                    error(("Error loading module '%s' from '%s':\n\t%s"):format(module_name, path, error_msg))
                end
            end
        end
        return nil
    end)
end

function M.bootstrap_plugins_loader()
    local rtp = assert(nix.get_roots().rtp_root)
    if fs.basename(rtp) == "lua" then
        rtp = fs.joinpath(vim.iter(fs.parents(rtp)):next(), "nvim")
    end
    set_plugins_loader(rtp)
end

return M

