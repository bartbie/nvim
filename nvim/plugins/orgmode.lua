local joinpath = vim.fs.joinpath
local notes = require("bartbie.notes")
local BG = require("bartbie.G")
local org_folder = notes.org_folder

if not org_folder then
    return
end

local Menu = require("org-modern.menu")

local inbox_path = joinpath(org_folder, "inbox.org")

require("orgmode").setup({
    org_agenda_files = joinpath(org_folder, "**/*"),
    org_default_notes_file = inbox_path,
    org_todo_keywords = notes.org_keywords,
    org_archive_location = joinpath(org_folder, "archive", "%s_archive::"),
    org_capture_templates = {
        t = { description = "Task", template = "* TODO %?\n  %u", target = inbox_path },
        n = { description = "Note", template = "* %?\n  %u", target = inbox_path },
    },
    mappings = BG.org_mappings,
    ui = {
        menu = {
            handler = function(data)
                Menu:new(
                    -- {
                    --     window = {
                    --         margin = { 1, 0, 1, 0 },
                    --         padding = { 0, 1, 0, 1 },
                    --         title_pos = "center",
                    --         border = "single",
                    --         zindex = 1000,
                    --     },
                    --     icons = {
                    --         separator = "->",
                    --     },
                    -- }
                ):open(data)
            end,
        },
    },
})

local function is_not_done(i)
    return i.todo_state ~= "DONE" and i.todo_state ~= "CANCELLED"
end

local function is_done(i)
    return not is_not_done(i)
end

local function is_sched_today(i)
    return i.scheduled and i.scheduled:is_today()
end

local function is_sched_tomorrow(i)
    return i.scheduled and i.scheduled:days_from_today() == 1
end

local function is_sched_past(i)
    return i.scheduled and i.scheduled:is_past()
end
local function is_deadl_past(i)
    return i.deadline and i.deadline:is_past()
end

local function is_sched_this_week(i)
    local d2 = i.scheduled and i.scheduled:days_from_today()
    return (d2 and d2 >= 0 and d2 <= 7)
end

local function is_deadl_this_week(i)
    local d1 = i.deadline and i.deadline:days_from_today()
    return (d1 and d1 >= 0 and d1 <= 7)
end

local function in_inbox(i)
    return i.file and i.file:find("inbox") ~= nil
end

local function is_backlog(i)
    return is_not_done(i) and not i.scheduled and not i.deadline
end

local function is_overdue(i)
    return is_not_done(i) and (is_deadl_past(i) or is_sched_past(i))
end

require("org-super-agenda").setup({
    org_directories = { org_folder },
    todo_states = notes.super_agenda_states,
    keymaps = BG.org_super_agenda_mappings,

    hide_empty_groups = false,
    allow_duplicates = true,

    groups = {
        {
            name = "Overdue",
            matcher = function(i)
                return is_overdue(i)
            end,
            sort = { by = "date_nearest", order = "asc" },
        },
        {
            name = "Deadline",
            matcher = function(i)
                return is_not_done(i) and i.deadline and (not is_deadl_past(i))
            end,
            sort = { by = "date_nearest", order = "asc" },
        },
        {
            name = "Today",
            matcher = function(i)
                return is_not_done(i) and is_sched_today(i)
            end,
            sort = { by = "scheduled_time", order = "asc" },
        },
        {
            name = "In Progress",
            matcher = function(i)
                return i.todo_state == "PROGRESS"
            end,
        },
        {
            name = "Waiting",
            matcher = function(i)
                return i.todo_state == "WAITING"
            end,
        },
        {
            name = "Tomorrow",
            matcher = function(i)
                return is_not_done(i) and is_sched_tomorrow(i)
            end,
            sort = { by = "scheduled_time", order = "asc" },
        },
        {
            name = "This Week",
            matcher = function(i)
                return is_not_done(i) and (is_deadl_this_week(i) or is_sched_this_week(i))
            end,
            sort = { by = "date_nearest", order = "asc" },
        },
        {
            name = "Upcoming",
            matcher = function(i)
                return is_not_done(i) and (not is_backlog(i)) and (not is_overdue(i))
            end,
            sort = { by = "date_nearest", order = "asc" },
        },
        {
            name = "Inbox",
            matcher = function(i)
                return is_backlog(i) and in_inbox(i)
            end,
        },
        {
            name = "Backlog",
            matcher = function(i)
                return is_backlog(i)
            end,
        },
    },
})

-- Experimental
vim.lsp.enable("org")
