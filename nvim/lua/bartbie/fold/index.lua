local lvl_cfg = require("bartbie.fold.config")
local M = {}

--- Fold level for a node type, 0 if not foldable.
--- Searches levels in descending order - higher-priority matches win.
---@param node TSNode
---@return integer
function M.node_base_lvl(node)
    local levels = lvl_cfg.curr_buf_levels()
    local precedence = vim.iter(levels):rev():totable()
    local t = node:type()
    for idx, level_set in ipairs(precedence) do
        ---@cast level_set table<string, boolean>
        if level_set[t] then
            return (#precedence + 1) - idx
        end
    end
    return 0
end

--- DFS iterator over all descendants of node.
---@param node TSNode
---@return fun(): TSNode?
local function walk_children_dfs(node)
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

--- Walk ancestor chain (excludes node itself).
---@param node TSNode
---@return fun(): TSNode?
local function walk_parents(node)
    return coroutine.wrap(function()
        local cur = node:parent()
        while cur do
            coroutine.yield(cur)
            cur = cur:parent()
        end
    end)
end

--- First ancestor without pending changes - safe subtree root for recalc.
---@param node TSNode
---@return TSNode?
local function find_clean_parent(node)
    for parent in walk_parents(node) do
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
local function get_containing_node(a, b)
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

---------------------------------------------------------------------------
-- LineEntry - per-line fold data, keyed by language tree
---------------------------------------------------------------------------

--- Per-source fold contribution. Multiple sources (injection languages)
--- can contribute to the same line independently.
---@class bartbie.fold._LineEntryValue
---@field level integer -- accumulated fold level
---@field marker ">" | "<" | nil -- ">" = fold start, "<" = fold end
---@field node TSNode

--- Holds fold contributions from all language trees touching a given line.
--- Keyed by tostring(ltree) - stable across reparses, unique per injection region.
---@class bartbie.fold.LineEntry
---@field _tree_map table<string, bartbie.fold._LineEntryValue>
---@field _cached string?
local LineEntry = {}
LineEntry.__index = LineEntry

function LineEntry.new_empty()
    return setmetatable({ _tree_map = {} }, LineEntry)
end

---@return fun(): string?, bartbie.fold._LineEntryValue?
function LineEntry:iter()
    local k
    return function()
        local id, v = next(self._tree_map, k)
        k = id
        return id, v
    end
end

function LineEntry:is_empty()
    for _, _ in self:iter() do
        return false
    end
    return true
end

--- Accumulate fold data for a source tree.
--- Multiple foldable nodes from the same tree (nested folds) add levels;
--- marker precedence: ">" wins over "<" wins over nil.
---@param treeid string
---@param level integer
---@param marker ">" | "<" | nil
---@param node TSNode
function LineEntry:set(treeid, level, marker, node)
    self._cached = nil
    local existing = self._tree_map[treeid]
    if existing then
        existing.level = existing.level + level
        if marker == ">" or (marker == "<" and existing.marker ~= ">") then
            existing.marker = marker
        end
    else
        self._tree_map[treeid] = {
            level = level,
            marker = marker,
            node = node,
        }
    end
end

--- Aggregate all sources into a foldexpr string (e.g. ">3", "<2", "1").
---@return string
function LineEntry:_foldexpr()
    ---@type "" | ">" | "<"
    local marker = ""
    local level = 0
    for _, value in self:iter() do
        level = level + value.level
        if value.marker == ">" or (value.marker == "<" and marker ~= ">") then
            marker = value.marker
        end
    end
    return marker .. level
end

---@return string
function LineEntry:foldexpr()
    if not self._cached then
        self._cached = self:_foldexpr()
    end
    return self._cached
end

---------------------------------------------------------------------------
-- Index - sparse lnum -> LineEntry map over the whole buffer
---------------------------------------------------------------------------

--- Sparse table keyed by 1-indexed lnum. Entries only exist for lines
--- participating in a fold. Supports incremental rebuild per language
--- tree and bulk shifting on edits via on_bytes.
---@class bartbie.fold.Index
---@field private _lines table<integer, bartbie.fold.LineEntry>
local Index = {}
Index.__index = Index
M.Index = Index

function Index.new_empty()
    return setmetatable({ _lines = {} }, Index)
end

---@param lnum integer 1-indexed
---@param treeid string
---@param lvl integer
---@param node TSNode
---@param marker ">" | "<" | nil
function Index:add(lnum, treeid, lvl, node, marker)
    if not self._lines[lnum] then
        self._lines[lnum] = LineEntry.new_empty()
    end
    self._lines[lnum]:set(treeid, lvl, marker, node)
end

---@param lnum integer 1-indexed
---@return bartbie.fold.LineEntry?
function Index:get(lnum)
    return self._lines[lnum]
end

---@param lnum integer 1-indexed
---@return string
function Index:foldexpr(lnum)
    local entry = self._lines[lnum]
    return entry and entry:foldexpr() or "0"
end

--- Walk all descendants of root, register fold-worthy nodes.
--- Fold region layout:
---   header line   -> ">" marker (e.g. function signature)
---   interior      -> level only, no marker
---   second-to-last -> "<" marker
---   last line     -> excluded (closing brace/end)
--- Nodes spanning <= 2 lines skipped - no interior to fold.
---@param treeid string
---@param root TSNode
function Index:_append_indices_for_node(treeid, root)
    for child in walk_children_dfs(root) do
        local lvl = M.node_base_lvl(child)
        if lvl == 0 then
            goto continue
        end
        -- CORRECTNESS: 0-indexed -> 1-indexed
        local first = child:start() + 1
        local scnd_last = child:end_() -- end-1: exclude closing line
        -- CORRECTNESS: single/two-line node has no interior, skip
        if first >= scnd_last then
            goto continue
        end
        -- CORRECTNESS: fold starts at header (e.g. function signature)
        self:add(first, treeid, lvl, child, ">")
        -- CORRECTNESS: interior lines get level only
        for lnum = first + 1, scnd_last - 1 do
            self:add(lnum, treeid, lvl, child, nil)
        end
        -- CORRECTNESS: fold ends at second-to-last line
        self:add(scnd_last, treeid, lvl, child, "<")
        ::continue::
    end
end

--- Full rebuild. Walks all language trees (DFS via for_each_tree),
--- each injection region tracked independently by tostring(ltree).
---@param buf integer
---@return bartbie.fold.Index
function Index.build(buf)
    local parser = vim.treesitter.get_parser(buf)
    if not parser then
        return Index.new_empty()
    end
    local index = Index.new_empty()
    parser:for_each_tree(function(tree, ltree)
        index:_append_indices_for_node(tostring(ltree), tree:root())
    end)
    return index
end

---------------------------------------------------------------------------
-- Incremental rebuild helpers
---------------------------------------------------------------------------

--- For each changed range, find the tightest clean ancestor to recalculate from.
--- Dirty nodes (has_changes) are walked upward until a stable parent is found.
---@param ltree vim.treesitter.LanguageTree
---@param changed_ranges Range4[]
---@return TSNode[]
local function find_changed_subtrees(ltree, changed_ranges)
    ---@type TSNode[]
    local subtrees = {}
    for _, range in ipairs(changed_ranges) do
        local node = ltree:node_for_range(range --[[@as Range4]])
        if node then
            local clean = (not node:has_changes()) and node or find_clean_parent(node)
            if clean then
                subtrees[#subtrees + 1] = clean
            end
        end
    end
    return subtrees
end

--- Deduplicate by node id, sort by start position.
---@param nodes TSNode[]
---@return TSNode[]
local function sorted_node_set(nodes)
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

--- Collapse overlapping subtrees into minimal set of covering roots.
--- WARN: roots should be biggest spans + weird edge cases of partial overlaps.
---@param subtrees TSNode[] sorted by start position
---@return TSNode[]
local function find_roots_of_subtrees(subtrees)
    ---@type TSNode[]
    local roots = {}
    local biggest_yet = nil
    for _, node in ipairs(subtrees) do
        --- CORRECTNESS
        --- rhs start always >= lhs start (sorted input)
        --- side:
        ---   nil -> no containment or first iter, add rhs and set as biggest
        ---   0   -> lhs bigger, discard rhs
        ---   1   -> rhs bigger, add rhs and set as biggest
        ---
        --- ```
        --- --A
        ---     --B
        ---         --C
        ---             --D
        ---     --b
        ---         --c
        --- --a
        ---             --d
        --- ```
        --- A -> A -> D
        local side, _ = get_containing_node(biggest_yet, node)
        if not side or side == 1 then
            roots[#roots + 1] = node
            biggest_yet = node
        end
    end
    return roots
end

--- Clear a single source's contributions from a line range (inclusive).
--- Removes the LineEntry entirely if no sources remain.
---@param treeid string
---@param start_row number 1-indexed
---@param end_row number 1-indexed
function Index:_nullify_at(treeid, start_row, end_row)
    for lnum = start_row, end_row do
        local entry = self._lines[lnum]
        if not entry then
            goto continue
        end
        entry._tree_map[treeid] = nil
        if entry:is_empty() then
            self._lines[lnum] = nil
        end
        ::continue::
    end
end

---@param treeid string
---@param node TSNode
function Index:_cleanup_at_node(treeid, node)
    local start_row = node:start() + 1
    local end_row = node:end_() + 1
    self:_nullify_at(treeid, start_row, end_row)
end

--- Incremental rebuild after on_changedtree. Per ltree:
--- find affected subtrees, clear their old entries, recalculate from roots.
---@param buf integer
---@param changed_ranges Range4[]
function Index:rebuild(buf, changed_ranges)
    local parser = vim.treesitter.get_parser(buf)
    if not parser then
        return
    end
    parser:for_each_tree(function(_tree, ltree)
        local id = tostring(ltree)
        local changed = find_changed_subtrees(ltree, changed_ranges)
        if #changed == 0 then
            return
        end
        local old_subtrees = sorted_node_set(changed)
        local roots = find_roots_of_subtrees(old_subtrees)
        for _, node in ipairs(old_subtrees) do
            self:_cleanup_at_node(id, node)
        end
        for _, sub in ipairs(roots) do
            self:_append_indices_for_node(id, sub)
        end
    end)
end

--- Shift index entries after an on_bytes edit. Called synchronously
--- before reparse - adjusts line numbers so on_changedtree sees correct positions.
---
--- Examples (letters = line slots, x/z/q/u/i = new content):
---   1 2 3 4 5 6 7 8 9 A B     start:4, D:5, I:2; delta=-3
---   1 2 3 4 x z       A B
---
---   1 2 3 4 5 6 7 8 9 A B     start:6, D:0, I:2; delta=2
---   1 2 3 4 5 6 x z 7 8 9 A B
---
---   1 2 3 4 5 6 7 8 9 A B     start:4, D:2, I:4; delta=2
---   1 2 3 4 q u i x 7 8 9 A B
---
---@param start_row number 0-indexed row from on_bytes
---@param deleted_delta number lines deleted below start_row
---@param inserted_delta number lines inserted below start_row
function Index:shift(start_row, deleted_delta, inserted_delta)
    -- INVARIANT: deltas are always down the buffer, ie. higher idxs than start_row
    start_row = start_row + 1 -- 0-indexed -> 1-indexed

    -- clean deleted zone
    for del_idx = start_row + 1, (start_row + deleted_delta) do
        self._lines[del_idx] = nil
    end

    local total_delta = inserted_delta - deleted_delta
    if total_delta == 0 then
        return
    end

    -- CORRECTNESS: _lines is sparse, must use pairs() not ipairs/#
    local idxs_to_shift = {}
    for idx in pairs(self._lines) do
        if idx > (start_row + deleted_delta) then
            idxs_to_shift[#idxs_to_shift + 1] = idx
        end
    end

    -- CORRECTNESS: sort direction prevents overwrites during re-key
    -- delta > 0: shift right, process high-to-low (desc)
    -- delta < 0: shift left, process low-to-high (asc)
    table.sort(idxs_to_shift, function(a, b)
        if total_delta < 0 then
            return a < b -- asc
        end
        return a > b -- desc
    end)

    for _, old in ipairs(idxs_to_shift) do
        self._lines[old + total_delta] = self._lines[old]
        self._lines[old] = nil
    end
end

return M
