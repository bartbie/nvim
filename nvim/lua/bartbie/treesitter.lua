local textlib = require("bartbie.text")
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

---@param node TSNode
function M.iter_named_children(node)
    return coroutine.wrap(function()
        for _, n in ipairs(node:named_children()) do
            coroutine.yield(n)
        end
    end)
end

---@param node TSNode
---@return TSNode?
function M.first_child(node)
    return node:child(0)
end

---@param node TSNode
---@return TSNode?
function M.last_child(node)
    return node:child(node:child_count() - 1)
end

---@param node TSNode
function M.first_named_child(node)
    return node:named_child(0)
end

---@param node TSNode
function M.last_named_child(node)
    return node:named_child(node:named_child_count() - 1)
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

---@param a TSNode
---@param b TSNode
---@return boolean
function M.starts_before(a, b)
    return M.range_tbl(a).start_byte < M.range_tbl(b).start_byte
end

---@param a TSNode
---@param b TSNode
---@return boolean
function M.starts_after(a, b)
    return M.range_tbl(a).start_byte > M.range_tbl(b).start_byte
end

---@param a TSNode
---@param b TSNode
---@return boolean
function M.ends_before(a, b)
    return M.range_tbl(a).end_byte < M.range_tbl(b).start_byte
end

---@param a TSNode
---@param b TSNode
---@return boolean
function M.ends_after(a, b)
    return M.range_tbl(a).start_byte > M.range_tbl(b).end_byte
end

---@param a TSNode
---@param b TSNode
---@return boolean
function M.overlaps(a, b)
    local ar = M.range_tbl(a)
    local br = M.range_tbl(b)
    local a_start, a_end = ar.start_byte, ar.end_byte
    local b_start, b_end = br.start_byte, br.end_byte
    return (a_start <= b_start and b_start <= a_end) or (b_start <= a_start and a_start <= b_end)
end

---@param a TSNode
---@param b TSNode
---@return boolean
function M.is_before(a, b)
    return M.starts_before(a, b) and M.ends_before(a, b)
end

---@param a TSNode
---@param b TSNode
---@return boolean
function M.is_after(a, b)
    return M.starts_after(a, b) and M.ends_after(a, b)
end

---@param a TSNode
---@param b TSNode
---@return boolean
function M.contains(a, b)
    local ar = M.range_tbl(a)
    local br = M.range_tbl(b)
    local a_start, a_end = ar.start_byte, ar.end_byte
    local b_start = br.start_byte
    return (a_start <= b_start and b_start <= a_end)
end

---@param a TSNode
---@param b TSNode
---@return boolean
function M.exactly_same_area(a, b)
    local ar = M.range_tbl(a)
    local br = M.range_tbl(b)
    return ar == br
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

    local overlap = M.overlaps(a, b)
    if not overlap then
        return nil
    end
    if M.contains(a, b) then
        return 0, a
    end
    return 1, b
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
        return M.range_tbl(a).start_byte < M.range_tbl(b).start_byte
    end)
    return set
end

---@param node TSNode
function M.nearest_named(node)
    for n in M.walk_parents(node, { inclusive = true }) do
        if n:named() then
            return n
        end
    end
end

---@param node TSNode
---@return boolean
function M.is_leaf(node)
    return node:named_child_count() == 0
end

---@param node TSNode
---@return fun(): TSNode?
function M.iter_leaf_children(node)
    return coroutine.wrap(function()
        for child in M.iter_named_children(node) do
            if M.is_leaf(child) then
                coroutine.yield(child)
            end
        end
    end)
end

---@param node TSNode
---@return fun(): TSNode?
function M.iter_non_leaf_children(node)
    return coroutine.wrap(function()
        for child in M.iter_named_children(node) do
            if not M.is_leaf(child) then
                coroutine.yield(child)
            end
        end
    end)
end

---@param node TSNode
---@return boolean
function M.only_leaf_children(node)
    for _ in M.iter_non_leaf_children(node) do
        return false
    end
    return true
end

