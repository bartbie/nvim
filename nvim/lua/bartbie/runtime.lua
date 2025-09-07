local M = {}

local stdp = vim.fn.stdpath

---@alias bartbie.runtime.FilterGate "and" | "or" | "xor" | "nand" | "nor" | "xnor"
---@alias bartbie.runtime.Pattern vim.lpeg.Pattern
---@alias bartbie.runtime.Glob string

local wo_neg = {
    ["and"] = "and",
    ["or"] = "or",
    xor = "xor",
    nand = "and",
    nor = "or",
    xnor = "xor",
}

local has_neg = {
    ["and"] = false,
    ["or"] = false,
    xor = false,
    nand = true,
    nor = true,
    xnor = true,
}

---@param patterns bartbie.runtime.Pattern[]
local f_and = function(patterns)
    return function(path)
        return #patterns ~= 0
            and vim.iter(patterns):all(function(pat)
                return pat:match(path) ~= nil
            end)
    end
end

---@param patterns bartbie.runtime.Pattern[]
local f_or = function(patterns)
    return function(path)
        return #patterns ~= 0
            and vim.iter(patterns):any(function(pat)
                return pat:match(path) ~= nil
            end)
    end
end

---@param patterns bartbie.runtime.Pattern[]
local f_xor = function(patterns)
    return function(path)
        local found = false
        for _, pat in ipairs(patterns) do
            if pat:match(path) then
                if found then
                    return false
                end
                found = true
            end
        end
        return found
    end
end

---@param patterns bartbie.runtime.Glob[]
---@return bartbie.runtime.Pattern[]
local function convert_patterns(patterns)
    return vim.iter(patterns):map(vim.glob.to_lpeg):totable()
end

--NOTE: include has to negate has_neg and exclude not
-- idk why, i thought the inverse should be true
-- i spent too much time, it's probably the fault of inverse fn

---@param gate bartbie.runtime.FilterGate
---@param patterns bartbie.runtime.Glob[]
---@return fun(path: string): boolean
local include = function(gate, patterns)
    local invert = has_neg[gate]

    gate = wo_neg[gate]
    patterns = convert_patterns(patterns)

    local fun
    if gate == "and" then
        fun = f_and(patterns)
    elseif gate == "or" then
        fun = f_or(patterns)
    else
        fun = f_xor(patterns)
    end

    return function(path)
        local res
        if invert then
            res = not fun(path)
        else
            res = fun(path)
        end
        return res
    end
end

---@param gate bartbie.runtime.FilterGate
---@param patterns bartbie.runtime.Glob[]
---@return fun(path: string): boolean
local exclude = function(gate, patterns)
    local inc = include(gate, patterns)
    return function(path)
        return not inc(path)
    end
end

M.include = include
M.exclude = exclude

local nix_store_glob = "{,**/}nix/store{,/**}"
local after_glob = "{,**/}after{,/**}"
local after_glob_pat = vim.glob.to_lpeg(after_glob)

---@class bartbie.runtime.Path
---@field set fun(self: self, val: string[]): self
---@field get fun(self: self): string[]
---@field toiter fun(self: self): Iter
---@field filtered fun(self: self, method: bartbie.runtime.FilterGate, pattern: bartbie.runtime.Glob|bartbie.runtime.Glob[]): string[]
---@field match fun(self: self, method: bartbie.runtime.FilterGate, pattern: bartbie.runtime.Glob|bartbie.runtime.Glob[]): boolean
---@field only fun(self: self, method: bartbie.runtime.FilterGate, pattern: bartbie.runtime.Glob|bartbie.runtime.Glob[]): self
---@field drop fun(self: self, method: bartbie.runtime.FilterGate, pattern: bartbie.runtime.Glob|bartbie.runtime.Glob[]): self
---@field unique fun(self: self): self
---@field clean_empty fun(self: self): self
---@field clean_impure fun(self: self, strict: boolean?): self
---@field clean fun(self: self, strict: boolean?): self
---@field prepend fun(self: self, val: string): self
---@field append fun(self: self, val: string): self
---@field prepend_before_after fun(self: self, val: string): self
---@field insert fun(self: self, val: string, idx: number): self
---@field save fun(self: self):self
---@field reset fun(self: self): self
---@field is_pure fun(self: self, strict: boolean?): boolean
---@field get_pure fun(self: self, strict: boolean?): string[]
---@field get_impure fun(self: self, strict: boolean?): string[]
---@field new fun(self: self): bartbie.runtime.Path
---@field count fun(self: self): integer
---@field print fun(self: self): nil

