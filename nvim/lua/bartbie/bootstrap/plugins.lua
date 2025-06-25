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
        local parent = vim.iter(fs.parents(rtp)):skip(1):next()
        rtp = fs.joinpath(parent, "nvim")
    end
    set_plugins_loader(rtp)
end

function M.load_all_plugin_configs()
    local rtp = assert(nix.get_roots().rtp_root)
    if fs.basename(rtp) == "lua" then
        local parent = vim.iter(fs.parents(rtp)):skip(1):next()
        rtp = fs.joinpath(parent, "nvim")
    end
    local files = vim.fn.glob(rtp .. "/plugins/*.lua", false, true)
    for _, file in ipairs(files) do
        local name = vim.fn.fnamemodify(file, ":t:r")
        local try = pcall(require, "plugins." .. name)
        if not try then
            vim.notify_once(("Couldn't load %s\npath: %s"):format(name, file), vim.diagnostic.severity.ERROR)
        end
    end
end

return M