---@param node TSNode
---@param buf integer?
---@return vim.treesitter.LanguageTree?
function M.get_lang_tree(node, buf)
    local parser = vim.treesitter.get_parser(buf or 0)
    if not parser then
        return
    end

    local r1, c1, r2, c2 = node:range()
    return parser:language_for_range({ r1, c1, r2, c2 })
end

---@class bartbie.treesitter.RangeTbl
---@field start_row integer
---@field start_col integer
---@field start_byte integer
---@field end_row integer
---@field end_col integer
---@field end_byte integer

---@param node TSNode
function M.range_tbl(node)
    local sr, sc, sb, er, ec, eb = node:range(true)
    return {
        start_row = sr,
        start_col = sc,
        start_byte = sb,
        end_row = er,
        end_col = ec,
        end_byte = eb,
    }
end

-- text mangling

---@param buf integer
---@param dst_node TSNode
---@param replacement string|string[]
function M.set_node_text(buf, dst_node, replacement)
    local sr, sc, er, ec = dst_node:range()
    textlib.replace_range(buf, sr, sc, er, ec, replacement)
end

---@param buf integer
---@param dst_node TSNode
---@param replacement string|string[]
function M.set_before_node(buf, dst_node, replacement)
    local sr, sc = dst_node:start()
    textlib.insert_text(buf, sr, sc, replacement)
end

---@param buf integer
---@param dst_node TSNode
---@param replacement string|string[]
function M.set_after_node(buf, dst_node, replacement)
    local er, ec = dst_node:end_()
    textlib.insert_text(buf, er, ec, replacement)
end

---@param buf integer
---@param edits [TSNode, (string|string[])][]
function M.set_disjoint_node_texts(buf, edits)
    edits = vim.iter(edits)
        :map(function(x)
            local node, text = x[1], x[2]
            local sr, sc, er, ec = node:range()
            return { sr, sc, er, ec, text }
        end)
        :totable()
    textlib.apply_disjoint_edits(buf, edits)
end

---@class bartbie.treesitter.EditLib
---@field after fun(node: TSNode, text: string|string[]): bartbie.treesitter.Edit
---@field before fun(node: TSNode, text: string|string[]): bartbie.treesitter.Edit
---@field replace fun(node: TSNode, text: string|string[]): bartbie.treesitter.Edit
---@field swap fun(node: TSNode, node: TSNode): bartbie.treesitter.Edit
---@field delete fun(node: TSNode): bartbie.treesitter.Edit
M.edit = {
    after = function(node, text)
        local range = M.range_tbl(node)
        range.start_byte = range.end_byte
        range.start_col = range.end_col
        range.start_row = range.end_row
        return { range = range, text = text }
    end,
    before = function(node, text)
        local range = M.range_tbl(node)
        range.end_byte = range.start_byte
        range.end_col = range.start_col
        range.end_row = range.start_row
        return { range = range, text = text }
    end,
    replace = function(node, text)
        local range = M.range_tbl(node)
        return { range = range, text = text }
    end,
    delete = function(node)
        local range = M.range_tbl(node)
        return { range = range, text = {} }
    end,
    swap = function(this, other)
        return {
            range = M.range_tbl(this),
            text = function(bufnr)
                return M.get_node_text_list(bufnr, other)
            end,
        }
    end,
}

---@class bartbie.treesitter.Edit
---@field range bartbie.treesitter.RangeTbl
---@field text string|string[] | fun(bufnr: integer): string|string[]
---
---@alias bartbie.treesitter.Edits bartbie.treesitter.Edit[]

---@param buf integer
---@param edits  bartbie.treesitter.Edits | fun(e: bartbie.treesitter.EditLib): bartbie.treesitter.Edits
function M.apply_disjoint_node_edits(buf, edits)
    local elist = type(edits) == "function" and edits(M.edit) or edits --[[@as bartbie.treesitter.Edits ]]
    local normalized = vim.iter(elist)
        :map(
            ---@param edit bartbie.treesitter.Edit
            ---@return [integer, integer, integer, integer, string|string[]]
            function(edit)
                local r = edit.range
                local text = type(edit.text) == "function" and edit.text(buf) or edit.text
                assert(text)
                return { r.start_row, r.start_col, r.end_row, r.end_col, text }
            end
        )
        :totable()
    textlib.apply_disjoint_edits(buf, normalized)
