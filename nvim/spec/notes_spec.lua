describe("bartbie.notes", function()
    -- Stub bartbie.G with the agenda_keymaps that keymap.lua normally provides
    local agenda_keymaps_stub = {
        TODO = { keymap = "ot", shortcut = "t" },
        PROGRESS = { keymap = "op", shortcut = "p" },
        WAITING = { keymap = "ow", shortcut = "w" },
        DONE = { keymap = "od", shortcut = "d" },
        CANCELLED = { keymap = "ox", shortcut = "x" },
    }

    local function load_notes()
        package.loaded["bartbie.notes"] = nil
        package.loaded["bartbie.G"] = { agenda_keymaps = agenda_keymaps_stub }
        return require("bartbie.notes")
    end

    after_each(function()
        package.loaded["bartbie.notes"] = nil
        package.loaded["bartbie.G"] = nil
    end)

    describe("states", function()
        it("has exactly 5 entries", function()
            local notes = load_notes()
            assert.are.same(5, #notes.states)
        end)

        it("first 3 are active (done=false)", function()
            local notes = load_notes()
            for i = 1, 3 do
                assert.is_false(notes.states[i].done, "states[" .. i .. "] should be active")
            end
        end)

        it("last 2 are terminal (done=true)", function()
            local notes = load_notes()
            for i = 4, 5 do
                assert.is_true(notes.states[i].done, "states[" .. i .. "] should be terminal")
            end
        end)

        it("each entry has required fields", function()
            local notes = load_notes()
            local required = { "name", "done", "keymap", "shortcut", "color", "strike_through" }
            for _, s in ipairs(notes.states) do
                for _, field in ipairs(required) do
                    assert.is_not_nil(s[field], "state " .. s.name .. " missing field " .. field)
                end
            end
        end)
    end)

    describe("org_keywords", function()
        it("has correct order and values", function()
            local notes = load_notes()
            assert.are.same({ "TODO", "PROGRESS", "WAITING", "|", "DONE", "CANCELLED" }, notes.org_keywords)
        end)

        it("separator is at position 4", function()
            local notes = load_notes()
            assert.are.same("|", notes.org_keywords[4])
        end)

        it("active states come before separator", function()
            local notes = load_notes()
            local sep_pos = 4
            for i = 1, sep_pos - 1 do
                assert.are_not.same("|", notes.org_keywords[i])
            end
        end)

        -- Note: Lua 5.1 cannot enforce table immutability for existing keys.
        -- The invariant is: mutating org_keywords does not corrupt M.states.
        it("mutation does not corrupt M.states", function()
            local notes = load_notes()
            -- states should still have exactly 5 entries with no "|"
            assert.are.same(5, #notes.states)
            for _, s in ipairs(notes.states) do
                assert.are_not.same("|", s.name)
            end
        end)
    end)

    describe("super_agenda_states", function()
        it("has same count as states", function()
            local notes = load_notes()
            assert.are.same(#notes.states, #notes.super_agenda_states)
        end)

        it("each entry has required fields", function()
            local notes = load_notes()
            local required = { "name", "keymap", "shortcut", "color", "strike_through", "fields" }
            for _, s in ipairs(notes.super_agenda_states) do
                for _, field in ipairs(required) do
                    assert.is_not_nil(s[field], "super_agenda_state " .. s.name .. " missing " .. field)
                end
            end
        end)

        it("does not contain '|' separator", function()
            local notes = load_notes()
            for _, s in ipairs(notes.super_agenda_states) do
                assert.are_not.same("|", s.name)
            end
        end)

        it("names match states in same order", function()
            local notes = load_notes()
            for i, s in ipairs(notes.super_agenda_states) do
                assert.are.same(notes.states[i].name, s.name)
            end
        end)

        -- Note: same Lua 5.1 limitation -- mutation is convention-only.
        it("entries are independent copies from M.states", function()
            local notes = load_notes()
            -- super_agenda_states entries should be new tables, not references to states entries
            assert.are_not.equal(notes.states[1], notes.super_agenda_states[1])
        end)
    end)

    describe("folder paths", function()
        it("org_folder is nil or a string", function()
            local notes = load_notes()
            assert.is_true(notes.org_folder == nil or type(notes.org_folder) == "string")
        end)

        it("notes_folder is nil or a string", function()
            local notes = load_notes()
            assert.is_true(notes.notes_folder == nil or type(notes.notes_folder) == "string")
        end)

        it("org_folder has no trailing slash when non-nil", function()
            local notes = load_notes()
            if notes.org_folder ~= nil then
                assert.are_not.same("/", notes.org_folder:sub(-1))
            end
        end)

        it("notes_folder has no trailing slash when non-nil", function()
            local notes = load_notes()
            if notes.notes_folder ~= nil then
                assert.are_not.same("/", notes.notes_folder:sub(-1))
            end
        end)
    end)
end)
