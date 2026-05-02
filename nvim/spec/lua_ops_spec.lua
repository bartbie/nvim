local h = require("spec.helpers")
local structural = require("bartbie.structural")

-- Covers the non-lisp branch of operand_and_ctx (structural.lua:30):
-- operand = tslib.nearest_named(cursor_node), parent = this:parent().
-- Without these, the entire non-lisp path is untested.
h.assert_grammar("lua")
h.assert_grammar("json")

-- Many of these edits produce intermediate parse errors (e.g. deleting an
-- identifier out of `local x = 1`). The lisp suite relies on the post-edit
-- tree being clean; here we opt out via allow_parse_errors per case.
local NO_PARSE_CHECK = { allow_parse_errors = true }

describe("structural non-lisp [json] #nonlisp", function()
    describe("swap_siblings_next", function()
        it("swaps array elements", function()
            h.golden("[<C>1, 2, 3]", "[2, 1, 3]", structural.swap_siblings_next, "json")
        end)
        it("swaps middle with last", function()
            h.golden("[1, <C>2, 3]", "[1, 3, 2]", structural.swap_siblings_next, "json")
        end)
    end)

    describe("swap_siblings_prev", function()
        it("swaps with previous", function()
            h.golden("[1, <C>2, 3]", "[2, 1, 3]", structural.swap_siblings_prev, "json")
        end)
    end)

    describe("raise", function()
        -- raise: src=this, dst=parent; tslib.replace_node copies src text into dst.
        -- For json [1, [2, 3], 4] with cursor on inner 2, the nearest_named is
        -- the number `2` and its parent is the inner array; replacing the array
        -- with `2` yields [1, 2, 4].
        it("raises a nested number out of its array", function()
            h.golden("[1, [<C>2, 3], 4]", "[1, 2, 4]", structural.raise, "json")
        end)
    end)

    describe("delete_node", function()
        it("removes a number atom", function()
            h.golden("[1, <C>2, 3]", "[1, , 3]", structural.delete_node, "json", NO_PARSE_CHECK)
        end)
    end)
end)

describe("structural non-lisp [lua] #nonlisp", function()
    describe("swap_siblings_next", function()
        it("swaps table elements", function()
            h.golden(
                "local t = { <C>1, 2, 3 }",
                "local t = { 2, 1, 3 }",
                structural.swap_siblings_next,
                "lua",
                NO_PARSE_CHECK
            )
        end)
    end)

    describe("swap_siblings_prev", function()
        it("swaps table elements backward", function()
            h.golden(
                "local t = { 1, <C>2, 3 }",
                "local t = { 2, 1, 3 }",
                structural.swap_siblings_prev,
                "lua",
                NO_PARSE_CHECK
            )
        end)
    end)

    describe("delete_node", function()
        -- Deleting an identifier from `local x = 1` produces a parse error
        -- (orphan `local  = 1`); we just want to confirm the non-lisp branch
        -- reaches tslib.delete_node without crashing.
        it("removes a number from a table literal", function()
            h.golden("local t = { 1, <C>2, 3 }", "local t = { 1, , 3 }", structural.delete_node, "lua", NO_PARSE_CHECK)
        end)
    end)
end)
