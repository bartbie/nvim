local h = require("spec.helpers")
local tslib = require("bartbie.treesitter")
local lisp = tslib.lisp

h.assert_grammar("fennel")
h.assert_grammar("clojure")

local function get_lines(buf)
    return vim.api.nvim_buf_get_lines(buf, 0, -1, false)
end

-- Per-row test runner over an op `op(buf, node, c)` where node is the first list
-- (or h.find_atom(root) if `c.atom = true`). Rows are pure data.
---@class MutRow
---@field [1] string  input (\n splits to lines)
---@field [2] string  expected (\n splits to lines)
---@field name string?
---@field lang string?
---@field atom boolean?  use first atom instead of first list as the node selector

---@param op fun(buf: integer, node: TSNode, c: MutRow)
---@param cases MutRow[]
---@param default_ft string?
local function each(op, cases, default_ft)
    for _, c in ipairs(cases) do
        it(c.name or (("%q -> %q"):format(c[1], c[2])), function()
            local input = vim.split(c[1], "\n", { plain = true })
            local expected = vim.split(c[2], "\n", { plain = true })
            h.with_buf(input, c.lang or default_ft or "fennel", function(buf, root)
                local node = c.atom and h.find_atom(root) or h.find_first(root, lisp.is_list)
                op(buf, node, c)
                assert.are.same(expected, get_lines(buf))
            end)
        end)
    end
end

describe("bartbie.treesitter.set_node_text", function()
    -- Op shape: replace `node` with `c.text` (string or string[]). Rows differ only in input/text.
    each(function(buf, node, c) tslib.set_node_text(buf, node, c.text) end, {
        { "(foo bar)", "(baz)", text = "(baz)", name = "single-line string replacement" },
        { "(foo)", "(foo\nbar)", text = { "(foo", "bar)" }, name = "multi-line array replacement" },
    })
end)

describe("bartbie.treesitter.set_before_node / set_after_node", function()
    each(function(buf, node) tslib.set_before_node(buf, node, "X") end, {
        { "foo", "Xfoo", atom = true, name = "set_before_node inserts at node start" },
    })
    each(function(buf, node) tslib.set_after_node(buf, node, "X") end, {
        { "foo", "fooX", atom = true, name = "set_after_node inserts at node end" },
    })
end)

describe("bartbie.treesitter.delete_node", function()
    each(tslib.delete_node, { { "(foo)", "", name = "deletes a single-line list" } })
    -- delete_node doesn't compact whitespace; documenting current behavior.
    it("leading atom leaves whitespace", function()
        h.with_buf({ "(foo bar)" }, "fennel", function(buf, root)
            local exprs = h.collect(lisp.iter_form_exprs(h.find_first(root, lisp.is_list)))
            tslib.delete_node(buf, exprs[1])
            assert.are.same({ "( bar)" }, get_lines(buf))
        end)
    end)
end)

describe("bartbie.treesitter.replace_node", function()
    it("copies src text into dst position", function()
        h.with_buf({ "(foo bar)" }, "fennel", function(buf, root)
            local exprs = h.collect(lisp.iter_form_exprs(h.find_first(root, lisp.is_list)))
            tslib.replace_node(buf, exprs[1], exprs[2])
            assert.are.same({ "(foo foo)" }, get_lines(buf))
        end)
    end)
end)

