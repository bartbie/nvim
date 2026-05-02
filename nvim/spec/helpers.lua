local M = {}
local assert = require("luassert")

local CURSOR_MARKER = "<C>"

---@alias Cursor {[1]: integer, [2]: integer}
---@alias Lines string[]
---@alias OpResult { after: string, cursor: Cursor }
---@alias Predicate fun(node: TSNode): boolean

---@generic T
---@class Rng
---@field int  fun(lo: integer, hi: integer): integer
---@field pick fun(arr: T[]): T
---@field bool fun(): boolean
---@field seed fun(): integer

---@param src string
---@return integer|nil first, integer count
local function scan_marker(src)
    local count, first = 0, nil
    local search = 1
    while true do
        local found = src:find(CURSOR_MARKER, search, true)
        if not found then
            break
        end
        count = count + 1
        first = first or found
        search = found + #CURSOR_MARKER
    end
    return first, count
end

-- Like assert but throws an error in busted instead of failure
---@generic T
---@param check T?
---@param msg string
---@param lvl integer?
---@return T
local function assert_err(check, msg, lvl)
    if not check then
        error(msg, lvl)
    end
    return check
end

--- Run fn inside assert.has_no_error, guarantee cleanup runs, rethrow preserving busted failure/error distinction.
---@param fn function
---@param cleanup function
local function with_cleanup(fn, cleanup)
    local ok, err = pcall(assert.has_no_error, fn)
    cleanup()
    if not ok then
        error(err, 0)
    end
end

-- you're about to see MAGIC.
local _, sample1 = pcall(assert.is_true, false)
local _, sample2 = pcall(assert.is_true, false, "msg")
local fmt1 = getmetatable(sample1)
local fmt2 = getmetatable(sample2)
---@param err any
---@return boolean
local function is_assert_failure(err)
    local mt = getmetatable(err)
    return mt == fmt1 or mt == fmt2
end
---@param err any
---@return "failure" | "error"
local function err_type(err)
    return is_assert_failure(err) and "failure" or "error"
end
-- yeah