---@class PathArgs
---@field getter fun(): string[]
---@field setter fun(val: string[])

---@param args PathArgs
---@return bartbie.runtime.Path
local function createPath(args)
    local data = args:getter()
    local first_after = nil

    local function get()
        return data
    end
    ---@param x string[]
    local function set(x)
        first_after = nil
        data = x
    end

    ---@param x string
    ---@param ind number?
    local function insert(x, ind)
        first_after = nil
        if ind == nil then
            table.insert(data, x)
        else
            table.insert(data, ind, x)
        end
        return data
    end

    vim.fn.stdpath("data")
    ---@param strict boolean|nil
    local function handle_strict(strict)
        return strict and { nix_store_glob } or { nix_store_glob, stdp("data") .. "/site{,/**}" }
    end

    ---@type bartbie.runtime.Path
    return {
        get = function(self)
            return get()
        end,
        toiter = function(self)
            return vim.iter(get())
        end,
        filtered = function(self, gate, pattern)
            if type(pattern) == "string" then
                pattern = { pattern }
            end
            return self:toiter():filter(include(gate, pattern)):totable()
        end,

        set = function(self, value)
            set(value)
            return self
        end,
        clean_empty = function(self)
            local new = vim.iter(get())
                :filter(function(x)
                    return #x > 0
                end)
                :totable()
            set(new)
            return self
        end,
        unique = function(self)
            vim.list.unique(get())
            return self
        end,
        match = function(self, method, pattern)
            if type(pattern) == "string" then
                pattern = { pattern }
            end
            return self:toiter():all(include(method, pattern))
        end,
        only = function(self, method, pattern)
            if type(pattern) == "string" then
                pattern = { pattern }
            end
            set(self:toiter():filter(include(method, pattern)):totable())
            return self
        end,
        drop = function(self, method, pattern)
            if type(pattern) == "string" then
                pattern = { pattern }
            end
            set(self:toiter():filter(exclude(method, pattern)):totable())
            return self
        end,
        save = function(self)
            args.setter(get())
            return self
        end,
        reset = function(self)
            set(args.getter())
            return self
        end,
        prepend = function(self, val)
            insert(val, 1)
            return self
        end,
        append = function(self, val)
            insert(val)
            return self
        end,
        new = function(self)
            return createPath(args)
        end,
        prepend_before_after = function(self, val)
            if first_after == nil then
                first_after = vim.iter(ipairs(get())):find(function(_, e)
                    return after_glob_pat:match(e) ~= nil
                end) or #get()
            end
            insert(val, first_after)
            first_after = after_glob_pat:match(val) and first_after - 1 or first_after
            return self
        end,
        insert = function(self, val, idx)
            insert(val, idx)
            return self
        end,
        is_pure = function(self, strict)
            return self:match("or", handle_strict(strict))
        end,
        get_impure = function(self, strict)
            return self:filtered("nor", handle_strict(strict))
        end,
        get_pure = function(self, strict)
            return self:filtered("or", handle_strict(strict))
        end,
        clean_impure = function(self, strict)
            local function map_to_glob(l)
                return vim.iter(l)
                    :map(function(s)
                        return s .. "{,/**}"
                    end)
                    :totable()
            end
            -- hide config folders
            local conf_dirs = map_to_glob({ stdp("config"), unpack(stdp("config_dirs")) })
            -- hide data folders except main one (stdpath("data"))
            local data_dirs = map_to_glob(stdp("data_dirs"))
            local VRT = vim.env.VIMRUNTIME .. "{,/**}"

            return self
                :only("or", handle_strict(strict))
                :drop("or", conf_dirs)
                -- HACK: force keeping vim.env.VIMRUNTIME/** by xoring on itself
                :drop(
                    "xor",
                    { VRT, VRT, unpack(data_dirs) }
                )
                -- hide any stuff that's not in data_dirs and still loiters
                :drop(
                    "xor",
                    { stdp("data") .. "/site{,/**}", "**/share/nvim/site{,/**}" }
                )
        end,
        clean = function(self, strict)
            return self:clean_impure(strict):clean_empty():unique()
        end,
        count = function(_self)
            return #get()
        end,
        print = function(_self)
            print("entries:")
            for index, path in ipairs(get()) do
                print(string.format("  [%d] %s", index, path))
            end
            print(string.format("\nTotal: %d entries", #get()))
        end,
    }
end

M.createPath = createPath

local lua_path = createPath({
    getter = function()
        return vim.split(package.path, ";", { trimempty = true })
    end,
    setter = function(new)
        package.path = table.concat(new, ";")
    end,
})

local rt_path = createPath({
    getter = function()
        return vim.opt.runtimepath:get()
    end,
    setter = function(new)
        local opt = vim.opt.runtimepath
        local all = opt:get()
        for _, p in ipairs(all) do
            opt:remove(p)
        end
        for _, p in ipairs(new) do
            opt:append(p)
        end
    end,
})

local pack_path = createPath({
    getter = function()
        return vim.opt.packpath:get()
    end,
    setter = function(new)
        local opt = vim.opt.packpath
        local all = opt:get()
        for _, p in ipairs(all) do
            opt:remove(p)
        end
        for _, p in ipairs(new) do
            opt:append(p)
        end
    end,
})

M.clean_runtime_path = function()
    return rt_path:clean(false):save()
end

M.clean_pack_path = function()
    return pack_path:clean(false):save()
end

M.clean_lua_path = function()
    return lua_path:clean(true):save()
end

M.runtime_path = function()
    return rt_path:new()
end

M.pack_path = function()
    return pack_path:new()
end

M.lua_path = function()
    return lua_path:new()
end

do
    local fs = vim.fs

    ---@param level integer
    ---@return string
    local function get_source(level)
        local x = debug.getinfo(level + 1, "S")
        return x and x.source:gsub("^@+", "")
    end

    ---@return string
    local function find_config()
        local G = require("bartbie.G")
        local source = get_source(2)
        local function assert_glob(str, pat)
            assert((vim.glob.to_lpeg(pat):match(str)), str .. " doesn't match: " .. pat)
            return str
        end

        source = fs.normalize(
            -- if :lua, we are being called from cmd, check from this file
            (source == ":lua" and get_source(1):gsub("/bartbie/runtime.lua$", "")) or source
        )

        if G.is_nix_shim then
            -- our dev shell - find our flake.nix
            -- INVARIANT: we *must* be at nvim/lua/bartbie/
            assert_glob(source, "{,**/}nvim/lua/bartbie/**")
            return fs.joinpath(fs.root(source, "flake.nix"), "nvim")
        elseif G.is_nix then
            -- INVARIANT: we *must* be at nix/store
            assert_glob(source, "{,**/}nix/store/**/*nvim-rtp{,/**}")

            -- nix - jump through parents
            -- nix/store/hash-rtp/lua/bartbie
            --           ^ we want this
            return assert_glob(assert(vim.iter(fs.parents(source)):nth(4)), "{,**/}nix/store/**/*nvim-rtp{,/}")
        else
            -- no nix at all - try to find our root files or ask nvim
            return fs.root(source, {
                ".luacheckrc",
                ".luarc.json",
                ".stylua.toml",
                "rocks.toml",
            }) or stdp("config")
        end
    end

    ---@type string?
    local config

    ---@param folder
    ---| "lua" nvim/lua
    ---| "nvim" nvim/
    ---| "after" nvim/after
    ---@param ... string
    ---@return string
    M.config_root = function(folder, ...)
        assert(type(folder) == "string")
        local G = require("bartbie.G")
        if not config then
            config = find_config()
        end
        if G.is_nix_shim or not G.is_nix then
            folder = folder == "nvim" and "" or folder --[[@as string]]
        end
        return vim.fs.joinpath(config, folder, ...)
    end
end

return M
