local UTILS = require("bartbie.utils")
local LIB = UTILS.lib

return {
    {
        "rcarriga/nvim-notify",
        keys = {
            {
                "<leader>un",
                function()
                    require("notify").dismiss({ silent = true, pending = true })
                end,
                desc = "Delete all Notifications",
            },
        },
        opts = {
            timeout = 3000,
            max_height = function()
                return math.floor(vim.o.lines * 0.75)
            end,
            max_width = function()
                return math.floor(vim.o.columns * 0.75)
            end,
        },
    },
    {
        "stevearc/dressing.nvim",
        lazy = true,
        init = function()
            vim.ui.select = function(...)
                require("lazy").load({ plugins = { "dressing.nvim" } })
                return vim.ui.select(...)
            end
            vim.ui.input = function(...)
                require("lazy").load({ plugins = { "dressing.nvim" } })
                return vim.ui.input(...)
            end
        end,
    },
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        opts = {
            lsp = {
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.stylize_markdown"] = true,
                },
            },
            presets = {
                bottom_search = true,
                command_palette = true,
                long_message_to_split = true,
                inc_rename = true,
            },
        },
        config = function(_, opts)
            local noice = require("noice")
            noice.setup(opts)
            vim.lsp.handlers["textDocument/hover"] = noice.hover
            vim.lsp.handlers["textDocument/signatureHelp"] = noice.signature
        end,
    },
    {
        "akinsho/bufferline.nvim",
        event = "VeryLazy",
        version = "v3.*",
        dependencies = "nvim-tree/nvim-web-devicons",
        keys = {
            { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle pin" },
            { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete non-pinned buffers" },
        },
        opts = {
            options = {
                diagnostics = "nvim_lsp",
                diagnostics_indicator = function(_, _, diag)
                    local icons = LIB.diagnostics_symbols.core
                    local ret = (diag.error and icons.error .. diag.error .. " " or "")
                        .. (diag.warning and icons.warn .. diag.warning or "")
                    return vim.trim(ret)
                end,
                -- NOTE: this will be called a lot so don't do any heavy processing here
                custom_filter = function(buf_number)
                    local types = LIB.special_types
                    local filetype = vim.bo[buf_number].filetype
                    local bufname = vim.fn.bufname(buf_number)
                    local buftype = vim.bo[buf_number].buftype
                    return not (
                        vim.tbl_contains(types.filetypes, filetype)
                        or vim.tbl_contains(types.bufnames, bufname)
                        or vim.tbl_contains(types.buftypes, buftype)
                    )
                end,
                offsets = {
                    {
                        filetype = "neo-tree",
                        -- text = "Neo-tree",
                        text = "♪.ılılıll|̲̅̅●̲̅̅|̲̅̅=̲̅̅|̲̅̅●̲̅̅|llılılı.♪",
                        highlight = "Directory",
                        text_align = "center",
                    },
                },
                hover = {
                    enabled = true,
                    delay = 200,
                    reveal = { "close" },
                },
            },
        },
    },
}
