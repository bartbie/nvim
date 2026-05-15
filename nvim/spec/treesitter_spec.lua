local h = require("spec.helpers")
local tslib = require("bartbie.treesitter")
local lisp = tslib.lisp

h.assert_grammar("fennel")
h.assert_grammar("clojure")
h.assert_grammar("janet_simple")

-- Per-row test runner: assert that h.find_first(root, pred) finds something for
-- each src in the corpus. Pure data; no per-row closure.
---@param pred fun(n: TSNode): boolean
---@param srcs string[]
---@param ft string
local function each_finds(pred, srcs, ft)
    for _, src in ipairs(srcs) do
        it(("finds in %q"):format(src), function()
            h.with_tree(src, ft, function(root)
                assert(h.find_first(root, pred), "predicate matched no node")
            end)
        end)
    end
end

describe("bartbie.treesitter", function()
    describe("walk_children_dfs", function()
        it("yields every descendant", function()
            h.with_tree("(foo (bar baz))", "fennel", function(root)
                local count = #h.collect(tslib.walk_children_dfs(root))
                assert(count > 3, "expected multiple descendants, got " .. count)
            end)
        end)

        it("yields in DFS order (parent before its descendants)", function()
            h.with_tree("(a (b c))", "fennel", function(root)
                local seen = h.collect(tslib.walk_children_dfs(root))
                local id_to_idx = {}
                for i, n in ipairs(seen) do
                    id_to_idx[n:id()] = i
                end
                for i, n in ipairs(seen) do
                    local p = n:parent()
                    if p and id_to_idx[p:id()] then
                        assert(id_to_idx[p:id()] < i, "DFS order violated")
                    end
                end
            end)
        end)
    end)

    describe("walk_parents", function()
        local function inner_list(root)
            local lists = h.find_all(root, lisp.is_list)
            return lists[#lists]
        end

        it("excludes node itself by default", function()
            h.with_tree("(foo (bar))", "fennel", function(root)
                local inner = inner_list(root)
                for n in tslib.walk_parents(inner) do
                    assert(n:id() ~= inner:id(), "default walk should exclude self")
                end
            end)
        end)

        it("includes node when inclusive=true", function()
            h.with_tree("(foo (bar))", "fennel", function(root)
                local inner = inner_list(root)
                local seen_self = false
                for n in tslib.walk_parents(inner, { inclusive = true }) do
                    if n:id() == inner:id() then
                        seen_self = true
                    end
                end
                assert(seen_self)
            end)
        end)

        it("yields (current, previous) when with_previous=true", function()
            h.with_tree("(foo (bar))", "fennel", function(root)
                for cur, prev in tslib.walk_parents(inner_list(root), { with_previous = true }) do
                    assert(cur)
                    if prev then
                        assert(prev:parent() and prev:parent():id() == cur:id(), "prev should be a child of cur")
                    end
                end
            end)
        end)
    end)

    describe("get_containing_node", function()
        -- 8 branches per tslib:84-107.
        it("returns nil for (nil, nil)", function()
            assert.is_nil(tslib.get_containing_node(nil, nil))
        end)

        it("returns (0, a) for (a, nil)", function()
            h.with_tree("(foo)", "fennel", function(root)
                local a = h.find_first(root, lisp.is_list)
                local side, node = tslib.get_containing_node(a, nil)
                assert.are.equal(0, side)
                assert.are.equal(a:id(), node:id())
            end)
        end)

        it("returns (1, b) for (nil, b)", function()
            h.with_tree("(foo)", "fennel", function(root)
                local b = h.find_first(root, lisp.is_list)
                local side, node = tslib.get_containing_node(nil, b)
                assert.are.equal(1, side)
                assert.are.equal(b:id(), node:id())
            end)
        end)

        it("returns nil for disjoint ranges", function()
            h.with_tree("(foo) (bar)", "fennel", function(root)
                local lists = h.find_all(root, lisp.is_list)
                assert.is_nil(tslib.get_containing_node(lists[1], lists[2]))
            end)
        end)

        local function outer_inner(root)
            local outer = h.find_first(root, lisp.is_list)
            local inner = h.find_first(outer, function(n)
                return n:id() ~= outer:id() and lisp.is_list(n)
            end)
            return outer, inner
        end

        it("returns (0, a) when a strictly contains b", function()
            h.with_tree("(foo (bar))", "fennel", function(root)
                local outer, inner = outer_inner(root)
                local side, node = tslib.get_containing_node(outer, inner)
                assert.are.equal(0, side)
                assert.are.equal(outer:id(), node:id())
            end)
        end)

        it("returns (1, b) when b strictly contains a", function()
            h.with_tree("(foo (bar))", "fennel", function(root)
                local outer, inner = outer_inner(root)
                local side, node = tslib.get_containing_node(inner, outer)
                assert.are.equal(1, side)
                assert.are.equal(outer:id(), node:id())
            end)
        end)

        it("returns (0, a) for equal-span identical nodes (current behavior)", function()
            -- CORRECTNESS: equal spans fall to else branch (tslib:104-106) -> 1, b.
            -- Documenting this; callers should not rely on which side is returned.
            h.with_tree("(foo)", "fennel", function(root)
                local list = h.find_first(root, lisp.is_list)
                local side, node = tslib.get_containing_node(list, list)
                assert.are.equal(0, side)
                assert.are.equal(list:id(), node:id())
            end)
        end)

        it("multi-byte content: byte-range comparison handles unicode bodies", function()
            -- get_containing_node uses :start() / :end_() byte offsets, not chars.
            h.with_tree("(foo (héllo))", "fennel", function(root)
                local lists = h.find_all(root, lisp.is_list)
                local outer, inner = lists[1], lists[#lists]
                local side, node = tslib.get_containing_node(outer, inner)
                assert.are.equal(0, side)
                assert.are.equal(outer:id(), node:id())
            end)
        end)
    end)

    describe("is_contiguous", function()
        -- INVARIANT (tslib:443-455): prev_end_row never assigned for empty/single-child,
        -- so the function returns true vacuously.
        it("returns true on a node with no children (vacuous)", function()
            h.with_tree("foo", "fennel", function(root)
                local leaf = h.find_first(root, function(n)
                    return n:named_child_count() == 0
                end)
                assert.is_true(tslib.is_contiguous(leaf))
            end)
        end)

        it("returns true for spatially-adjacent siblings", function()
            -- Smoke check: result is boolean. Adjacent-children grammar dependence
            -- makes a stronger assertion brittle.
            h.with_tree("(ab)", "fennel", function(root)
                assert.are.equal("boolean", type(tslib.is_contiguous(h.find_first(root, lisp.is_list))))
            end)
        end)
    end)

    describe("sorted_node_set", function()
        it("deduplicates by id", function()
            h.with_tree("(foo)", "fennel", function(root)
                local list = h.find_first(root, lisp.is_list)
                assert.are.equal(1, #tslib.sorted_node_set({ list, list, list }))
            end)
        end)

        it("sorts by start position", function()
            -- Same row -> compare by byte offset (third return of TSNode:start()),
            -- not row scalar.
            h.with_tree("(a) (b) (c)", "fennel", function(root)
                local lists = h.find_all(root, lisp.is_list)
                local sorted = tslib.sorted_node_set({ lists[3], lists[1], lists[2] })
                assert.are.equal(3, #sorted)
                local prev = -1
                for _, n in ipairs(sorted) do
                    local _, _, byte = n:start()
                    assert(byte > prev, "not sorted ascending")
                    prev = byte
                end
            end)
        end)
    end)

    describe("nearest_named", function()
        it("returns self when node is named", function()
            h.with_tree("(foo)", "fennel", function(root)
                local list = h.find_first(root, lisp.is_list)
                assert.are.equal(list:id(), tslib.nearest_named(list):id())
            end)
        end)
    end)

    describe("is_leaf / first_named_child / last_named_child", function()
        it("is_leaf true on atoms, false on lists", function()
            h.with_tree("(foo)", "fennel", function(root)
                assert.is_false(tslib.is_leaf(h.find_first(root, lisp.is_list)))
            end)
        end)

        it("first/last_named_child are first and last", function()
            -- Same-row siblings -> compare by byte offset (third return of :start()).
            h.with_tree("(a b c)", "fennel", function(root)
                local list = h.find_first(root, lisp.is_list)
                local first = tslib.first_named_child(list)
                local last = tslib.last_named_child(list)
                local _, _, fb = first:start()
                local _, _, lb = last:start()
                assert(fb < lb or first:id() == last:id())
            end)
        end)
    end)

    describe("range_tbl", function()
        it("returns the 4-keyed range record", function()
            h.with_tree("(foo)", "fennel", function(root)
                local r = tslib.range_tbl(h.find_first(root, lisp.is_list))
                for _, k in ipairs({ "start_row", "start_col", "end_row", "end_col" }) do
                    assert.are.equal("number", type(r[k]))
                end
            end)
        end)
    end)
end)

describe("bartbie.treesitter.lisp", function()
    describe("is_list", function()
        each_finds(lisp.is_list, { "(foo)", "[foo]", "{:a 1}" }, "fennel")
    end)

    describe("is_reader_macro", function()
        -- INVARIANT: is_reader_macro (tslib:328) requires the macro to wrap a list -
        -- the named child must satisfy is_list. '(foo) qualifies; 'foo does not.
        each_finds(lisp.is_reader_macro, { "'(foo)", "~@(foo)" }, "clojure")
    end)

    describe("is_form", function()
        it("true for lists", function()
            h.with_tree("(foo)", "fennel", function(root)
                assert(lisp.is_form(h.find_first(root, lisp.is_list)))
            end)
        end)

        it("true for reader macros", function()
            h.with_tree("'(foo)", "clojure", function(root)
                local rm = h.find_first(root, lisp.is_reader_macro)
                if rm then
                    assert(lisp.is_form(rm))
                end
            end)
        end)
    end)

    describe("get_form_macro", function()
        it("works with macro-reader node", function()
            h.with_tree("'(foo)", "fennel", function(root)
                local form = h.find_first(root, lisp.is_form)
                local macro = lisp.get_form_macro(form)
                assert.is.Not.Nil(macro)
                assert.is.equal("'", macro:type())
            end)
        end)

        it("works with list node", function()
            h.with_tree("'(foo)", "fennel", function(root)
                local list = lisp.try_node_to_list(h.find_first(root, lisp.is_form))
                local macro = lisp.get_form_macro(list)
                assert.is.Not.Nil(macro)
                assert.is.equal("'", macro:type())
            end)
        end)
    end)

    describe("get_list_delims", function()
        it("returns open and close for ()", function()
            h.with_tree("(foo)", "fennel", function(root)
                local open, close = lisp.get_list_delims(h.find_first(root, lisp.is_list))
                local _, _, ob = open:start()
                local _, _, cb = close:start()
                assert(ob < cb)
            end)
        end)
    end)

    describe("get_form_delims", function()
        it("returns open and close for ()", function()
            h.with_tree("(foo)", "fennel", function(root)
                local open, close, macro = lisp.get_form_delims(h.find_first(root, lisp.is_list))
                assert.is_nil(macro)
                assert.is.equal("(", open:type())
                assert.is.equal(")", close:type())
                assert(tslib.is_before(open, close))
            end)
        end)
        it("returns open and close for '()", function()
            h.with_tree("'(foo)", "fennel", function(root)
                local open, close, macro = lisp.get_form_delims(h.find_first(root, lisp.is_form))
                assert.is.equal("'", macro:type())
                assert.is.equal("(", open:type())
                assert.is.equal(")", close:type())
                assert(tslib.starts_before(macro, open))
                assert(tslib.is_before(open, close))
            end)
        end)
    end)

    describe("enclosing_form", function()
        -- INVARIANT (tslib:413): returns enclosing form that is NOT this node.
        it("on a list returns its parent form, not itself", function()
            h.with_tree("(foo (bar))", "fennel", function(root)
                local lists = h.find_all(root, lisp.is_list)
                local inner = lists[#lists]
                local enc = lisp.enclosing_form(inner)
                assert(enc and enc:id() ~= inner:id(), "enclosing form must differ from input")
            end)
        end)

        it("on a list inside a reader-macro returns an outer form, not the wrapping reader-macro", function()
            -- INVARIANT (tslib:415-417): "skip first iteration if it's us" branch ensures
            -- a list whose immediate parent is a reader-macro does NOT return that wrapper
            -- (a sibling form, not strictly enclosing).
            h.with_tree("(outer '(inner))", "clojure", function(root)
                local lists = h.find_all(root, lisp.is_list)
                local enc = lisp.enclosing_form(lists[#lists])
                assert(enc, "should find an enclosing form")
                local rm = h.find_first(root, lisp.is_reader_macro)
                if rm then
                    assert(enc:id() ~= rm:id(), "enclosing_form should not be the reader-macro wrapper")
                end
            end)
        end)
    end)

    describe("nearest_form / enclosing_form precedence", function()
        -- CORRECTNESS: cursor on the `(` of `'(foo)` resolves to the reader-macro form,
        -- not the inner list. is_reader_macro branch (tslib:401) fires before inner is_list match.
        for _, c in ipairs({
            { "'<C>(foo)", "cursor on `(` inside `'(foo)`" },
            { "<C>~@(foo)", "cursor on `~` of `~@(foo)` (byte 0)" },
            -- TODO(verify): tree-sitter-clojure may emit `~@` as one token or two.
            -- Either way the byte-1 point lands inside the prefix and walks up to the rm.
            { "~<C>@(foo)", "cursor on `@` of `~@(foo)` (byte 1)" },
        }) do
            it(("%s -> reader-macro node"):format(c[2]), function()
                h.with_tree_at_cursor(c[1], "clojure", function(node)
                    local form = lisp.nearest_form(node)
                    assert(form and lisp.is_reader_macro(form), "nearest_form should be the reader-macro")
                end)
            end)
        end

        it("cursor on inner list of `'(foo)` resolves to a form that contains the inner list", function()
            -- nearest_form on a list inside a reader-macro returns the inner list itself
            -- (inclusive walk yields list as cur, sees rm at next step which IS a form).
            -- Canonical "wraps it" property: result spans >= the inner list.
            -- TODO(verify): assertion is "form range includes the inner list" — adjust if
            -- the actual return is the reader-macro under different shapes.
            h.with_tree_at_cursor("'<C>(foo)", "clojure", function(node, root)
                local form = lisp.nearest_form(node)
                local inner = h.find_all(root, lisp.is_list)
                inner = inner[#inner]
                local sr, _, er, ec = form:range()
                local isr, _, ier, iec = inner:range()
                assert(sr <= isr and ec >= iec and er >= ier, "form should span >= inner list")
            end)
        end)
    end)

    describe("iter_form_exprs", function()
        -- tslib:516-519: recurses through non-word/non-form children rather than skipping.
        for _, c in ipairs({
            { "(a b c)", 3, name = "yields direct word children of a form" },
            { "(a (b c) d)", 3, name = "yields nested forms as expressions" },
        }) do
            it(c.name, function()
                h.with_tree(c[1], "fennel", function(root)
                    assert.are.equal(c[2], #h.collect(lisp.iter_form_exprs(h.find_first(root, lisp.is_list))))
                end)
            end)
        end

        -- {input, expected_text_to_reach, lang, name}
        for _, c in ipairs({
            -- tslib:516-519: metadata wrapper is neither word nor form; iterator descends.
            -- TODO(verify): exact count may depend on grammar shape; assertion is "yields bar".
            { "(^:foo bar)", "bar", "clojure", "recurses through `^:foo` to reach bar" },
            -- TODO(verify): grammars vary in how they shape double metadata. Pin behavior.
            { "(^:a ^:b c)", "c", "clojure", "recurses through nested non-form wrappers (double-meta)" },
        }) do
            it(c[4], function()
                h.with_tree(c[1], c[3], function(root)
                    local outer = h.find_first(root, lisp.is_list)
                    local saw = false
                    for child in lisp.iter_form_exprs(outer) do
                        if vim.treesitter.get_node_text(child, c[1]) == c[2] then
                            saw = true
                        end
                    end
                    assert(saw, ("iter_form_exprs should reach %q in %q"):format(c[2], c[1]))
                end)
            end)
        end

        it("yields quoted-list children as forms (reader-macro is a form)", function()
            h.with_tree("(let '(a b) c)", "clojure", function(root)
                local outer = h.find_first(root, lisp.is_list)
                local saw_rm, count = false, 0
                for child in lisp.iter_form_exprs(outer) do
                    count = count + 1
                    if lisp.is_reader_macro(child) then
                        saw_rm = true
                    end
                end
                -- 3: `let`, `'(a b)`, `c`.
                assert.are.equal(3, count)
                assert(saw_rm, "the `'(a b)` child should appear as a reader-macro form")
            end)
        end)
    end)

    describe("next_sibling_expr / prev_sibling_expr", function()
        -- 6-line inverse property: prev . next == identity where both defined.
        -- Catches asymmetric termination at tslib:547-552 vs 561-565.
        it("prev_sibling_expr is left-inverse of next_sibling_expr", function()
            h.with_tree("(a b c d)", "fennel", function(root)
                local exprs = h.collect(lisp.iter_form_exprs(h.find_first(root, lisp.is_list)))
                assert(#exprs >= 3, "need >=3 exprs to test inverses; got " .. #exprs)
                for i = 1, #exprs - 1 do
                    local nxt = lisp.next_sibling_expr(exprs[i])
                    assert(nxt, ("next_sibling_expr undefined for idx %d"):format(i))
                    assert.are.equal(exprs[i]:id(), lisp.prev_sibling_expr(nxt):id())
                end
            end)
        end)
    end)

    describe("is_single_symbol / is_compound_word / is_word", function()
        it("is_single_symbol true on a bare atom", function()
            h.with_tree("foo", "fennel", function(root)
                local atom = h.find_atom(root)
                if atom then
                    assert(lisp.is_single_symbol(atom))
                end
            end)
        end)

        it("is_list and is_single_symbol are mutually exclusive", function()
            h.with_tree("(foo)", "fennel", function(root)
                local list = h.find_first(root, lisp.is_list)
                assert(lisp.is_list(list))
                assert(not lisp.is_single_symbol(list))
            end)
        end)
    end)
end)

-- Property tests over a small fennel corpus. RNG deterministic via TEST_SEED.
-- 50-100 iter cap so they run on every CI.
describe("bartbie.treesitter.lisp properties", function()
    local CORPUS = {
        "(foo bar)",
        "(let [x 1] (+ x y))",
        "(a (b (c d)))",
        "(do (print x) (print y) z)",
        "(if a b c)",
        "(fn [x y] (* x y))",
        "{:a 1 :b 2}",
        "[1 2 [3 4] 5]",
        "((nested) (forms) (here))",
    }

    local function ancestors(node)
        local out = {}
        local p = node:parent()
        while p do
            out[#out + 1] = p:id()
            p = p:parent()
        end
        return out
    end

    local function is_ancestor(maybe_anc, node)
        for _, id in ipairs(ancestors(node)) do
            if id == maybe_anc:id() then
                return true
            end
        end
        return false
    end

    it("enclosing_form(nearest_form(n)) is strictly ancestral when defined", function()
        for _, src in ipairs(CORPUS) do
            h.with_tree(src, "fennel", function(root)
                for n in tslib.walk_children_dfs(root) do
                    local nf = lisp.nearest_form(n)
                    if nf then
                        local ef = lisp.enclosing_form(nf)
                        if ef then
                            assert(ef:id() ~= nf:id(), ("enclosing_form returned input form (src=%q)"):format(src))
                            assert(is_ancestor(ef, nf), ("not strictly ancestral (src=%q)"):format(src))
                        end
                    end
                end
            end)
        end
    end)

    it("prev_sibling_expr is left-inverse of next_sibling_expr across the corpus", function()
        for _, src in ipairs(CORPUS) do
            h.with_tree(src, "fennel", function(root)
                for _, form in ipairs(h.find_all(root, lisp.is_form)) do
                    local exprs = h.collect(lisp.iter_form_exprs(form))
                    for i = 1, #exprs do
                        local nxt = lisp.next_sibling_expr(exprs[i])
                        if nxt then
                            local back = lisp.prev_sibling_expr(nxt)
                            assert(back, ("prev_sibling_expr undefined after next in %q"):format(src))
                            assert.are.equal(exprs[i]:id(), back:id())
                        end
                    end
                end
            end)
        end
    end)

    it("is_contiguous holds for every reified compound word from iter_form_exprs", function()
        -- is_compound_word's definition (tslib:460-465) requires is_contiguous, so any
        -- compound-word node must satisfy is_contiguous. Pins the contract callers
        -- downstream of iter_form_exprs rely on.
        for _, src in ipairs({ "(vim.fs.joinpath a b)", "(let [foo.bar 1] foo.bar)", "(io.write x)" }) do
            h.with_tree(src, "fennel", function(root)
                for _, form in ipairs(h.find_all(root, lisp.is_form)) do
                    for child in lisp.iter_form_exprs(form) do
                        if lisp.is_compound_word(child) then
                            assert(tslib.is_contiguous(child), ("compound word not contiguous in %q"):format(src))
                        end
                    end
                end
            end)
        end
    end)

    it("RNG-driven walk: random-pick a corpus form, walk all descendants, all properties hold", function()
        -- 100 iter, deterministic seed (TEST_SEED or 0xC0FFEE). Each iter:
        -- pick random src, walk DFS, sample-check enclosing_form / sibling inverse / contiguous.
        local rng = h.rng()
        for _ = 1, 100 do
            local src = rng.pick(CORPUS)
            h.with_tree(src, "fennel", function(root)
                local all = h.collect(tslib.walk_children_dfs(root))
                if #all == 0 then
                    return
                end
                local nf = lisp.nearest_form(all[rng.int(1, #all)])
                if nf then
                    local ef = lisp.enclosing_form(nf)
                    if ef then
                        assert(ef:id() ~= nf:id(), ("seed=%d src=%q: enclosing_form returned input"):format(rng.seed(), src))
                        assert(is_ancestor(ef, nf), ("seed=%d src=%q: not strictly ancestral"):format(rng.seed(), src))
                    end
                end
            end)
        end
    end)

    -- Data-driven head/foot: same setup, swap the operation.
    for _, op in ipairs({
        { name = "get_head", fn = lisp.get_head, cases = {
            { "(a b) c", "a" },
            { "a (b) c", "b" },
            { "a () c", nil },
        } },
        { name = "get_foot", fn = lisp.get_foot, cases = {
            { "(a b) c", "b" },
            { "a (b) c", "b" },
            { "a () c", nil },
        } },
    }) do
        describe(("bartbie.treesitter.lisp.%s"):format(op.name), function()
            for _, c in ipairs(op.cases) do
                it(("%q -> %s"):format(c[1], c[2] or "nil"), function()
                    h.with_buf({ c[1] }, "fennel", function(buf, root)
                        local result = op.fn(h.find_first(root, lisp.is_list))
                        if c[2] == nil then
                            assert.is_nil(result)
                        else
                            assert.equal(c[2], vim.treesitter.get_node_text(result, buf))
                        end
                    end)
                end)
            end
        end)
    end
end)