-- Returns (lines, cursor={1-indexed row, 0-indexed byte col}). Errors on 0 or >1 markers.
---@param src string
---@return Lines lines, Cursor cursor
function M.parse_cursor(src)
    local idx, count = scan_marker(src)
    assert_err(
        count == 1,
        ("parse_cursor: expected exactly 1 %s marker, got %d in %q"):format(CURSOR_MARKER, count, src)
    )
    assert_err(idx ~= nil, "parse_cursor: scan_marker returned nil index despite count == 1")
    local before = src:sub(1, idx - 1)
    local after = src:sub(idx + #CURSOR_MARKER)
    local clean = before .. after
    local row, col = 1, 0
    for i = 1, #before do
        if before:sub(i, i) == "\n" then
            row = row + 1
            col = 0
        else
            col = col + 1
        end
    end
    local lines = vim.split(clean, "\n", { plain = true })
    return lines, { row, col }
end

-- Returns (clean_text, cursor_or_nil). Cursor is nil if no marker present.
---@param src string
---@return string clean_text, Cursor|nil cursor
function M.maybe_parse_cursor(src)
    local _, count = scan_marker(src)
    if count == 0 then
        return src, nil
    end
    local lines, cursor = M.parse_cursor(src)
    return table.concat(lines, "\n"), cursor
end

---@param lang string  filetype or grammar name
---@param buf integer
---@return vim.treesitter.LanguageTree
function M.buf_parser(lang, buf)
    -- Callers usually pass filetype; resolve to the registered grammar so e.g.
    -- ft "janet" picks up grammar "janet_simple" via language.register.
    local resolved = vim.treesitter.language.get_lang(lang) or lang
    M.assert_grammar(resolved)
    vim.treesitter.start(buf, resolved)
    local parser = vim.treesitter.get_parser(buf, resolved)
    return assert_err(parser, ("missing tree-sitter grammar %q"):format(resolved))
end

---@param lang string
---@param str string
---@return vim.treesitter.LanguageTree
function M.str_parser(lang, str)
    local parser = vim.treesitter.get_string_parser(str, lang)
    return assert_err(parser, ("missing tree-sitter grammar %q"):format(lang))
end

---@param lang string
function M.assert_grammar(lang)
    -- INVARIANT: language.add returns (boolean, string?) on modern nvim;
    -- on failure path either returns false or errors.
    local ok, err = pcall(function()
        local added, add_err = vim.treesitter.language.add(lang)
        assert_err(added, add_err or "language.add returned false", 0)
    end)
    assert_err(ok ~= nil, ("missing tree-sitter grammar %q: %s"):format(lang, tostring(err)))
end

---@param src  string
---@param lang string
---@param fn   fun(root: TSNode, src: string): any
---@return any
function M.with_tree(src, lang, fn)
    local parser = M.str_parser(lang, src)
    local tree = parser:parse()[1]
    return fn(tree:root(), src)
end

-- Parse cursor from `src`, parse tree on the cleaned text, resolve the smallest
-- descendant at the cursor point, and invoke `fn(node, root, clean_src)`.
-- Saves the parse_cursor + with_tree + node_at boilerplate for tree precedence tests.
---@param src  string
---@param lang string
---@param fn   fun(node: TSNode, root: TSNode, clean_src: string): any
---@return any
function M.with_tree_at_cursor(src, lang, fn)
    local lines, cursor = M.parse_cursor(src)
    local clean = table.concat(lines, "\n")
    return M.with_tree(clean, lang, function(root)
        -- cursor is {1-indexed row, 0-indexed byte col}; descendant_for_range wants 0-indexed.
        local node = root:descendant_for_range(cursor[1] - 1, cursor[2], cursor[1] - 1, cursor[2])
        assert(node ~= nil, ("with_tree_at_cursor: no node at cursor {%d, %d}"):format(cursor[1], cursor[2]))
        return fn(node, root, clean)
    end)
end

---@param root TSNode
---@param pred Predicate
---@return TSNode|nil
function M.find_first(root, pred)
    if pred(root) then
        return root
    end
    for child in root:iter_children() do
        local found = M.find_first(child, pred)
        if found then
            return found
        end
    end
end

---@param root TSNode
---@param pred Predicate
---@return TSNode[]
function M.find_all(root, pred)
    local out = {}
    local function recur(node)
        if pred(node) then
            out[#out + 1] = node
        end
        for child in node:iter_children() do
            recur(child)
        end
    end
    recur(root)
    return out
end

-- Smallest node whose range fully contains the (row, col) point.
---@param root TSNode
---@param row  integer  0-indexed
---@param col  integer  0-indexed byte offset
---@return TSNode|nil
function M.node_at(root, row, col)
    return root:descendant_for_range(row, col, row, col)
end

---@param lines Lines
---@param ft    string
---@param fn    fun(buf: integer, root: TSNode, parser: vim.treesitter.LanguageTree): any
function M.with_buf(lines, ft, fn)
    local prev_parinfer = vim.g.parinfer_enabled
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value("filetype", ft, { buf = buf })
    local parser = M.buf_parser(ft, buf)
    local tree = parser:parse()[1]
    with_cleanup(function()
        fn(buf, tree:root(), parser)
    end, function()
        if vim.api.nvim_buf_is_valid(buf) then
            vim.api.nvim_buf_delete(buf, { force = true })
        end
        vim.g.parinfer_enabled = prev_parinfer
    end)
end

---@param buf integer
---@return integer win
local function open_test_win(buf)
    return vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        row = 0,
        col = 0,
        width = math.max(40, vim.o.columns - 4),
        height = math.max(10, vim.o.lines - 4),
        style = "minimal",
    })
end

---@param buf integer
---@param ft  string
local function assert_no_parse_errors(buf, ft)
    local parser = M.buf_parser(ft, buf)
    local tree = parser:parse(true)[1]
    if tree:root():has_error() then
        local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        error("post-op tree has parse errors; buffer:\n" .. table.concat(lines, "\n"), 0)
    end
end

---@class RunOpOpts
---@field allow_parse_errors? boolean

