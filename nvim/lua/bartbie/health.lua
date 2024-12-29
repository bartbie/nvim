local M = {}

local start = vim.health.start or vim.health.report_start
local ok = vim.health.ok or vim.health.report_ok
local warn = vim.health.warn or vim.health.report_warn
local error = vim.health.error or vim.health.report_error
local info = vim.health.info or vim.health.report_info
local version = vim.version

local DEPENDENCIES = {
    "git",
    "rg",
    { "fd", "fdfind" },
    "lazygit",
    "fzf",
    { "gcc", "clang" },
    "luarocks",
    "stylua",
}

local MINIMAL_VERSION = "0.10.0"

local is_nix = vim.g.is_nix

local function main_check()
    start("bartbie's nvim config")
    do
        local fmt = function(ver)
            return table.concat(ver, ".")
        end
        if version ~= nil and version.ge(version(), version.parse(MINIMAL_VERSION)) then
            ok(("Using Neovim `%s` >= `%s`"):format(version(), MINIMAL_VERSION))
        else
            error(
                ("Neovim >= `%s` is required"):format(MINIMAL_VERSION),
                ("Current version: `%s`"):format(version and version() or "really old.")
            )
        end
    end
    do
        if jit then
            ok("Using JIT")
        else
            warn("Not using JIT!")
        end
    end
    do
        info("dependencies:")
        for _, cmd in ipairs(DEPENDENCIES) do
            local name = type(cmd) == "string" and cmd or vim.inspect(cmd)
            local commands = type(cmd) == "string" and { cmd } or cmd
            ---@cast commands string[]
            local found = false

            for _, c in ipairs(commands) do
                if vim.fn.executable(c) == 1 then
                    found = true
                    ok(("`%s` is installed"):format(c))
                end
            end

            if not found then
                warn(("`%s` %s not installed"):format(name, type(cmd) == "string" and "is" or "are"))
            end
        end
    end
end

local function nix_check()
    start("nix check")
    do
        local in_nix_shell = vim.fn.IN_NIX_SHELL
        local function info_nix_shell()
            info(in_nix_shell and "In Nix Shell" or "Not in Nix Shell")
        end
        if is_nix == nil then
            error("vim.g.is_nix not set!")
            info_nix_shell()
            return
        end
        if not is_nix then
            if not in_nix_shell then
                ok("Not managed via Nix")
                info_nix_shell()
                return
            end
            warn("Not managed via Nix yet in a Nix Shell!")
        else
            ok("Managed via Nix")
        end
        info_nix_shell()
    end
    do
        local rtp = vim.opt.runtimepath:get()
        local configs = { vim.fn.stdpath("config"), unpack(vim.fn.stdpath("config_dirs")) }
        local non_isolated_configs = vim.iter(rtp)
            :filter(function(s)
                return vim.iter(configs):any(function(c)
                    return s:match(c)
                end)
            end)
            :totable()

        if #non_isolated_configs ~= 0 then
            error("runtimepath contains impure config paths!")
            info("impure paths:")
            info(table.concat(non_isolated_configs, "\n"))
        else
            ok("runtimepath does not contain impure config paths")
        end
    end
end

local function rocks_check()
    start("rocks.nvim check")
    local function check_path(path, name)
        if path:match("nix/store") then
            ok(("Rocks.nvim uses `%s` from Nix"):format(name))
        elseif is_nix then
            error(("Rocks.nvim does not use %s from Nix"):format(name))
        else
            ok(("Rocks.nvim does not use %s from Nix"):format(name))
        end
        info(("%s path: `%s`"):format(name, path))
    end
    do
        local stat, rocks = pcall(require, "rocks.api")
        if not stat then
            error("Rocks.nvim is not installed!")
            return
        end
        check_path(rocks.get_rocks_toml_path(), "rocks.toml")
    end
    do
        local config = vim.g.rocks_nvim
        check_path(config.luarocks_binary, "luarocks")
        info(("rocks path: `%s`"):format(config.rocks_path))
    end
end

local function stats()
    start("additional info")
    do
        local paths = {
            "config",
            "cache",
            "data",
            "state",
        }
        for _, name in ipairs(paths) do
            info(("stdpath(`%s`): `%s`"):format(name, vim.fn.stdpath(name)))
        end
    end
    do
        local fs = vim.fs
        if fs == nil then
            return
        end
        local source = fs.normalize(debug.getinfo(2, "S").source:sub(2))
        if source:match("nix/store") then
            local parent = vim.iter(fs.parents(source)):skip(1):next()
            info(("rtp root of this config: `%s`"):format(parent))
        else
            local function root(...)
                return fs.root(source, vim.tbl_flatten({ ... }))
            end
            info(("rtp root of this config: `%s`"):format(root("rocks.toml") or root("init.lua")))
            info(("location of this config: `%s`"):format(root("flake.nix") or root("rocks.toml")))
        end
    end
end

function M.check()
    main_check()
    nix_check()
    rocks_check()
    stats()
end

return M