end

---@param buf integer
---@param node TSNode
---@return string[]
function M.get_node_text_list(buf, node)
    return vim.split(vim.treesitter.get_node_text(node, buf), "\n", { plain = true })
end

---@param buf integer
---@param first_node TSNode
---@param second_node TSNode
---@return string[]
function M.get_text_between_nodes(buf, first_node, second_node)
    local f_end_row, f_end_col = first_node:end_()
    local s_start_row, s_start_col = second_node:start()
    assert(f_end_row <= s_start_row)
    if f_end_row == s_start_row then
        assert(f_end_col <= s_start_col)
    end
    return vim.api.nvim_buf_get_text(buf, f_end_row, f_end_col, s_start_row, s_start_col, {})
end

---@param buf integer
---@param src_node TSNode
---@param dst_node TSNode
function M.replace_node(buf, src_node, dst_node)
    M.set_node_text(buf, dst_node, M.get_node_text_list(buf, src_node))
end

---@param buf integer
---@param node TSNode
function M.delete_node(buf, node)
    local sr, sc, er, ec = node:range()
    textlib.delete_text(buf, sr, sc, er, ec)
end

---@param win integer
---@param node TSNode
function M.move_cursor_to_node(win, node)
    local sr, sc = node:range()
    vim.api.nvim_win_set_cursor(win, { sr + 1, sc })
end

---@param buf integer
---@param node TSNode
---@param fts string[]
---@return boolean
function M.any_ft_registered_for_node(buf, node, fts)
    local ltree = M.get_lang_tree(node, buf)
    local lang = ltree and ltree:lang()
    local registered_fts = lang and vim.treesitter.language.get_filetypes(lang) or {}
    for _, ft in ipairs(registered_fts) do
        if vim.list_contains(fts, ft) then
            return true
        end
    end
    return false
end
local lisp = {}
M.lisp = lisp

local LISP_FTS = {
    "fennel",
    "clojure",
    "scheme",
    "lisp",
    "elisp",
    "commonlisp",
    "racket",
    "janet",
    "hy",
    "carp",
    "shen",
}

---@param buf integer
---@param node TSNode
---@return boolean
function lisp.is_lisp(buf, node)
    return M.any_ft_registered_for_node(buf, node, LISP_FTS)
end

--- Is this node a list (delimited container)?
---@param node TSNode
---@return boolean
function lisp.is_list(node)
    local first = M.first_child(node)
    return (first and first:type():match("[%(%[{]$")) ~= nil
end

--- Is this node a reader macro?
---@param node TSNode
---@return boolean
function lisp.is_reader_macro(node)
    if node:named_child_count() ~= 1 or not lisp.is_list(M.first_named_child(node)) then
        return false
    end
    local first = M.first_child(node)
    return (first and first:type():match("^[`'~#@%^,]")) ~= nil
end

--- Is this node a form (list or a list macro)?
---@param node TSNode
---@return boolean
function lisp.is_form(node)
    return lisp.is_list(node) or lisp.is_reader_macro(node)
end

---@param node TSNode
---@return TSNode?
function lisp.try_node_to_list(node)
    if lisp.is_list(node) then
        return node
    elseif lisp.is_reader_macro(node) then
        for child in M.iter_named_children(node) do
            if lisp.is_list(child) then
                return child
            end
        end
    end
end

---@param form TSNode
---@return TSNode
function lisp.form_to_list(form)
    local list = lisp.try_node_to_list(form)
    if list then
        return list
    else
        error("passed a node to form_to_list that's not a form!")
    end
end

---@param node TSNode
---@return TSNode?, TSNode?
function lisp.get_list_delims(node)
    local list = lisp.try_node_to_list(node)
    if list then
        return M.first_child(list), M.last_child(list)
    end
end

