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

local function main_check()
    start("bartbie's nvim config")
    do
        local try, res = pcall(function()
            return version ~= nil and version.ge(version(), version.parse(MINIMAL_VERSION))
        end)
        if try and res then
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
            error("Not using JIT!")
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

local nix_error_state = {
    is_nix = {
        state = false,
        msg = "`vim.g.is_nix` not set!",
    },
    is_nix_shim = {
        state = false,
        msg = "`vim.g.is_nix_shim` not set!",
    },
    is_nix_mismatch = {
        state = false,
        msg = "`vim.g.is_nix_shim` is `true` while `vim.g.is_nix` is not!",
    },
}
local nix_error_state_set = false

local function check_nix_err()
    if nix_error_state_set then
        return true
    end
    for _, data in pairs(nix_error_state) do
        if data.state then
            nix_error_state_set = true
            return true
        end
    end
    return false
end

local function nix_info()
    if check_nix_err() then
        return nil
    end

    local is_nix = vim.g.is_nix
    local is_nix_shim = vim.g.is_nix_shim
    local err = nix_error_state

    err.is_nix.state = is_nix == nil
    err.is_nix_shim.state = is_nix_shim == nil
    err.is_nix_mismatch.state = is_nix_shim == true and is_nix ~= true

    if check_nix_err() then
        return nil
    end

    local in_nix_shell = vim.env.IN_NIX_SHELL
    local exists = in_nix_shell ~= nil

    -- exists = true
    -- is_nix = true
    -- is_nix_shim = true

    return {
        is_nix = is_nix,
        is_nix_shim = is_nix_shim,
        shell = {
            exists = exists,
            purity = in_nix_shell,
            name = exists and vim.env.name or nil,
            ours = exists and is_nix_shim,
        },
    }
end

local function nix_check()
    start("nix check")
    local nix = nix_info()
    if nix == nil then
        for _, data in pairs(nix_error_state) do
            if data.state then
                error(data.msg)
            end
        end
        return
    end
    do
        if nix.is_nix then
            ok("Managed via Nix")
            if nix.is_nix_shim then
                ok("Using Nix config shim")
            end
        elseif not nix.shell.exists then
            ok("Not managed via Nix")
        elseif not nix.shell.ours then
            warn(
                ("Not managed via Nix yet in a Nix Shell!"):format(name),
                "This may be fine and you're simply using your own project's devShell"
            )
        else
            error(("Not managed via Nix while using `%s`!"):format(nix.shell.name))
        end
    end
    -- pester about impure config paths and nix shell only if we use nix or nix shell
    if not (nix.is_nix or nix.shell.exists) then
        return
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
    do
        start("nix shell info")
        info(("Using Nix Shell: `%s`"):format(nix.shell.exists and "YES" or "NO"))
        if nix.shell.exists then
            info(("Nix Shell name: `%s`"):format(nix.shell.name))
            info(("Nix Shell purity: `%s`"):format(nix.shell.purity))
        end
    end
end

local function rocks_check()
    start("rocks.nvim check")
    local nix = nix_info()
    local is_nix = nix and nix.is_nix or false
    local function check_path(path, name, check_shim)
        if path:match("nix/store") then
            ok(("Rocks.nvim uses `%s` from Nix"):format(name))
        elseif check_shim and nix and nix.shell.ours then
            ok(("Rocks.nvim uses `%s` from devShell"):format(name))
        else
            local report = is_nix and error or ok
            local exc = is_nix and "!" or ""
            report(("Rocks.nvim does not use %s from Nix%s"):format(name, exc))
        end
        info(("%s path: `%s`"):format(name, path))
    end
    do
        local stat, rocks = pcall(require, "rocks.api")
        if not stat then
            error("Rocks.nvim is not installed!")
            return
        end
        check_path(rocks.get_rocks_toml_path(), "rocks.toml", true)
    end
    do
        local config = vim.g.rocks_nvim
        check_path(config.luarocks_binary, "luarocks")
        info(("rocks path: `%s`"):format(config.rocks_path))
    end
end

local function stats()
    start("additional info")
    local nix = nix_info()
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
        local function root(...)
            return fs.root(source, vim.tbl_flatten({ ... }))
        end

        local function fmt_info(name)
            return function(s)
                if s == nil then
                    warn(("Couldn't find %s of this config"):format(name))
                    info(("source: `%s`"):format(source))
                else
                    ok(("%s of this config: `%s`"):format(name, s))
                end
            end
        end

        local rtp_info = fmt_info("rtp root")

        if source:match("nix/store") then
            -- if we are at nix/store then just jump through parents
            local parent = vim.iter(fs.parents(source)):skip(2):next()
            rtp_info(parent)
        elseif nix and nix.shell.ours then
            -- if we are using our dev shell just find our flake.nix
            rtp_info(vim.fs.joinpath(root("flake.nix"), "nvim"))
        else
            rtp_info(root("rocks.toml") or root("init.lua"))
        end

        local loc_info = fmt_info("location")

        if nix and nix.is_nix then
            if nix.shell.ours then
                loc_info(root("flake.nix"))
            elseif nix.shell.exists and nix.shell.name:match("bartbie%-nvim%-nix%-shell") then
                loc_info(fs.root(vim.env.PWD, "flake.nix"))
            else
                ok("Can't locate this config when using Nix without config-devShell's shim.")
            end
        else
            loc_info(root("flake.nix") or root("rocks.toml"))
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
