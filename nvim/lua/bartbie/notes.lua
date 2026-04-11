local joinpath = vim.fs.joinpath

local function exists(...)
    local path = vim.fn.expand(joinpath(...))
    return vim.fn.isdirectory(path) == 1 and path or nil
end

local M = {}

M.org_folder = exists("~/Eternal/orgfiles") or exists("~/Eternal/notes") or exists("~/orgfiles") or exists("~/notes")

M.notes_folder = exists("~/Eternal/notes") or exists("~/notes")

local states = {
    { name = "TODO", done = false, color = "#FF5D62", strike_through = false },
    { name = "PROGRESS", done = false, color = "#FF9E3B", strike_through = false },
    { name = "WAITING", done = false, color = "#957FB8", strike_through = false },
    { name = "DONE", done = true, color = "#98BB6C", strike_through = true },
    { name = "CANCELLED", done = true, color = "#727169", strike_through = true },
}

-- computed on first access
setmetatable(M, {
    __index = function(t, k)
        if k == "states" then
            local agenda_keymaps = require("bartbie.G").agenda_keymaps
            for idx, state in ipairs(states) do
                states[idx] = vim.tbl_extend("error", state, agenda_keymaps[state.name])
            end
            local v = states
            rawset(t, k, v)
            return v
        elseif k == "super_agenda_states" then
            local fields = { "filename", "todo", "headline", "priority", "date", "tags" }
            local v = vim.tbl_map(function(s)
                return {
                    name = s.name,
                    keymap = s.keymap,
                    shortcut = s.shortcut,
                    color = s.color,
                    strike_through = s.strike_through,
                    fields = fields,
                }
            end, t.states)
            rawset(t, k, v)
            return v
        -- org_todo_keywords format: { "TODO", "PROGRESS", "WAITING", "|", "DONE", "CANCELLED" }
        elseif k == "org_keywords" then
            local v = {}
            for _, s in ipairs(M.states) do
                if not s.done then
                    table.insert(v, s.name)
                end
            end
            table.insert(v, "|")
            for _, s in ipairs(M.states) do
                if s.done then
                    table.insert(v, s.name)
                end
            end
            rawset(t, k, v)
            return v
        end
    end,
})

-- warn if orgmode is installed but no org folder was found
if not M.org_folder then
    vim.schedule(function()
        if pcall(require, "orgmode") then
            vim.notify(
                "bartbie.notes: orgmode installed but no org folder found"
                    .. " (checked ~/Eternal/orgfiles, ~/Eternal/notes, ~/orgfiles, ~/notes)",
                vim.log.levels.WARN
            )
        end
    end)
end

return M
