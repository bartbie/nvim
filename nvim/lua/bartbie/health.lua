local nix_helpers = require("bartbie.nix")

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
            return version ~= nil and version.ge(version(), assert(version.parse(MINIMAL_VERSION)))
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

local function nix_check()
    start("nix check")
    local nix = nix_helpers.info()
    if nix == nil then
        for _, data in pairs(nix_helpers.get_error_state()) do
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
                "Not managed via Nix yet in a Nix Shell!",
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

        local function fmt_info(name, src, root)
            if root == nil then
                warn(("Couldn't find %s of this config"):format(name))
                info(("source: `%s`"):format(src))
            else
                ok(("%s of this config: `%s`"):format(name, root))
            end
        end

        local source = fs.normalize(debug.getinfo(2, "S").source:sub(2))
        local roots = nix_helpers.get_roots(source)
        fmt_info("rtp root", source, roots.rtp_root)
        if roots.loc_root == vim.NIL then
            ok("Can't locate this config when using Nix without config-devShell's shim.")
        else
            fmt_info("location", source, roots.loc_root)
        end
    end
end

function M.check()
    main_check()
    nix_check()
    stats()
end

return M
