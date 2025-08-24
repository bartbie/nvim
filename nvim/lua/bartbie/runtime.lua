local M = {}

local stdp = vim.fn.stdpath

---@param patterns string[]
---@return fun(string): boolean
local include_if_any = function (patterns)
    ---@return boolean
    return function(path)
      return vim.iter(patterns):any(function(x)
         return not not path:match(vim.pesc(x))
      end)
    end
end
---@param patterns string[]
---@return fun(string): boolean
local include_if_all = function (patterns)
    ---@return boolean
    return function(path)
      return vim.iter(patterns):all(function(x)
         return not not path:match(vim.pesc(x))
      end)
    end
end
---@param patterns string[]
---@return fun(string): boolean
local exclude_if_any = function (patterns)
    ---@return boolean
    return function(path)
      return not vim.iter(patterns):any(function(x)
         return not not path:match(vim.pesc(x))
      end)
    end
end
---@param patterns string[]
---@return fun(string): boolean
local exclude_if_all = function (patterns)
    ---@return boolean
    return function(path)
      return not vim.iter(patterns):all(function(x)
         return not not path:match(vim.pesc(x))
      end)
    end
end

---@class Path
---@field get fun(self): string[])
---@field set fun(self, val: string[]): self
---@field clean_empty fun(self): self
---@field unique fun(self): self
---@field rm_if_any fun(self, pattern: string|string[]): self
---@field rm_if_all fun(self, pattern: string|string[]): self
---@field rm_if_not_all fun(self, pattern: string|string[]): self
---@field rm_if_not_any fun(self, pattern: string|string[]): self
---@field prepend fun(self, val: string): self
---@field append fun(self, val: string): self
---@field save fun(self):self
---@field reset fun(self): self
---@field new fun(self): Path

---@class PathArgs
---@field getter fun(): string[]
---@field setter fun(val: string[])

---@param args PathArgs
---@return Path
local function createPath(args)
    local data = args:getter()
    local function get()
        return data
    end
    ---@param x string[]
    local function set(x)
        data = x
    end

    ---@type Path
    return {
        get = function(self)
            return get()
        end,
        set = function(self, value)
            set(value)
            return self
        end,
        clean_empty = function (self)
            local new = vim.iter(get()):filter(function (x) return #x > 0 end):totable()
            set(new)
            return self
        end,
        unique = function (self)
            vim.list.unique(get())
            return self
        end,
        rm_if_any = function (self, pattern)
            if type(pattern) == "string" then
                pattern = {pattern}
            end
            local new = vim.iter(get()):filter(exclude_if_any(pattern)):totable()
            set(new)
            return self
        end,
        rm_if_all = function (self, pattern)
            if type(pattern) == "string" then
                pattern = {pattern}
            end
            local new = vim.iter(get()):filter(exclude_if_all(pattern)):totable()
            set(new)
            return self
        end,
        rm_if_not_all = function (self, pattern)
            if type(pattern) == "string" then
                pattern = {pattern}
            end
            local new = vim.iter(get()):filter(include_if_all(pattern)):totable()
            set(new)
            return self
        end,
        rm_if_not_any = function (self, pattern)
            if type(pattern) == "string" then
                pattern = {pattern}
            end
            local new = vim.iter(get()):filter(include_if_any(pattern)):totable()
            set(new)
            return self
        end,
        save = function (self)
            args.setter(get())
            return self
        end,
        reset = function (self)
            set(args.getter())
            return self
        end,
        prepend = function (self, val)
            table.insert(get(), 1, val)
            return self
        end,
        append = function (self, val)
            table.insert(get(), val)
            return self
        end,
        new = function (self)
            return createPath(args)
        end

    }
end

local lua_path = createPath({
    getter = function ()
        return vim.split(package.path, ";", {trimempty=true})
    end,
    setter = function (new)
        package.path = table.concat(new, ";")
    end
})

local rt_path = createPath({
    getter = function ()
        return vim.opt.runtimepath:get()
    end,
    setter = function (new)
        local opt = vim.opt.runtimepath
        local all = opt:get()
        for _, p in ipairs(all) do
            opt:remove(p)
        end
        for _, p in ipairs(new) do
            opt:append(p)
        end
    end
})

local pack_path = createPath({
    getter = function ()
        return vim.opt.packpath:get()
    end,
    setter = function (new)
        local opt = vim.opt.packpath
        local all = opt:get()
        for _, p in ipairs(all) do
            opt:remove(p)
        end
        for _, p in ipairs(new) do
            opt:append(p)
        end
    end
})

---@param l string[]
---@return string[]
local function add_after(l)
    return vim.iter(l):map(function (x)
        return vim.fs.joinpath(x, "after")
    end):totable()
end

M.clean_runtime_path = function()
      -- hide config folders
      local conf_dirs = {stdp("config"), unpack(stdp("config_dirs"))}
      -- hide data folders except main one (stdpath("data"))
      local data_dirs = stdp("data_dirs")
      return rt_path
      :clean_empty()
      :rm_if_not_any({"nix/store", stdp("data")})
      :rm_if_any(conf_dirs)
      :rm_if_any(add_after(conf_dirs))
      :rm_if_any(data_dirs)
      :rm_if_any(add_after(data_dirs))
      :unique()
      :save()

end

M.clean_pack_path = function ()
      -- hide config folders
      local conf_dirs = {stdp("config"), unpack(stdp("config_dirs"))}
      -- hide data folders except main one (stdpath("data"))
      local data_dirs = stdp("data_dirs")
      return pack_path
      :clean_empty()
      :rm_if_not_any({"nix/store", stdp("data")})
      :rm_if_any(conf_dirs)
      :rm_if_any(add_after(conf_dirs))
      :rm_if_any(data_dirs)
      :rm_if_any(add_after(data_dirs))
      :unique()
      :save()
end

M.clean_lua_path = function ()
    return lua_path
      :clean_empty()
      :rm_if_not_all("nix/store")
      :unique()
      :save()
end

M.runtime_path = function ()
    return rt_path:new()
end

M.pack_path = function ()
    return pack_path:new()
end

M.lua_path = function ()
    return lua_path:new()
end

return M
