local fs = vim.fs
local nix = require("bartbie.nix")

local function get_rtp_root()
    local rtp = assert(nix.get_roots().rtp_root)
    if fs.basename(rtp) == "lua" then
        local parent = vim.iter(fs.parents(rtp)):skip(1):next()
        rtp = fs.joinpath(parent, "nvim")
    end
    return rtp
end

local M = {}

function M.setup_plugins_folder()
    M.install_plugins_loader()
    M.install_plugins_autoload()
end

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

function M.install_plugins_loader()
    set_plugins_loader(get_rtp_root())
end

function M.install_plugins_autoload()
    local au = require("bartbie.augroup")
    vim.api.nvim_create_autocmd("SourcePre", {
        pattern = {
            fs.joinpath("*", "after", "*.lua"),
            fs.joinpath("*", "after", "*.vim"),
        },
        once = true,
        group = au("source_plugins_folder"),
        callback = function()
            M.load_all_plugin_configs()
        end,
    })
end

local err_handler = function(name, file)
    return function(err)
        vim.notify_once(("Couldn't load %s\npath: %s"):format(name, file), vim.diagnostic.severity.ERROR)
        local trace = debug.traceback(err, 2)
        print(trace)
        return trace
    end
end

function M.load_all_plugin_configs()
    local rtp = get_rtp_root()
    local files = vim.fn.glob(rtp .. "/plugins/*.lua", false, true)
    for _, file in ipairs(files) do
        local name = vim.fn.fnamemodify(file, ":t:r")
        xpcall(require, err_handler(name, file), "plugins." .. name)
    end
end

-- so cheap they inflict the cost of redraw flash on user
local IGNORED_FTS = { "markdown", "jjdescription", "man", "checkhealth" }
function M.quickenter()
    if vim.v.vim_did_enter == 1 or vim.bo.filetype == "bigfile" then
        return
    end

    local buf = vim.api.nvim_get_current_buf()

    -- get ft before it changes
    local ft = vim.filetype.match({ buf = buf })

    if ft and not vim.list_contains(IGNORED_FTS, ft) then
        -- try enabling ts syntax or fallback to classic
        local lang = vim.treesitter.language.get_lang(ft)
        if not (lang and pcall(vim.treesitter.start, buf, lang)) then
            vim.bo[buf].syntax = ft
        end

        -- Trigger early redraw
        vim.cmd([[redraw]])
        -- on less common filetypes it can unset the ft afterwards for some reason (e.g. jjdescription)
        vim.bo[buf].filetype = ft
    end
end

return M