-- Runs op_fn inside a floating window over a scratch buf seeded from `before_str`.
-- Returns { after = text, cursor = {row, col} }.
-- By default asserts the post-edit tree parses error-free (opts.allow_parse_errors disables).
---@param before_str string
---@param ft         string
---@param op_fn      fun(): any
---@param opts?      RunOpOpts
---@return OpResult
function M.run_op(before_str, ft, op_fn, opts)
    opts = opts or {}
    local lines, cursor = M.parse_cursor(before_str)
    local prev_parinfer = vim.g.parinfer_enabled
    local prev_win = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value("filetype", ft, { buf = buf })
    vim.api.nvim_set_option_value("buftype", "", { buf = buf })
    -- Force parser attachment before opening the window (so get_node has a tree).
    local parser = M.buf_parser(ft, buf)
    parser:parse()
    local win = open_test_win(buf)
    vim.api.nvim_win_set_cursor(win, cursor)

    local op_ok, op_err = pcall(op_fn)
    ---@type OpResult|nil
    local result
    local parse_ok, parse_err = true, nil
    if op_ok then
        local after_lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local after_cursor = vim.api.nvim_win_get_cursor(win)
        result = { after = table.concat(after_lines, "\n"), cursor = after_cursor }
        if not opts.allow_parse_errors then
            parse_ok, parse_err = pcall(assert_no_parse_errors, buf, ft)
        end
    end

    if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
        vim.api.nvim_buf_delete(buf, { force = true })
    end
    vim.g.parinfer_enabled = prev_parinfer
    if vim.api.nvim_win_is_valid(prev_win) then
        vim.api.nvim_set_current_win(prev_win)
    end

    if not op_ok then
        error(op_err, 0)
    end
    if not parse_ok then
        error(parse_err, 0)
    end
    assert(result ~= nil, "run_op: result is nil after successful op (this should never happen)")
    return result
end

-- Run op, assert text. Cursor checked only if `after_str` contains a marker.
---@param before_str string
---@param after_str  string
---@param op_fn      fun(): any
---@param ft         string
---@param opts?      RunOpOpts
function M.golden(before_str, after_str, op_fn, ft, opts)
    local expected_text, expected_cursor = M.maybe_parse_cursor(after_str)
    local actual = M.run_op(before_str, ft, op_fn, opts)
    assert.is.same(expected_text, actual.after)
    if expected_cursor then
        assert(
            (actual.cursor[1] == expected_cursor[1]) and (actual.cursor[2] == expected_cursor[2]),
            ("cursor mismatch:\n  expected: {%d, %d}\n  actual:   {%d, %d}"):format(
                expected_cursor[1],
                expected_cursor[2],
                actual.cursor[1],
                actual.cursor[2]
            ),
            0
        )
    end
end

---@class EachFtOpts
---@field skip_if? fun(ft: string, case: any): boolean

-- Parameterize a block of tests across filetypes.
-- opts.skip_if(ft, case) -> boolean: skip a given case for a given ft.
---@param fts  string[]
---@param fn   fun(ft: string, opts: EachFtOpts): any
---@param opts? EachFtOpts
function M.each_ft(fts, fn, opts)
    opts = opts or {}
    for _, ft in ipairs(fts) do
        describe(("[%s]"):format(ft), function()
            fn(ft, opts)
        end)
    end
end

-- 32-bit LCG. Deterministic, seedable via TEST_SEED env var.
local DEFAULT_SEED = 0xC0FFEE

---@param seed? integer
---@return Rng
function M.rng(seed)
    seed = seed or tonumber(os.getenv("TEST_SEED")) or DEFAULT_SEED
    local state = seed
    local function next_u32()
        state = (state * 1103515245 + 12345) % 0x80000000
        return state
    end
    return {
        int = function(lo, hi)
            assert(lo <= hi)
            return lo + (next_u32() % (hi - lo + 1))
        end,
        pick = function(arr)
            assert(#arr > 0)
            return arr[1 + (next_u32() % #arr)]
        end,
        bool = function()
            return next_u32() % 2 == 0
        end,
        seed = function()
            return seed
        end,
    }
end

return M
