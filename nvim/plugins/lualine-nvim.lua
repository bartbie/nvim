local theme = require("lualine.themes.auto")
local symbols = require("bartbie.symbols")
local os = require("bartbie.os")

for _, mode in ipairs(vim.tbl_keys(theme)) do
    -- theme[mode].b.bg = theme.normal.c.bg
    theme[mode].b = theme.normal.c
end

local function get_curr_mode()
    return require("lualine.highlight").get_mode_suffix():gsub("_", "")
end

local function color_text(_)
    return { fg = theme[get_curr_mode()].a.bg }
end

---create simple extention
---@param filetypes string[]
---@param text function | string | nil
---@param rest? table | nil
---@return table
local function create_extention(filetypes, text, rest)
    local lualine_a = { { "mode" } }
    if text then
        lualine_a[1].fmt = type(text) == "function" and text or function()
            return text
        end
    end
    lualine_a[1] = vim.tbl_extend("force", lualine_a[1], rest or {})
    -- vim.notify(vim.inspect(lualine_a))
    return {
        filetypes = filetypes,
        sections = {
            lualine_a = lualine_a,
            lualine_b = { { "branch", color = color_text } },
        },
    }
end

-- local function get_short_cwd()
--     return vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
-- end

require("lualine").setup({
    options = {
        theme = function()
            return theme
        end,
        globalstatus = true,
        disabled_filetypes = { statusline = { "dashboard", "alpha" } },
        component_separators = { left = "", right = "" },
        section_separators = { left = "", right = "" },
    },
    sections = {
        lualine_a = { "mode" },
        lualine_b = {
            { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
            {
                "filename",
                path = 1,
                symbols = { modified = "", readonly = "✘", unnamed = "", new = "" },
            },
        },
        lualine_c = {
            {
                "branch",
                color = color_text,
            },
            {
                "diff",
                source = function()
                    local gitsigns = vim.b.gitsigns_status_dict
                    if gitsigns then
                        return {
                            added = gitsigns.added,
                            modified = gitsigns.changed,
                            removed = gitsigns.removed,
                        }
                    end
                end,
            },
        },

        lualine_x = {
            { "diagnostics", symbols = symbols.diagnostics },
            --- lsp server display
            {
                --- lsp icon
                "filetype",
                icon_only = true,
                separator = "",
                padding = { left = 1, right = 0 },
                cond = function()
                    local no_clients = next(vim.lsp.get_clients({ bufnr = 0 })) == nil
                    return not no_clients
                end,
            },
            {
                --- lsp names
                padding = { left = 0, right = 1 },
                function(_, _)
                    local servers = {}
                    local buf_clients = vim.lsp.get_clients({ bufnr = 0 })
                    for _, client in ipairs(buf_clients) do
                        table.insert(servers, client.name)
                    end
                    return table.concat(servers, " ")
                end,
            },
        },
        lualine_y = {
            { "encoding", fmt = string.upper },
            {
                "fileformat",
                symbols = {
                    unix = os.is_macos and "" or "",
                    dos = "",
                    mac = "",
                },
                padding = { left = 1, right = 0 },
                color = color_text,
            },
            {
                "fileformat",
                symbols = {
                    unix = "UNIX",
                    dos = "DOS",
                    mac = "MAC",
                },
                padding = { left = 0, right = 1 },
            },
            "progress",
            "selectioncount",
        },
        lualine_z = {
            {
                "location",
                fmt = function(str, _)
                    return " " .. vim.trim(str) .. " "
                end,
            },
        },
    },
    extensions = {
        -- "lazy",
        "fugitive",
        "man",
        -- "neo-tree",
        -- "nvim-dap-ui",
        -- "quickfix",
        -- "symbols-outline",
        -- "toggleterm",
        -- "trouble",
        "fzf",
        "oil",

        -- create_extention({ "fzf" }, "Fzf", {
        --     color = function()
        --         local mode = get_curr_mode()
        --         return mode == "command" and theme.normal.a or theme[mode].a
        --     end,
        -- }),
        create_extention({ "undotree" }, "Undo-tree"),
        create_extention({ "diff" }, "Undo-tree"),
        -- create_extention({ "Outline" }, "Outline"),
        -- create_extention({ "neo-tree" }, get_short_cwd),
    },
})