---@param node TSNode
---@return TSNode?
function lisp.get_form_macro(node)
    if not lisp.is_form(node) then
        return
    end
    local form
    if lisp.is_reader_macro(node) then
        form = node
    else
        -- CORRECTNESS: when going up we are at list and need to get our form first
        form = lisp.nearest_form(node)
        if not form then
            return
        end
    end
    local first = M.first_child(form)
    return first and first:type():match("^[`'~#@%^,]") and first or nil
end

---@param node TSNode
---@param which "left"|"right"
---@overload fun(node: TSNode, which: "left"): TSNode?, TSNode? -- with macro symbol
---@overload fun(node: TSNode, which: "right"): TSNode?
function lisp.get_form_delim(node, which)
    if not lisp.is_form(node) then
        return
    end
    local is_left = which == "left"
    local left_delim, right_delim = lisp.get_list_delims(node)
    local delim = (is_left and left_delim) or (not is_left and right_delim)
    if not delim then
        return
    end
    return delim, is_left and lisp.get_form_macro(node) or nil
end

---@param node TSNode
---@return TSNode?, TSNode?, TSNode? -- with macro symbol
function lisp.get_form_delims(node)
    local list = lisp.try_node_to_list(node)
    if not list then
        return
    end
    local l, r = lisp.get_list_delims(list)
    return l, r, lisp.get_form_macro(list)
end

---@param buf integer
---@param node TSNode
function lisp.delete_form_delims(buf, node)
    local ldelim, rdelim, macro = lisp.get_form_delims(node)
    if not ldelim or not rdelim then
        return
    end
    M.apply_disjoint_node_edits(buf, {
        M.edit.delete(ldelim),
        M.edit.delete(rdelim),
        (macro and M.edit.delete(macro)),
    })
end

---@param buf integer
---@param form TSNode
---@param which "left"|"right"
---@param at_node TSNode
function lisp.move_delim(buf, form, which, at_node)
    lisp.move_delim_loose(buf, form, which, which == "left" and "before" or "after", at_node)
end

---@param buf integer
---@param form TSNode
---@param which "left"|"right"
---@param where "before"|"after"
---@param at_node TSNode
function lisp.move_delim_loose(buf, form, which, where, at_node)
    local delim, macro = lisp.get_form_delim(form, which)
    if not delim then
        return
    end
    -- 0 (a 1 b) 2
    -- 0 (a 1 b  2)
    -- 0 (a 1 b )2
    -- 0 (a 1) b 2
    -- 0 (a 1 )b 2
    -- (0 a 1 b) 2
    -- 0( a 1 b) 2
    -- 0 a (1 b) 2
    -- 0 a( 1 b) 2
    local delim_text = vim.treesitter.get_node_text(delim, buf)
    if macro then
        delim_text = (vim.treesitter.get_node_text(macro, buf) or "") .. delim_text
    end
    local e = M.edit
    M.apply_disjoint_node_edits(buf, {
        (where == "after" and e.after(at_node, delim_text) or e.before(at_node, delim_text)),
        e.delete(delim),
        (macro and e.delete(macro)),
    })
end

---@param node TSNode
---@param idx integer
---@return TSNode?
function lisp.form_named_child(node, idx)
    local list = lisp.try_node_to_list(node)
    return list and list:named_child(idx)
end

--- Walk up to nearest form
---@param node TSNode
---@return TSNode?
function lisp.nearest_form(node)
    -- INVARIANT: as a list we treat our enclosing macro node as ourselves
    for n, prev in M.walk_parents(node, { inclusive = true, with_previous = true }) do
        if lisp.is_reader_macro(n) then
            return n
        elseif prev and lisp.is_list(prev) then
            return prev
        end
    end
end

--- Walk up to nearest form that is not this node
---@param node TSNode
---@return TSNode?
function lisp.enclosing_form(node)
    -- INVARIANT: as a list we treat our enclosing macro node as ourselves
    for n, prev in M.walk_parents(node, { with_previous = true }) do
        -- CORRECTNESS: skip first iteration if it's us to avoid returning our enclosing macro
        if prev and prev:id() == node:id() then
            -- skip
        elseif lisp.is_reader_macro(n) then
            return n
        elseif prev and lisp.is_list(prev) then
            return prev
        end
    end
end

