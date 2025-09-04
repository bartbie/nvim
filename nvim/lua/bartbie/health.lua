local runtime = require("bartbie.runtime")
local nix = require("bartbie.nix").info()

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

local MINIMAL_VERSION = "0.12.0-dev"

local function main_check()
    local run_other = true
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
            run_other = false
        end
    end
    do
        if jit then
            ok("Using JIT")
        else
            error("Not using JIT!")
            run_other = false
        end
    end
    return run_other
end

local function deps_check()
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

local function nix_check()
    start("nix check")
    do
        if nix.is_nix then
            ok("Managed via Nix")
            if nix.is_nix_shim then
                ok("Using Nix config shim")
            end
        elseif not nix.shell then
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
    if not (nix.is_nix or nix.shell) then
        return
    end
    do
        start("nix shell info")
        info(("Using Nix Shell: `%s`"):format(nix.shell and "YES" or "NO"))
        if nix.shell then
            info(("Nix Shell name: `%s`"):format(nix.shell.name))
            info(("Nix Shell purity: `%s`"):format(nix.shell.purity))
        end
    end
end

local function path_purity()
    start("runtime paths purity")
    local paths = {
        ["`runtimepath`"] = runtime.runtime_path,
        ["`packpath`"] = runtime.pack_path,
        ["`package.path/luapath`"] = runtime.lua_path,
    }
    local i = 0
    for name, path in pairs(paths) do
        i = i + 1
        local ending = i ~= vim.tbl_count(paths) and "\n" or ""
        local impure = path():get_impure()
        if #impure > 0 then
            local fn
            if nix.is_nix_shim then
                local glob = vim.glob.to_lpeg(vim.env.PWD .. "{,/**}")
                local all_from_shim = vim.iter(impure):all(function(x)
                    return glob:match(x) ~= nil
                end)
                if all_from_shim then
                    ok(
                        name
                            .. " contains only impure config paths from nix config shim.\n\n\t"
                            .. table.concat(impure, "\n\t")
                            .. ending
                    )
                    goto continue
                end
                fn = error
            else
                fn = warn
            end
            fn(name .. " contains impure config paths!\n\n\t" .. table.concat(impure, "\n\t") .. ending)
        else
            ok(name .. " does not contain impure config paths")
        end
        ::continue::
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
        if nix.is_nix and not nix.is_nix_shim then
            info("nix roots of this config:")
            ok(runtime.config_root("nvim"))
            ok(runtime.config_root("lua"))
            ok(runtime.config_root("after"))
        else
            ok(("root of this config: `%s`"):format(runtime.config_root("nvim")))
        end
    end
end

local M = {}

function M.check()
    if main_check() then
        deps_check()
        nix_check()
        path_purity()
        stats()
    else
        error("Other checks will not run unless main requirements are satisfied: version, jit")
    end
end

M.MINIMAL_VERSION = MINIMAL_VERSION

return M