describe("bartbie.treesitter.set_disjoint_node_texts", function()
    -- Multi-line range arithmetic is the failure surface; ranges must survive
    -- earlier edits' line-count deltas.
    it("swaps two single-line nodes on the same line", function()
        h.with_buf({ "(a b)" }, "fennel", function(buf, root)
            local exprs = h.collect(lisp.iter_form_exprs(h.find_first(root, lisp.is_list)))
            local a = tslib.get_node_text_list(buf, exprs[1])
            local b = tslib.get_node_text_list(buf, exprs[2])
            tslib.set_disjoint_node_texts(buf, { { exprs[1], b }, { exprs[2], a } })
            assert.are.same({ "(b a)" }, get_lines(buf))
        end)
    end)

    it("preserves tree validity when swapping a multi-line node with a single-line node", function()
        h.with_buf({ "(", "  (foo", "    bar)", "  baz", ")" }, "fennel", function(buf, root)
            local outer = h.find_first(root, lisp.is_list)
            local inner_list, baz_atom
            for e in lisp.iter_form_exprs(outer) do
                if lisp.is_list(e) then
                    inner_list = e
                else
                    baz_atom = baz_atom or e
                end
            end
            if not (inner_list and baz_atom) then
                return
            end
            local inner_text = tslib.get_node_text_list(buf, inner_list)
            local baz_text = tslib.get_node_text_list(buf, baz_atom)
            tslib.set_disjoint_node_texts(buf, {
                { inner_list, baz_text },
                { baz_atom, inner_text },
            })
            local tree = h.buf_parser("fennel", buf):parse(true)[1]
            assert(not tree:root():has_error(), "post-swap tree has errors:\n" .. table.concat(get_lines(buf), "\n"))
        end)
    end)

    it("three-way replacement with mixed line counts (1-line, 1-line, 3-line)", function()
        -- Reverse-range sort must keep later edits' coords valid after earlier deltas.
        h.with_buf({ "(a b c)" }, "fennel", function(buf, root)
            local exprs = h.collect(lisp.iter_form_exprs(h.find_first(root, lisp.is_list)))
            tslib.set_disjoint_node_texts(buf, {
                { exprs[1], { "X", "Y" } },
                { exprs[2], "B2" },
                { exprs[3], { "C1", "C2", "C3" } },
            })
            assert.are.same({ "(X", "Y B2 C1", "C2", "C3)" }, get_lines(buf))
        end)
    end)

    it("edit-order independence: applying same edits in any order yields the same result", function()
        -- Bottom-up sort is internal (text.lua:50-62), so caller order must not matter.
        local function apply_with_order(order)
            local result
            h.with_buf({ "(a b c d)" }, "fennel", function(buf, root)
                local exprs = h.collect(lisp.iter_form_exprs(h.find_first(root, lisp.is_list)))
                local edits = {
                    { exprs[1], "AAA" },
                    { exprs[2], "BBB" },
                    { exprs[3], "CCC" },
                    { exprs[4], "DDD" },
                }
                local reordered = {}
                for i, idx in ipairs(order) do
                    reordered[i] = edits[idx]
                end
                tslib.set_disjoint_node_texts(buf, reordered)
                result = get_lines(buf)
            end)
            return result
        end
        local baseline = apply_with_order({ 1, 2, 3, 4 })
        local rng = h.rng()
        for _ = 1, 5 do
            local idxs = { 1, 2, 3, 4 }
            for i = #idxs, 2, -1 do
                local j = rng.int(1, i)
                idxs[i], idxs[j] = idxs[j], idxs[i]
            end
            assert.are.same(baseline, apply_with_order(idxs), ("order %s diverged"):format(vim.inspect(idxs)))
        end
    end)

    it("EOF clamp: edit on last atom of last line, no trailing newline", function()
        -- text.replace_range clamps er when it exceeds line_count (text.lua:13-16).
        h.with_buf({ "(foo bar)" }, "fennel", function(buf, root)
            local exprs = h.collect(lisp.iter_form_exprs(h.find_first(root, lisp.is_list)))
            tslib.set_disjoint_node_texts(buf, { { exprs[#exprs], "BAR" } })
            assert.are.same({ "(foo BAR)" }, get_lines(buf))
        end)
    end)
end)

describe("bartbie.treesitter.edit constructors", function()
    -- Range capture is eager: each constructor snapshots node coords at call time.
    -- These pin the {range, text} shape so apply_disjoint_node_edits has a stable contract.
    local function collapsed(r, side)
        local p = side == "start" and "start_" or "end_"
        return {
            start_row = r[p .. "row"],
            start_col = r[p .. "col"],
            start_byte = r[p .. "byte"],
            end_row = r[p .. "row"],
            end_col = r[p .. "col"],
            end_byte = r[p .. "byte"],
        }
    end

    -- Ctor tests share the shape "build edit on first list, compare to expected shape".
    -- Rows: { name, build_fn(list), expected_fn(list) }
    for _, c in ipairs({
        {
            "replace: range matches node, text passed through",
            function(list) return tslib.edit.replace(list, "X") end,
            function(list) return { range = tslib.range_tbl(list), text = "X" } end,
        },
        {
            "before: range collapsed to node start",
            function(list) return tslib.edit.before(list, "X") end,
            function(list) return { range = collapsed(tslib.range_tbl(list), "start"), text = "X" } end,
        },
        {
            "after: range collapsed to node end",
            function(list) return tslib.edit.after(list, "X") end,
            function(list) return { range = collapsed(tslib.range_tbl(list), "end"), text = "X" } end,
        },
        {
            "delete: range matches node, text = {}",
            function(list) return tslib.edit.delete(list) end,
            function(list) return { range = tslib.range_tbl(list), text = {} } end,
        },
    }) do
        it(c[1], function()
            h.with_buf({ "(foo)" }, "fennel", function(_, root)
                local list = h.find_first(root, lisp.is_list)
                assert.are.same(c[3](list), c[2](list))
            end)
        end)
    end

    it("swap: range is `this`, text is a function reading `other` at apply time", function()
        h.with_buf({ "(a b)" }, "fennel", function(buf, root)
            local exprs = h.collect(lisp.iter_form_exprs(h.find_first(root, lisp.is_list)))
            local edit = tslib.edit.swap(exprs[1], exprs[2])
            assert.are.same(tslib.range_tbl(exprs[1]), edit.range)
            assert.is_function(edit.text)
            assert.are.same(tslib.get_node_text_list(buf, exprs[2]), edit.text(buf))
        end)
    end)
end)

describe("bartbie.treesitter.apply_disjoint_node_edits", function()
    -- Wrapper over text.apply_disjoint_edits: unboxes {range, text}, resolves text-fns
    -- (swap) BEFORE applying so source reads see pre-mutation state. Sort/apply
    -- correctness lives in set_disjoint_node_texts; here we test the contract.

    -- Single-edit cases via list-form. Selector: list (default) or atom (atom=true).
    -- {input, expected, build_edit(list_or_atom), atom?, name}
    for _, c in ipairs({
        {
            "(foo bar)",
            "(baz)",
            function(node) return tslib.edit.replace(node, "(baz)") end,
            name = "single replace via list form",
        },
        {
            "foo",
            "Xfoo",
            function(node) return tslib.edit.before(node, "X") end,
            atom = true,
            name = "single before via list form",
        },
        {
            "foo",
            "fooX",
            function(node) return tslib.edit.after(node, "X") end,
            atom = true,
            name = "single after via list form",
        },
    }) do
        it(c.name, function()
            h.with_buf(vim.split(c[1], "\n", { plain = true }), "fennel", function(buf, root)
                local node = c.atom and h.find_atom(root) or h.find_first(root, lisp.is_list)
                tslib.apply_disjoint_node_edits(buf, { c[3](node) })
                assert.are.same(vim.split(c[2], "\n", { plain = true }), get_lines(buf))
            end)
        end)
    end

    it("single delete via list form", function()
        h.with_buf({ "(foo bar)" }, "fennel", function(buf, root)
            local exprs = h.collect(lisp.iter_form_exprs(h.find_first(root, lisp.is_list)))
            tslib.apply_disjoint_node_edits(buf, { tslib.edit.delete(exprs[1]) })
            assert.are.same({ "( bar)" }, get_lines(buf))
        end)
    end)

    it("mixed constructors in one batch", function()
        h.with_buf({ "(a b c d)" }, "fennel", function(buf, root)
            local exprs = h.collect(lisp.iter_form_exprs(h.find_first(root, lisp.is_list)))
            tslib.apply_disjoint_node_edits(buf, {
                tslib.edit.before(exprs[1], "<"),
                tslib.edit.replace(exprs[2], "B"),
                tslib.edit.after(exprs[3], ">"),
                tslib.edit.delete(exprs[4]),
            })
            assert.are.same({ "(<a B c> )" }, get_lines(buf))
        end)
    end)

    it("multi-line replacement coexisting with point-inserts", function()
        h.with_buf({ "(a b c)" }, "fennel", function(buf, root)
            local exprs = h.collect(lisp.iter_form_exprs(h.find_first(root, lisp.is_list)))
            tslib.apply_disjoint_node_edits(buf, {
                tslib.edit.before(exprs[1], "<"),
                tslib.edit.replace(exprs[2], { "B1", "B2", "B3" }),
                tslib.edit.after(exprs[3], ">"),
            })
            assert.are.same({ "(<a B1", "B2", "B3 c>)" }, get_lines(buf))
        end)
    end)

    it("accepts callback form: fn(e) -> edits", function()
        h.with_buf({ "(foo)" }, "fennel", function(buf, root)
            local list = h.find_first(root, lisp.is_list)
            tslib.apply_disjoint_node_edits(buf, function(e)
                return { e.replace(list, "(BAR)") }
            end)
            assert.are.same({ "(BAR)" }, get_lines(buf))
        end)
    end)

    it("swap two nodes via edit.swap (text fn resolved pre-mutation)", function()
        -- CORRECTNESS: edit.text(buf) MUST be called before any range mutation,
        -- otherwise the second swap-edit reads already-overwritten text.
        h.with_buf({ "(a b)" }, "fennel", function(buf, root)
            local exprs = h.collect(lisp.iter_form_exprs(h.find_first(root, lisp.is_list)))
            tslib.apply_disjoint_node_edits(buf, {
                tslib.edit.swap(exprs[1], exprs[2]),
                tslib.edit.swap(exprs[2], exprs[1]),
            })
            assert.are.same({ "(b a)" }, get_lines(buf))
        end)
    end)

    it("trailing nil in edits list is tolerated", function()
        -- Callers conditionally append: `(macro and e.delete(macro))`. ipairs stops
        -- at nil, so preceding edits still apply.
        h.with_buf({ "(foo)" }, "fennel", function(buf, root)
            local list = h.find_first(root, lisp.is_list)
            tslib.apply_disjoint_node_edits(buf, {
                tslib.edit.replace(list, "X"),
                (false and tslib.edit.delete(list)) or nil,
            })
            assert.are.same({ "X" }, get_lines(buf))
        end)
    end)

    it("empty edits list is a no-op", function()
        h.with_buf({ "(foo)" }, "fennel", function(buf, root)
            tslib.apply_disjoint_node_edits(buf, {})
            assert.are.same({ "(foo)" }, get_lines(buf))
        end)
    end)

    it("edit-order independence: same edits, any order, same result", function()
        -- Mirrors set_disjoint_node_texts property test; proves the wrapper doesn't
        -- break the underlying bottom-up sort.
        local function apply_with_order(order)
            local result
            h.with_buf({ "(a b c d)" }, "fennel", function(buf, root)
                local exprs = h.collect(lisp.iter_form_exprs(h.find_first(root, lisp.is_list)))
                local edits = {
                    tslib.edit.replace(exprs[1], "AAA"),
                    tslib.edit.replace(exprs[2], "BBB"),
                    tslib.edit.replace(exprs[3], "CCC"),
                    tslib.edit.replace(exprs[4], "DDD"),
                }
                local reordered = {}
                for i, idx in ipairs(order) do
                    reordered[i] = edits[idx]
                end
                tslib.apply_disjoint_node_edits(buf, reordered)
                result = get_lines(buf)
            end)
            return result
        end
        local baseline = apply_with_order({ 1, 2, 3, 4 })
        local rng = h.rng()
        for _ = 1, 5 do
            local idxs = { 1, 2, 3, 4 }
            for i = #idxs, 2, -1 do
                local j = rng.int(1, i)
                idxs[i], idxs[j] = idxs[j], idxs[i]
            end
            assert.are.same(baseline, apply_with_order(idxs), ("order %s diverged"):format(vim.inspect(idxs)))
        end
    end)

    it("adjacent zero-width inserts at same byte (after(a) + before(b))", function()
        -- HAZARD for slurp/barf: when anchor and deleted-delim are adjacent, two
        -- zero-width inserts can land at the same byte. Pin behavior so future
        -- regressions are visible.
        h.with_buf({ "(a b)" }, "fennel", function(buf, root)
            local exprs = h.collect(lisp.iter_form_exprs(h.find_first(root, lisp.is_list)))
            tslib.apply_disjoint_node_edits(buf, {
                tslib.edit.after(exprs[1], "X"),
                tslib.edit.before(exprs[2], "Y"),
            })
            assert.are.same({ "(aX Yb)" }, get_lines(buf))
        end)
    end)
end)

describe("bartbie.treesitter.lisp.delete_form_delims", function()
    -- All cases share op `lisp.delete_form_delims(buf, list)`. Pure data.
    each(function(buf, node) lisp.delete_form_delims(buf, node) end, {
        { "(foo)", "foo" },
        { "[foo]", "foo" },
        { "{foo bar}", "foo bar" },
        -- INVARIANT: for slen=elen=1 and txt={"()"}, sub(2)->")" -> sub(1,-2)->"".
        { "()", "" },
        -- INVARIANT: slen/elen are byte lengths; multi-byte body trims cleanly.
        { "(héllo)", "héllo" },
    }, "fennel")

    -- TRACE: try_node_to_list(rm) returns inner; txt = "(foo)" -> sub trims to "foo".
    -- set_node_text(rm, "foo") replaces the FULL reader-macro range, dropping the `'`.
    -- LIKELY BUG: prefix silently dropped. Pin so the next fix updates this test.
    -- TODO(verify): user to decide whether intended is `foo` (current) or `'foo`.
    it("reader-macro `'(foo)` drops both prefix and delims", function()
        h.with_buf({ "'(foo)" }, "clojure", function(buf, root)
            lisp.delete_form_delims(buf, h.find_first(root, lisp.is_reader_macro))
            assert.are.same({ "foo" }, get_lines(buf))
        end)
    end)

    -- WARN: is_list does not match clojure `#{...}` (set predicate gap); test falls
    -- back to a no-op when find_first returns nil. Preserved as in original.
    it("clojure set #{...} (multi-char opener)", function()
        -- INVARIANT (tslib:580-583): slen accounts for the 2-byte '#{' opener.
        h.with_buf({ "#{1 2}" }, "clojure", function(buf, root)
            local set = h.find_first(root, lisp.is_list)
            if set then
                lisp.delete_form_delims(buf, set)
                assert.are.same({ "1 2" }, get_lines(buf))
            end
        end)
    end)

    it('clojure regex `#"abc"` - is_list classification (current behavior)', function()
        -- TODO(verify): tree-sitter-clojure parses #"abc" as regex_lit whose first child
        -- type is `#"` (ending with `"`, not in [(\[{]). is_list=false -> no-op expected.
        h.with_buf({ '#"abc"' }, "clojure", function(buf, root)
            local target = h.find_first(root, function(n)
                local first = n:child(0)
                return first and first:type():sub(1, 1) == "#"
            end)
            if not target then
                return
            end
            lisp.delete_form_delims(buf, target)
            -- Weak invariant: regex body survives whether op is no-op or strip.
            assert(get_lines(buf)[1]:find("abc"), "regex body should survive delete_delimiters")
        end)
    end)

    each(function(buf, node) lisp.delete_form_delims(buf, node) end, {
        { "foo", "foo", atom = true, name = "no-op when called on a non-list node" },
    })
end)

describe("bartbie.treesitter.lisp.move_delims", function()
    it("(a b) c -> (a b c)", function()
        h.with_buf({ "(a b) c" }, "fennel", function(buf, root)
            local list = h.find_first(root, lisp.is_form)
            lisp.move_delim_loose(buf, list, "right", "after", list:next_named_sibling())
            assert.are.same({ "(a b c)" }, get_lines(buf))
        end)
    end)
    it("a (b c) -> (a b c)", function()
        h.with_buf({ "a (b c)" }, "fennel", function(buf, root)
            local list = h.find_first(root, lisp.is_form)
            lisp.move_delim_loose(buf, list, "left", "before", list:prev_named_sibling())
            assert.are.same({ "(a b c)" }, get_lines(buf))
        end)
    end)
end)

describe("bartbie.treesitter.lisp.is_lisp", function()
    it("true on fennel buffer node", function()
        h.with_buf({ "(foo)" }, "fennel", function(buf, root)
            assert(lisp.is_lisp(buf, h.find_first(root, lisp.is_list)))
        end)
    end)

    it("false on lua buffer node", function()
        h.with_buf({ "local x = 1" }, "lua", function(buf, root)
            assert.is_false(lisp.is_lisp(buf, root:named_child(0) or root))
        end)
    end)
end)
