local lib = require("lib")
local icons = lib.diagnostics_symbols

return {
    {
        "VonHeikemen/lsp-zero.nvim",
        event = { "BufReadPre", "BufNewFile" },
        branch = "v1.x",
        keys = {
            { "<leader>m", "<CMD>Mason<CR>", desc = "Mason" },
        },
        dependencies = {
            -- LSP Support
            { "neovim/nvim-lspconfig" }, -- Required
            { "williamboman/mason.nvim" }, -- Optional
            { "williamboman/mason-lspconfig.nvim" }, -- Optional

            -- Autocompletion
            { "hrsh7th/nvim-cmp" }, -- Required
            { "hrsh7th/cmp-nvim-lsp" }, -- Required
            { "hrsh7th/cmp-buffer" }, -- Optional
            { "hrsh7th/cmp-path" }, -- Optional
            { "saadparwaiz1/cmp_luasnip" }, -- Optional
            { "hrsh7th/cmp-nvim-lua" }, -- Optional
            { "hrsh7th/cmp-nvim-lsp-signature-help" },

            -- Snippets
            { "L3MON4D3/LuaSnip" }, -- Required
            { "rafamadriz/friendly-snippets" }, -- Optional
        },
        opts = {
            ensure_installed = {
                "vimls",
                "grammarly",
                "lua_ls",
                "rust_analyzer",
                "pyright",
                "eslint",
                "tsserver",
                "tailwindcss",
                "html",
                "jsonls",
            },
        },
        config = function(_, opts)
            local lsp = require("lsp-zero").preset({
                name = "minimal",
                set_lsp_keymaps = true,
                manage_nvim_cmp = true,
                suggest_lsp_servers = false,
            })

            local cmp_sources = lsp.defaults.cmp_sources()
            table.insert(cmp_sources, { name = "nvim_lsp_signature_help" })

            lsp.setup_nvim_cmp({ sources = cmp_sources })

            lsp.ensure_installed(opts.ensure_installed)
            -- (Optional) Configure lua language server for neovim
            lsp.nvim_workspace()

            lsp.setup()
        end,
    },
    {
        "glepnir/lspsaga.nvim",
        event = { "BufRead" },
        dependencies = {
            { "nvim-tree/nvim-web-devicons" },
            { "nvim-treesitter/nvim-treesitter" },
        },
        keys = {
            { "gh", "<cmd>Lspsaga lsp_finder<CR>", desc = "Find Definition & References" },
            { "gn", "<cmd>Lspsaga rename<CR>", desc = "Rename in File" },
            { "gN", "<cmd>Lspsaga rename ++project<CR>", desc = "Rename in Project" },
            { mode = { "n", "v" }, "<leader>ca", "<cmd>Lspsaga code_action<CR>", desc = "Actions" },
            { "gd", "<cmd>Lspsaga peek_definition<CR>", desc = "Peek Definition" },
            { "gt", "<cmd>Lspsaga peek_type_definition<CR>", desc = "Peek Type Definition" },
            { "gT", "<cmd>Lspsaga goto_type_definition<CR>", desc = "Go to Type Definition" },
            { "go", "<cmd>Lspsaga show_line_diagnostics<CR>", desc = "Show Line Diagnostics" },
            { "gk", "<cmd>Lspsaga diagnostic_jump_prev<CR>", desc = "Jump to Prev Diagnostic" },
            { "gj", "<cmd>Lspsaga diagnostic_jump_next<CR>", desc = "Jump to Next Diagnostic" },

            {
                "gK",
                function()
                    require("lspsaga.diagnostic"):goto_prev({ severity = vim.diagnostic.severity.ERROR })
                end,
                desc = "Jump to Prev Error",
            },
            {
                "gJ",
                function()
                    require("lspsaga.diagnostic"):goto_next({ severity = vim.diagnostic.severity.ERROR })
                end,
                desc = "Jump to Next Error",
            },
            { "K", "<cmd>Lspsaga hover_doc ++keep<CR>", desc = "Hover Documentation" },
            { "<leader>co", "<cmd>Lspsaga outline<CR>", desc = "Sorted Code Outline" },
            { "<Leader>ci", "<cmd>Lspsaga incoming_calls<CR>", desc = "Incoming Calls" },
            { "<Leader>co", "<cmd>Lspsaga outgoing_calls<CR>", desc = "Incoming Calls" },
        },
        opts = {
            symbol_in_winbar = {
                separator = "  ",
                hide_keyword = true,
                show_file = false,
            },
            ui = {
                expand = "",
                collapse = "",
                preview = " ",
                code_action = icons.action,
                diagnostic = icons.bug,
                incoming = " ",
                outgoing = " ",
                hover = " ",
            },
        },
    },
}
