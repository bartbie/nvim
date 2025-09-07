---@param prefix string
---@return {commit_all: fun(self: self), set: fun(self: self, tree: table<string, any>), [string]: any}
local function create_config(prefix)
    local root = {}

    ---@alias tree table<string, tree | number|boolean|string>

    ---@param tree tree
    ---@param path string[]
    ---@param value any
    local function tree_add(tree, path, value)
        local current = tree
        for i = 1, #path - 1 do
            current[path[i]] = current[path[i]] or {}
            current = current[path[i]]
        end
        current[path[#path]] = value
        return value
    end

    ---@param tree tree
    ---@param path string[]
    local function tree_get(tree, path)
        return vim.tbl_get(tree, unpack(path))
    end

    ---@param tree tree
    ---@param other tree
    local function tree_extend(tree, other)
        vim.tbl_deep_extend("error", tree, other)
    end

    ---@param path string[]
    ---@param new string
    ---@return string[]
    local function path_new(path, new)
        local x = vim.deepcopy(path, false)
        x[#x + 1] = new
        return x
    end

    ---@param tree tree
    ---@param path? string[]
    ---@param result? table<string, number|boolean|string>
    ---@return table<string, number|boolean|string>
    local function flatten_tree(tree, path, result)
        path = path or { prefix }
        result = result or {}

        for k, v in pairs(tree) do
            local new_path = path_new(path, k)
            if type(v) == "table" and next(v) then
                flatten_tree(v, new_path, result)
            else
                result[table.concat(new_path, "#")] = v
            end
        end
        return result
    end

    ---@param path string[]
    local function build_node(path)
        return setmetatable({}, {
            __index = function(_, key)
                return build_node(vim.list_extend(vim.deepcopy(path), { key }))
            end,

            __newindex = function(_, key, value)
                local full_path = path_new(path, key)
                if type(value) == "table" then
                    local ns = tree_get(root, full_path)
                    if ns then
                        assert(type(ns) == "table")
                        tree_extend(ns, value)
                    else
                        tree_add(root, full_path, value)
                    end
                else
                    tree_add(root, full_path, value)
                end
            end,
        })
    end

    local r = build_node({})
    rawset(r, "commit_all", function()
        local flattened = flatten_tree(root)
        for key, value in pairs(flattened) do
            vim.g[key] = value
        end
        return flattened
    end)

    rawset(r, "set", function(_, tree)
        tree_extend(root, tree)
        return r
    end)

    rawset(r, "tree", function()
        return root
    end)

    return r
end

local M = {
    create_config = create_config,
}

return M