--- Get head of s-expr
---@param node TSNode
---@return TSNode?
function lisp.get_head(node)
    node = M.nearest_named(node)
    return lisp.form_named_child(node, 0)
end

--- Get foot of s-expr
---@param node TSNode
---@return TSNode?
function lisp.get_foot(node)
    node = M.nearest_named(node)
    local list = lisp.try_node_to_list(node)
    return list and M.last_named_child(list)
end

---@param node TSNode
function lisp.is_single_symbol(node)
    return node:named_child_count() == 0 and not lisp.is_list(node)
end

--- Check if nodes named children are contiguous to one another
--- if no children returns true
---@param node TSNode
---@return boolean
function M.is_contiguous(node)
    local prev_end_row, prev_end_col
    for child in node:iter_children() do
        if prev_end_row then
            local start_row, start_col = child:start()
            if start_row ~= prev_end_row or start_col ~= prev_end_col then
                return false
            end
        end
        prev_end_row, prev_end_col = child:end_()
    end
    return true
end

--- Check if node is a compound word (e.g. multi-symbol)
---@param node TSNode
---@return boolean
function lisp.is_compound_word(node)
    return not lisp.is_single_symbol(node)
        and not lisp.is_form(node)
        and M.only_leaf_children(node)
        and M.is_contiguous(node)
end

--- Check if node is a word (simple or compound)
---@param node TSNode
---@return boolean
function lisp.is_word(node)
    return lisp.is_single_symbol(node) or lisp.is_compound_word(node)
end

--- Get the full "word" (atom) under cursor.
--- Walks up past compound parts, stops at form boundary.
---@param node TSNode
---@return TSNode?
function lisp.nearest_word(node)
    node = M.nearest_named(node)
    if not node then
        return
    end
    -- e.g. vim.treesitter.get_node is a three identifier children under one multi-symbol node
    local is_single = lisp.is_single_symbol(node)
    local maybe_compound = is_single and node:parent() or node
    if
        maybe_compound
        and not lisp.is_form(maybe_compound)
        and M.only_leaf_children(maybe_compound)
        and M.is_contiguous(maybe_compound)
    then
        return maybe_compound
    elseif is_single then
        return node
    end
end

--- Nearest meaningful expression: word if on an atom, enclosing form otherwise.
---@param node TSNode
---@return TSNode?
function lisp.nearest_expression(node)
    return lisp.nearest_word(node) or lisp.nearest_form(node)
end

---@param node TSNode
---@param opts {with_previous?: boolean}?
---@return fun(): TSNode?, TSNode?
function lisp.iter_form_exprs(node, opts)
    opts = opts or {}
    return coroutine.wrap(function()
        local prev
        local function recur(n)
            for child in M.iter_named_children(n) do
                if lisp.is_word(child) or lisp.is_form(child) then
                    coroutine.yield(child, opts.with_previous and prev or nil)
                    prev = child
                else
                    recur(child)
                end
            end
        end
        local list = lisp.try_node_to_list(node)
        if list then
            recur(list)
        end
    end)
end

---@param node TSNode
---@return TSNode?, TSNode?
function lisp.expr_and_form(node)
    local this_expr = lisp.nearest_expression(node)
    if not this_expr then
        return nil, nil
    end
    local form = lisp.enclosing_form(this_expr)
    return this_expr, form
end

---@param node TSNode
---@return TSNode?
function lisp.next_sibling_expr(node)
    local this_expr, form = lisp.expr_and_form(node)
    if not this_expr or not form then
        return
    end
    for child_expr, prev_ce in lisp.iter_form_exprs(form, { with_previous = true }) do
        if prev_ce and prev_ce:id() == this_expr:id() then
            return child_expr
        end
    end
end

---@param node TSNode
---@return TSNode?
function lisp.prev_sibling_expr(node)
    local this_expr, form = lisp.expr_and_form(node)
    if not this_expr or not form then
        return
    end
    for child_expr, prev_ce in lisp.iter_form_exprs(form, { with_previous = true }) do
        if child_expr:id() == this_expr:id() then
            return prev_ce
        end
    end
end
return M
