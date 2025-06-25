local fs = vim.fs
local M = {}

local root = {
    cache = {},
}

function root.find(src, ...)
    local args = vim.iter({ ... }):flatten(math.huge):totable()
    table.sort(args)
    local hashed = table.concat(args, "")
    local nested = root.cache[src]
    if nested and nested[hashed] then
        return nested[hashed]
    end
    local res = fs.root(src, args)
    if nested then
        nested[hashed] = res or false
    else
        root.cache[src] = { [hashed] = res or false }
    end
    return res or nil
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

function M.get_error_state()
    return vim.deepcopy(nix_error_state, true)
end

function M.info()
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

local find = {}

function find.rtp_root(source, nix)
    if source:match("nix/store") then
        -- if we are at nix/store then just jump through parents
        return vim.iter(fs.parents(source)):skip(2):next()
    elseif nix and nix.shell.ours then
        -- if we are using our dev shell just find our flake.nix
        return fs.joinpath(root.find(source, "flake.nix"), "nvim")
    end
    return root.find(source, "rocks.toml") or root.find(source, "init.lua")
end

function find.loc_root(source, nix)
    if nix and nix.is_nix then
        if nix.shell.ours then
            return root.find(source, "flake.nix")
        elseif nix.shell.exists and nix.shell.name:match("bartbie%-nvim%-nix%-shell") then
            return root.find(vim.env.PWD, "flake.nix")
        else
            return vim.NIL -- using this sentinel value is pretty ugly but eh
        end
    end
    return root.find(source, "flake.nix") or root.find(source, "rocks.toml")
end

local function get_source(level)
    local x = debug.getinfo(level + 1, "S")
    return x and x.source:gsub("^@+", "")
end

function M.get_roots(source)
    local prev = get_source(2)
    source = fs.normalize(
        source
            or (
                prev == ":lua" -- we are being called from cmd, check from this file
                and get_source(1):gsub("/bartbie/nix.lua$", "")
            )
            or prev
    )
    local nix = M.info()
    return {
        rtp_root = find.rtp_root(source, nix),
        loc_root = find.loc_root(source, nix),
    }
end

function M._get_cache()
    return root.cache
end

return M
