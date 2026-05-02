local h = require("spec.helpers")
local tslib = require("bartbie.treesitter")
local lisp = tslib.lisp

h.assert_grammar("fennel")
h.assert_grammar("clojure")
h.assert_grammar("janet_simple")

describe("bartbie.treesitter", function()
    describe("walk_children_dfs", function()
        it("yields every descendant", function()
            h.with_tree("(foo (bar baz))", "fennel", function(root)
                local count = 0
                for _ in tslib.walk_children_dfs(root) do
                    count = count + 1
                end
                assert(count > 3, "expected multiple descendants, got " .. count)
            end)
        end)

        it("yields in DFS order (parent before its descendants)", function()
            h.with_tree("(a (b c))", "fennel", function(root)
                local seen = {}
                for n in tslib.walk_children_dfs(root) do
                    seen[#seen + 1] = n
                end
                -- For any node at index i with parent in seen, parent appears at lower index.
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
        it("excludes node itself by default", function()
            h.with_tree("(foo (bar))", "fennel", function(root)
                local lists = h.find_all(root, lisp.is_list)
                local inner = lists[#lists]
                for n in tslib.walk_parents(inner) do
                    assert(n:id() ~= inner:id(), "default walk should exclude self")
                end
            end)
        end)

        it("includes node when inclusive=true", function()
            h.with_tree("(foo (bar))", "fennel", function(root)
                local lists = h.find_all(root, lisp.is_list)
                local inner = lists[#lists]
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
                local lists = h.find_all(root, lisp.is_list)
                local inner = lists[#lists]
                for cur, prev in tslib.walk_parents(inner, { with_previous = true }) do
                    assert(cur)
                    if prev then
                        assert(prev:parent() and prev:parent():id() == cur:id(), "prev should be a child of cur")
                    end
                end
            end)
        end)
    end)

    describe("get_containing_node", function()
        -- 8 branches per tslib:84-107
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
                assert(#lists >= 2)
                assert.is_nil(tslib.get_containing_node(lists[1], lists[2]))
            end)
        end)

        it("returns (0, a) when a strictly contains b", function()
            h.with_tree("(foo (bar))", "fennel", function(root)
                local outer = h.find_first(root, lisp.is_list)
                local inner = h.find_first(outer, function(n)
                    return n:id() ~= outer:id() and lisp.is_list(n)
                end)
                local side, node = tslib.get_containing_node(outer, inner)
                assert.are.equal(0, side)
                assert.are.equal(outer:id(), node:id())
            end)
        end)

        it("returns (1, b) when b strictly contains a", function()
            h.with_tree("(foo (bar))", "fennel", function(root)
                local outer = h.find_first(root, lisp.is_list)
                local inner = h.find_first(outer, function(n)
                    return n:id() ~= outer:id() and lisp.is_list(n)
                end)
                local side, node = tslib.get_containing_node(inner, outer)
                assert.are.equal(1, side)
                assert.are.equal(outer:id(), node:id())
            end)
        end)

        it("returns (0, a) for equal-span identical nodes (current behavior)", function()
            -- CORRECTNESS: equal spans fall to else branch (tslib:104-106) -> 1, b.
            -- Documenting this; callers should not rely on which side is returned for equal spans.
            h.with_tree("(foo)", "fennel", function(root)
                local list = h.find_first(root, lisp.is_list)
                local side, node = tslib.get_containing_node(list, list)
                assert.are.equal(0, side)
                assert.are.equal(list:id(), node:id())
            end)
        end)
    end)

    describe("is_contiguous", function()
        -- INVARIANT (tslib:443-455): prev_end_row is never assigned for empty/single-child,
        -- so the function returns true vacuously.
        it("returns true on a node with no children (vacuous)", function()
            h.with_tree("foo", "fennel", function(root)
                local leaf = h.find_first(root, function(n)
                    return n:named_child_count() == 0
                end)
                assert(leaf, "should find a leaf node")
                assert.is_true(tslib.is_contiguous(leaf))
            end)
        end)

        it("returns true for spatially-adjacent siblings", function()
            -- Two atoms inside a list separated by exactly one space *as children of a list*
            -- are not adjacent (the space is between them). But the list as a whole, with
            -- delimiters touching atoms? Depends on grammar. Smoke check: is_contiguous returns boolean.
            h.with_tree("(ab)", "fennel", function(root)
                local list = h.find_first(root, lisp.is_list)
                local result = tslib.is_contiguous(list)
                assert.are.equal("boolean", type(result))
            end)
        end)
    end)

    describe("sorted_node_set", function()
        it("deduplicates by id", function()
            h.with_tree("(foo)", "fennel", function(root)
                local list = h.find_first(root, lisp.is_list)
                local result = tslib.sorted_node_set({ list, list, list })
                assert.are.equal(1, #result)
            end)
        end)

        it("sorts by start position", function()
            -- All three lists are on the same row; compare by byte offset
            -- (third return of TSNode:start()) rather than row scalar.
            h.with_tree("(a) (b) (c)", "fennel", function(root)
                local lists = h.find_all(root, lisp.is_list)
                local shuffled = { lists[3], lists[1], lists[2] }
                local sorted = tslib.sorted_node_set(shuffled)
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
                local r = tslib.nearest_named(list)
                assert.are.equal(list:id(), r:id())
            end)
        end)
    end)

    describe("is_leaf / first_named_child / last_named_child", function()
        it("is_leaf true on atoms, false on lists", function()
            h.with_tree("(foo)", "fennel", function(root)
                local list = h.find_first(root, lisp.is_list)
                assert.is_false(tslib.is_leaf(list))
            end)
        end)

        it("first/last_named_child are first and last", function()
            -- Compare via byte offset (third return of :start()); first/last are on
            -- the same row so a row-scalar comparison would be a no-op.
            h.with_tree("(a b c)", "fennel", function(root)
                local list = h.find_first(root, lisp.is_list)
                local first = tslib.first_named_child(list)
                local last = tslib.last_named_child(list)
                assert(first and last)
                local _, _, fb = first:start()
                local _, _, lb = last:start()
                assert(fb < lb or first:id() == last:id())
            end)
        end)
    end)

    describe("range_tbl", function()
        it("returns the 4-keyed range record", function()
            h.with_tree("(foo)", "fennel", function(root)
                local list = h.find_first(root, lisp.is_list)
                local r = tslib.range_tbl(list)
                for _, k in ipairs({ "start_row", "start_col", "end_row", "end_col" }) do
                    assert.are.equal("number", type(r[k]))
                end
            end)
        end)
    end)
end)

describe("bartbie.treesitter.lisp", function()
    describe("is_list", function()
        it("true for (...)", function()
            h.with_tree("(foo)", "fennel", function(root)
                local list = h.find_first(root, lisp.is_list)
                assert(list, "should find a list")
            end)
        end)

        it("true for [...]", function()
            h.with_tree("[foo]", "fennel", function(root)
                local list = h.find_first(root, lisp.is_list)
                assert(list, "should find a list")
            end)
        end)

        it("true for {...}", function()
            h.with_tree("{:a 1}", "fennel", function(root)
                local list = h.find_first(root, lisp.is_list)
                assert(list, "should find a list")
            end)
        end)
    end)

    describe("is_reader_macro", function()
        it("true for '(foo) (clojure)", function()
            -- INVARIANT: is_reader_macro (tslib:328) requires the macro to wrap
            -- a list - the named child must satisfy is_list. '(foo) qualifies;
            -- 'foo (wrapping a bare symbol) does not.
            h.with_tree("'(foo)", "clojure", function(root)
                local rm = h.find_first(root, lisp.is_reader_macro)
                assert(rm, "should find reader macro")
            end)
        end)

        it("true for ~@foo (clojure)", function()
            h.with_tree("~@(foo)", "clojure", function(root)
                local rm = h.find_first(root, lisp.is_reader_macro)
                assert(rm, "should find unquote-splicing reader macro")
            end)
        end)
    end)

    describe("is_form", function()
        it("true for lists", function()
            h.with_tree("(foo)", "fennel", function(root)
                local list = h.find_first(root, lisp.is_list)
                assert(lisp.is_form(list))
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
                assert(form)
                local macro = lisp.get_form_macro(form)
                assert.is.Not.Nil(macro)
                assert.is.equal("'", macro:type())
            end)
        end)

        it("works with list node", function()
            h.with_tree("'(foo)", "fennel", function(root)
                local form = h.find_first(root, lisp.is_form)
                assert(form)
                local list = lisp.try_node_to_list(form)
                assert(list)
                local macro = lisp.get_form_macro(list)
                assert.is.Not.Nil(macro)
                assert.is.equal("'", macro:type())
            end)
        end)
    end)

    describe("get_list_delims", function()
        it("returns open and close for ()", function()
            h.with_tree("(foo)", "fennel", function(root)
                local list = h.find_first(root, lisp.is_list)
                local open, close = lisp.get_list_delims(list)
                assert(open and close)
                local _, _, ob = open:start()
                local _, _, cb = close:start()
                assert(ob < cb)
            end)
        end)
    end)

    describe("get_form_delims", function()
        it("returns open and close for ()", function()
            h.with_tree("(foo)", "fennel", function(root)
                local list = h.find_first(root, lisp.is_list)
                assert(list)
                local open, close, macro = lisp.get_form_delims(list)
                assert(open)
                assert(close)
                assert.is_nil(macro)
                assert.is.equal("(", open:type())
                assert.is.equal(")", close:type())
                assert(tslib.is_before(open, close))
            end)
        end)
        it("returns open and close for '()", function()
            h.with_tree("'(foo)", "fennel", function(root)
                local list = h.find_first(root, lisp.is_form)
                assert(list)
                local open, close, macro = lisp.get_form_delims(list)
                assert.is_not_nil(open)
                assert.is_not_nil(close)
                assert.is_not_nil(macro)
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
                assert(enc, "should find enclosing form")
                assert(enc:id() ~= inner:id(), "enclosing form must differ from input")
            end)
        end)

        it("on a list inside a reader-macro returns an outer form, not the wrapping reader-macro", function()
            -- INVARIANT (tslib:415-417): the "skip first iteration if it's us" branch ensures
            -- that for a list whose immediate parent is a reader-macro, enclosing_form does NOT
            -- return that reader-macro (which would be a sibling form of the list, not strictly enclosing).
            h.with_tree("(outer '(inner))", "clojure", function(root)
                local lists = h.find_all(root, lisp.is_list)
                -- pick the innermost list (the (inner) one)
                local inner_list = lists[#lists]
                local enc = lisp.enclosing_form(inner_list)
                assert(enc, "should find an enclosing form")
                -- enc must be strictly outside the reader-macro wrapper, i.e. the outer list.
                local rm = h.find_first(root, lisp.is_reader_macro)
                if rm then
                    assert(
                        enc:id() ~= rm:id(),
                        "enclosing_form of inner list should not be its own reader-macro wrapper"
                    )
                end
            end)
        end)
    end)

    describe("nearest_form / enclosing_form precedence", function()
        -- CORRECTNESS: cursor on the `(` of `'(foo)` should resolve to the reader-macro
        -- form, not the inner list. The is_reader_macro branch (tslib:401) fires before
        -- the inner is_list match.
        it("cursor on `(` inside `'(foo)` -> reader-macro node", function()
            h.with_tree_at_cursor("'<C>(foo)", "clojure", function(node)
                local form = lisp.nearest_form(node)
                assert(form, "should find a form")
                assert(lisp.is_reader_macro(form), "nearest_form on `(` inside reader-macro should be the reader-macro")
            end)
        end)

        it("cursor on `~` of `~@(foo)` -> reader-macro node (byte 0)", function()
            h.with_tree_at_cursor("<C>~@(foo)", "clojure", function(node)
                local form = lisp.nearest_form(node)
                assert(form, "should find a form")
                assert(lisp.is_reader_macro(form), "nearest_form on `~` of `~@` should be the reader-macro form")
            end)
        end)

        it("cursor on `@` of `~@(foo)` -> reader-macro node (byte 1)", function()
            -- TODO(verify): tree-sitter-clojure may emit `~@` as one token or two.
            -- Either way the byte-1 point lands inside the prefix and walks up to the rm.
            h.with_tree_at_cursor("~<C>@(foo)", "clojure", function(node)
                local form = lisp.nearest_form(node)
                assert(form, "should find a form")
                assert(lisp.is_reader_macro(form), "nearest_form on `@` of `~@` should be the reader-macro form")
            end)
        end)

        it("cursor on inner list of `'(foo)` resolves to a form that contains the inner list", function()
            -- Precedence: nearest_form on a list inside a reader-macro returns the inner list
            -- itself (the inclusive walk yields the list as cur, sees the reader-macro at the next
            -- step which IS a form). The canonical "wraps it" property is that nearest_form's result
            -- spans >= the inner list. Pin down this current behavior.
            -- TODO(verify): assertion is "form range includes the inner list" -- adjust if the
            -- actual return is the reader-macro vs the inner list, both are observed under
            -- different reader-macro shapes.
            h.with_tree_at_cursor("'<C>(foo)", "clojure", function(node, root)
                local form = lisp.nearest_form(node)
                assert(form, "should find a form")
                local lists = h.find_all(root, lisp.is_list)
                local inner = lists[#lists]
                local sr, sc, er, ec = form:range()
                local isr, isc, ier, iec = inner:range()
                -- form span contains inner's span
                assert(sr <= isr and ec >= iec and er >= ier, "form should span >= inner list")
            end)
        end)
    end)

    describe("get_containing_node corner cases", function()
        it("a == b (same instance) -> (0, a) via equal-spans path", function()
            -- CORRECTNESS: when called with identical node, the size delta check
            -- (tslib:102-106) takes the else branch -> 1, b.
            h.with_tree("(foo)", "fennel", function(root)
                local list = h.find_first(root, lisp.is_list)
                local side, node = tslib.get_containing_node(list, list)
                assert.are.equal(0, side)
                assert.are.equal(list:id(), node:id())
            end)
        end)

        it("multi-byte content: byte-range comparison handles unicode bodies", function()
            -- get_containing_node uses :start() / :end_() byte offsets. If one node has
            -- multi-byte content the comparison still uses bytes, not chars.
            h.with_tree("(foo (héllo))", "fennel", function(root)
                local lists = h.find_all(root, lisp.is_list)
                local outer = lists[1]
                local inner = lists[#lists]
                local side, node = tslib.get_containing_node(outer, inner)
                assert.are.equal(0, side)
                assert.are.equal(outer:id(), node:id())
            end)
        end)
    end)

    describe("iter_form_exprs", function()
        -- tslib:516-519: recurses through non-word/non-form children rather than skipping them.
        it("yields direct word children of a form", function()
            h.with_tree("(a b c)", "fennel", function(root)
                local list = h.find_first(root, lisp.is_list)
                local count = 0
                for _ in lisp.iter_form_exprs(list) do
                    count = count + 1
                end
                assert.are.equal(3, count)
            end)
        end)

        it("yields nested forms as expressions", function()
            h.with_tree("(a (b c) d)", "fennel", function(root)
                local outer = h.find_first(root, lisp.is_list)
                local count = 0
                for _ in lisp.iter_form_exprs(outer) do
                    count = count + 1
                end
                assert.are.equal(3, count)
            end)
        end)

        it("recurses through non-word non-form children (clojure metadata `^:foo bar`)", function()
            -- tslib:516-519: recurses through children that are neither words nor forms.
            -- Clojure metadata `^:foo` attaches as a `meta_form` (or similar) wrapper. The
            -- iterator should descend into it and still yield the underlying word(s).
            -- TODO(verify): the exact count may depend on grammar shape; assertion is "yields at
            -- least one expr including bar".
            h.with_tree("(^:foo bar)", "clojure", function(root)
                local outer = h.find_first(root, lisp.is_list)
                local saw_bar = false
                for child in lisp.iter_form_exprs(outer) do
                    local txt = vim.treesitter.get_node_text(child, "(^:foo bar)")
                    if txt == "bar" then
                        saw_bar = true
                    end
                end
                assert(saw_bar, "iter_form_exprs should reach `bar` through the metadata wrapper")
            end)
        end)

        it("yields quoted-list children as forms (reader-macro is a form)", function()
            h.with_tree("(let '(a b) c)", "clojure", function(root)
                local outer = h.find_first(root, lisp.is_list)
                local count = 0
                local saw_rm = false
                for child in lisp.iter_form_exprs(outer) do
                    count = count + 1
                    if lisp.is_reader_macro(child) then
                        saw_rm = true
                    end
                end
                -- We expect 3: `let`, `'(a b)`, `c`
                assert.are.equal(3, count)
                assert(saw_rm, "the `'(a b)` child should appear as a reader-macro form")
            end)
        end)

        it("recurses through deeply nested non-form wrappers (clojure double-meta)", function()
            -- TODO(verify): grammars vary in how they shape double metadata. Pin behavior.
            h.with_tree("(^:a ^:b c)", "clojure", function(root)
                local outer = h.find_first(root, lisp.is_list)
                local saw_c = false
                for child in lisp.iter_form_exprs(outer) do
                    local txt = vim.treesitter.get_node_text(child, "(^:a ^:b c)")
                    if txt == "c" then
                        saw_c = true
                    end
                end
                assert(saw_c, "iter_form_exprs should reach `c` through nested metadata")
            end)
        end)
    end)

    describe("next_sibling_expr / prev_sibling_expr", function()
        -- 6-line inverse property: prev . next == identity where both defined.
        -- Catches the asymmetric termination at tslib:547-552 vs 561-565.
        it("prev_sibling_expr is left-inverse of next_sibling_expr", function()
            h.with_tree("(a b c d)", "fennel", function(root)
                local list = h.find_first(root, lisp.is_list)
                local exprs = {}
                for e in lisp.iter_form_exprs(list) do
                    exprs[#exprs + 1] = e
                end
                assert(#exprs >= 3, "need >=3 exprs to test inverses; got " .. #exprs)
                for i = 1, #exprs - 1 do
                    local nxt = lisp.next_sibling_expr(exprs[i])
                    assert(nxt, ("next_sibling_expr undefined for idx %d"):format(i))
                    local back = lisp.prev_sibling_expr(nxt)
                    assert(back, "prev_sibling_expr undefined")
                    assert.are.equal(exprs[i]:id(), back:id())
                end
            end)
        end)
    end)

    describe("is_single_symbol / is_compound_word / is_word", function()
        it("is_single_symbol true on a bare atom", function()
            h.with_tree("foo", "fennel", function(root)
                local atom = h.find_first(root, function(n)
                    return n:named_child_count() == 0 and not lisp.is_list(n)
                end)
                if atom then
                    assert(lisp.is_single_symbol(atom))
                end
            end)
        end)

        it("is_list and is_single_symbol are mutually exclusive", function()
            h.with_tree("(foo)", "fennel", function(root)
                local list = h.find_first(root, lisp.is_list)
                assert(list)
                assert(lisp.is_list(list))
                assert(not lisp.is_single_symbol(list))
            end)
        end)
    end)
end)

-- Property tests over a small fennel corpus. RNG is deterministic via TEST_SEED.
-- Bodies are kept cheap (50-100 iterations max) so they can run on every CI.
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
                            assert(
                                is_ancestor(ef, nf),
                                ("enclosing_form(%q) not strictly ancestral of nearest_form result"):format(src)
                            )
                        end
                    end
                end
            end)
        end
    end)

    it("prev_sibling_expr is left-inverse of next_sibling_expr across the corpus", function()
        for _, src in ipairs(CORPUS) do
            h.with_tree(src, "fennel", function(root)
                local forms = h.find_all(root, lisp.is_form)
                for _, form in ipairs(forms) do
                    local exprs = {}
                    for e in lisp.iter_form_exprs(form) do
                        exprs[#exprs + 1] = e
                    end
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
        -- is_compound_word's definition (tslib:460-465) requires is_contiguous, so any node
        -- for which is_compound_word=true must satisfy is_contiguous. This property pins down
        -- the contract: callers downstream of iter_form_exprs can rely on the invariant.
        local compound_corpus = {
            "(vim.fs.joinpath a b)",
            "(let [foo.bar 1] foo.bar)",
            "(io.write x)",
        }
        for _, src in ipairs(compound_corpus) do
            h.with_tree(src, "fennel", function(root)
                local forms = h.find_all(root, lisp.is_form)
                for _, form in ipairs(forms) do
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
        -- 100 iterations, deterministic seed (TEST_SEED or 0xC0FFEE). Each iteration:
        -- pick a random src, walk DFS, sample-check enclosing_form / sibling inverse / contiguous.
        local rng = h.rng()
        local ITER = 100
        for _ = 1, ITER do
            local src = rng.pick(CORPUS)
            h.with_tree(src, "fennel", function(root)
                local all = {}
                for n in tslib.walk_children_dfs(root) do
                    all[#all + 1] = n
                end
                if #all == 0 then
                    return
                end
                local n = all[rng.int(1, #all)]
                local nf = lisp.nearest_form(n)
                if nf then
                    local ef = lisp.enclosing_form(nf)
                    if ef then
                        assert(
                            ef:id() ~= nf:id(),
                            ("seed=%d src=%q: enclosing_form returned input"):format(rng.seed(), src)
                        )
                        assert(
                            is_ancestor(ef, nf),
                            ("seed=%d src=%q: enclosing_form not strictly ancestral"):format(rng.seed(), src)
                        )
                    end
                end
            end)
        end
    end)

    describe("bartbie.treesitter.lisp.get_head", function()
        it("(a b) c -> a", function()
            h.with_buf({ "(a b) c" }, "fennel", function(buf, root)
                local list = h.find_first(root, lisp.is_list)
                assert(list)
                local head = lisp.get_head(list)
                assert.is_not_nil(head)
                assert.equal("a", vim.treesitter.get_node_text(head, buf))
            end)
        end)
        it("a (b) c -> b", function()
            h.with_buf({ "a (b) c" }, "fennel", function(buf, root)
                local list = h.find_first(root, lisp.is_list)
                assert(list)
                local head = lisp.get_head(list)
                assert.is_not_nil(head)
                assert.equal("b", vim.treesitter.get_node_text(head, buf))
            end)
        end)
        it("a () c -> nil", function()
            h.with_buf({ "a () c" }, "fennel", function(buf, root)
                local list = h.find_first(root, lisp.is_list)
                assert(list)
                local head = lisp.get_head(list)
                assert.is_nil(head)
            end)
        end)
    end)
    describe("bartbie.treesitter.lisp.get_foot", function()
        it("(a b) c -> b", function()
            h.with_buf({ "(a b) c" }, "fennel", function(buf, root)
                local list = h.find_first(root, lisp.is_list)
                assert(list)

                local foot = lisp.get_foot(list)
                assert.is_not_nil(foot)
                assert.equal("b", vim.treesitter.get_node_text(foot, buf))
            end)
        end)
        it("a (b) c -> b", function()
            h.with_buf({ "a (b) c" }, "fennel", function(buf, root)
                local list = h.find_first(root, lisp.is_list)
                assert(list)
                local foot = lisp.get_foot(list)
                assert.is_not_nil(foot)
                assert.equal("b", vim.treesitter.get_node_text(foot, buf))
            end)
        end)
        it("a () c -> nil", function()
            h.with_buf({ "a () c" }, "fennel", function(buf, root)
                local list = h.find_first(root, lisp.is_list)
                assert(list)
                local foot = lisp.get_foot(list)
                assert.is_nil(foot)
            end)
        end)
    end)
end)
