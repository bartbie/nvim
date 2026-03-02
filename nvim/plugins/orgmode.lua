local joinpath = vim.fs.joinpath

local function exists(...)
    local parts = { ... }
    local path = vim.fn.expand(vim.fs.joinpath(unpack(parts)))
    return vim.fn.isdirectory(path) == 1 and path or nil
end

local folder = (
    exists("~/Eternal", "orgfiles")
    or exists("~/Eternal", "notes")
    or exists("~/", "orgfiles")
    or exists("~/", "notes")
)
local Menu = require("org-modern.menu")

require("orgmode").setup({
    org_agenda_files = joinpath(folder, "**/*"),
    org_default_notes_file = joinpath(folder, "/refile.org"),
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
                    --         separator = "➜",
                    --     },
                    -- }
                ):open(data)
            end,
        },
    },
})

require("org-super-agenda").setup({
    org_directories = { joinpath(folder, "**/*") },
})

-- Experimental
vim.lsp.enable("org")
