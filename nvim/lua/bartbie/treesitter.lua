local M = {}

--- DFS iterator over all descendants of node.
---@param node TSNode
---@return fun(): TSNode?
function M.walk_children_dfs(node)
    return coroutine.wrap(function()
        local function recur(n)
            for child in n:iter_children() do
                coroutine.yield(child)
                recur(child)
            end
        end
        recur(node)
    end)
end

--- Walk ancestor chain (excludes node itself by default).
---@param node TSNode
---@param opts? {inclusive?: boolean, with_previous?: boolean}
---@return fun(): TSNode?, TSNode?
function M.walk_parents(node, opts)
    opts = opts or {}
    return coroutine.wrap(function()
        local cur = opts.inclusive and node or node:parent()
        local prev = (not opts.inclusive) and node or nil
        while cur do
            coroutine.yield(cur, opts.with_previous and prev or nil)
            prev = cur
            cur = cur:parent()
        end
    end)
end

--- First ancestor without pending changes - safe subtree root for recalc.
---@param node TSNode
---@return TSNode?
function M.find_clean_parent(node)
    for parent in M.walk_parents(node) do
        if not parent:has_changes() then
            return parent
        end
    end
end

--- Containment test - returns side (0=a, 1=b) of the bigger span.
--- nil when no containment relationship exists.
---@param a TSNode?
---@param b TSNode?
---@return 0|1, TSNode
---@overload fun(a: TSNode?, b: TSNode?): nil, nil
function M.get_containing_node(a, b)
    if not a and not b then
        return nil
    end
    if not a then
        return 1, b
    end
    if not b then
        return 0, a
    end

    local a_start, a_end = a:start(), a:end_()
    local b_start, b_end = b:start(), b:end_()
    local contained = (b_start >= a_start and b_end <= a_end) or (a_start >= b_start and a_end <= b_end)
    if not contained then
        return nil
    end

    if (a_end - a_start) > (b_end - b_start) then
        return 0, a
    else
        return 1, b
    end
end

--- Deduplicate by node id, sort by start position.
---@param nodes TSNode[]
---@return TSNode[]
function M.sorted_node_set(nodes)
    local set = vim.iter(nodes)
        :unique(function(node)
            ---@cast node TSNode
            return node:id()
        end)
        :totable()
    table.sort(set, function(a, b)
        return a:start() < b:start()
    end)
    return set
end

return M
