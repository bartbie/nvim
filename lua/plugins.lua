local lib = require("lib")
local y = function(x)
    return x
end

return {
    {
        "sainnhe/gruvbox-material",
        config = function()
            local o = vim.o
            local g = vim.g

            o.background = "dark"
            g.gruvbox_material_background = "hard"
            g.gruvbox_material_palette = "original"

            g.gruvbox_material_disable_italic_comment = 0
            g.gruvbox_material_enable_bold = 1
            g.gruvbox_material_enable_italic = 1
            g.gruvbox_material_cursor = "auto"
            g.gruvbox_material_transparent_background = 0
            -- g.gruvbox_material_visual = "grey background"
            -- g.gruvbox_material_selection_background = "grey"
            g.gruvbox_material_sign_column_background = "none"
            g.gruvbox_material_spell_foreground = "none"
            g.gruvbox_material_ui_contrast = "low"
            g.gruvbox_material_show_eob = 0
            g.gruvbox_material_diagnostic_text_highlight = 0
            g.gruvbox_material_diagnostic_line_highlight = 1
            g.gruvbox_material_diagnostic_virtual_text = 1
            g.gruvbox_material_current_word = "grey background"
            g.gruvbox_material_disable_terminal_colors = 0
            g.gruvbox_material_statusline_style = "original"
            g.gruvbox_material_lightline_disable_bold = 0
            vim.cmd("colorscheme gruvbox-material")
        end,
    },
    {
        "nvim-neo-tree/neo-tree.nvim",
        keys = {
            { "<leader>n", "<cmd>Neotree toggle<cr>", desc = "NeoTree" },
        },
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
        },
    },
    {
        "nvim-treesitter/nvim-treesitter",
        build = ":TSUpdate",
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            auto_install = true,
            ensure_installed = {
                "bash",
                "vim",
                "help",
                "html",
                "lua",
                "json",
                "rust",
                "python",
                "c",
                "cpp",
                "javascript",
                "typescript",
                "tsx",
                "java",
                "toml",
                "markdown",
                "markdown_inline",
                "yaml",
                "query",
            },
            highlight = {
                enable = true,
                additional_vim_regex_highlighting = false,
            },
            indent = { enable = true },
            incremental_selection = {
                enable = true,
                keymaps = {
                    init_selection = "gnn",
                    node_incremental = "grn",
                    scope_incremental = "grc",
                    node_decremental = "grm",
                },
            },

            rainbow = {
                enable = true,
                -- disable = { "jsx", "cpp" }, list of languages you want to disable the plugin for
                extended_mode = true, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
                max_file_lines = nil, -- Do not enable for files with more than n lines, int
                --				colors = { col.skyblue, col.purple, col.white }, -- table of hex strings
                -- termcolors = {} -- table of colour name strings
            },
        },
        config = function(_, opts)
            require("nvim-treesitter.configs").setup(opts)
        end,
    },
    {
        "tpope/vim-fugitive",
        keys = {
            { "<leader>gg", "<CMD>Git<CR>", desc = "Open Status Menu" },
            { "<leader>gc", "<CMD>Git commit<CR>", desc = "Commit" },
        },
    },
    {
        "nvim-telescope/telescope.nvim",
        dependencies = {
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
            },
        },
        keys = {
            { "<leader>ff", "<CMD>Telescope find_files<CR>", "Find File" },
            { "<leader>fg", "<CMD>Telescope live_grep<CR>", "Grep Through Files" },
            { "<leader>fh", "<CMD>Telescope oldfiles<CR>", "Find Recent Files" },
            { "<leader>fb", "<CMD>Telescope buffers<CR>", "Find Buffer" },
            { "<leader>fd", "<CMD>Telescope help_tags<CR>", "Find Documentation" },
            { "<leader>fm", "<CMD>Telescope marks<CR>", "Find Bookmarks" },
            { "<leader>fw", "<CMD>Telescope current_buffer_fuzzy_find<CR>", "Find Word In Buffer" },
        },
        config = function()
            local ts = require("telescope")
            ts.setup({})

            local fzf, _ = pcall(require, "fzf_lib")
            if fzf then
                ts.load_extension("fzf")
            end

            local extensions = {}
            for _, v in ipairs(extensions) do
                ts.load_extension(v)
            end
        end,
    },
    {
        "VonHeikemen/lsp-zero.nvim",
        branch = "v1.x",
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
        "windwp/nvim-autopairs",
        config = function()
            require("nvim-autopairs").setup({})
            local cmp_autopairs = require("nvim-autopairs.completion.cmp")
            local cmp = require("cmp")
            cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
        end,
        dependencies = {
            { "hrsh7th/nvim-cmp" },
        },
    },
    { "p00f/nvim-ts-rainbow" },
    { "numToStr/Comment.nvim", config = true },
    {
        "petertriho/nvim-scrollbar",
        config = true,
    },
    {
        "folke/trouble.nvim",
        dependencies = { "nvim-tree/nvim-web-devicons" },
        opts = {
            signs = {
                error = lib.diagnostics_symbols.error,
                warning = lib.diagnostics_symbols.warning,
                hint = lib.diagnostics_symbols.hint,
                information = lib.diagnostics_symbols.info,
                other = lib.diagnostics_symbols.otehr,
            },
        },
    },
    {
        "lewis6991/gitsigns.nvim",
        opts = {
            current_line_blame = true,
        },
    },
    { "tpope/vim-unimpaired" },
    { "tpope/vim-repeat" },
    {
        "lukas-reineke/indent-blankline.nvim",
        opts = {
            use_treesitter = true,
            show_end_of_line = true,
            show_current_context = true,
            show_current_context_start = true,
            -- char_blankline = '┆',
            -- space_char_blankline = "",
            show_trailing_blankline_indent = false,
            show_first_indent_level = false,
            filetype_exclude = {
                "lspinfo",
                "packer",
                "checkhealth",
                "help",
                "man",
                "fugitive",
                "",
            },
        },
        config = function(_, opts)
            vim.opt.list = true
            vim.opt.listchars:append("eol:↴")
            require("indent_blankline").setup(opts)
        end,
    },
}
