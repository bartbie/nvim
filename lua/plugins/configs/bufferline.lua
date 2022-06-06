local lib = require("core.lib")
local icons = lib.diagnostics_symbols

local filetypes = lib.special_types.filetypes
local buftypes = lib.special_types.buftypes
local bufnames = lib.special_types.bufnames
local function check(tbl, value)
    return vim.tbl_contains(tbl, value)
end

require("bufferline").setup({
    options = {
        mode = "buffers", -- set to "tabs" to only show tabpages instead
        numbers = "ordinal",
        close_command = "bdelete! %d", -- can be a string | function, see "Mouse actions"
        right_mouse_command = "bdelete! %d", -- can be a string | function, see "Mouse actions"
        left_mouse_command = "buffer %d", -- can be a string | function, see "Mouse actions"
        middle_mouse_command = nil, -- can be a string | function, see "Mouse actions"
        max_name_length = 18,
        max_prefix_length = 15, -- prefix used when a buffer is de-duplicated
        tab_size = 18,
        diagnostics = "nvim_lsp",
        diagnostics_update_in_insert = false,
        -- show overall count and level of the highest (i.e. 3 errors and 2 warnings displayed as 5 errors)
        -- diagnostics_indicator = function(count, level, diagnostics_dict, context)
        --     local icon = level:match("error") and icons.error or icons.warn
        --     return " " .. icon .. " " .. count
        -- end,
        -- show count for each level (without hints)
        diagnostics_indicator = function(count, level, diagnostics_dict, context)
            local s = " "
            for e, n in pairs(diagnostics_dict) do
                local sym = e == "error" and icons.error or (e == "warning" and icons.warn or icons.info)
                s = s .. n .. sym
            end
            return s
        end,
        -- NOTE: this will be called a lot so don't do any heavy processing here
        custom_filter = function(buf_number, buf_numbers)
            local filetype = vim.bo[buf_number].filetype
            local bufname = vim.fn.bufname(buf_number)
            local buftype = vim.bo[buf_number].buftype
            return not (check(filetypes, filetype) or check(bufnames, bufname) or check(buftypes, buftype))
        end,
        offsets = {
            {
                filetype = "NvimTree",
                text = "file explorer",
                text_align = "left",
            },
        },
        color_icons = true,
        show_buffer_icons = true,
        show_buffer_close_icons = true,
        show_buffer_default_icon = true,
        show_close_icon = true,
        show_tab_indicators = true,
        persist_buffer_sort = true, -- whether or not custom sorted buffers should persist
        -- can also be a table containing 2 custom separators
        -- [focused and unfocused]. eg: { '|', '|' }
        separator_style = "thick",
        enforce_regular_tabs = false,
        always_show_bufferline = false,
        sort_by = "id",
    },
})
