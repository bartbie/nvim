local lib = require("lib")
local icons = lib.diagnostics_symbols
return {
    {
        "folke/tokyonight.nvim",
        lazy = false,
        priority = 1000,
        opts = {
            style = "night",
            -- style = "moon",
        },
        config = function(_, opts)
            local tokyonight = require("tokyonight")
            tokyonight.setup(opts)
            vim.cmd("colorscheme tokyonight")
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
            { "<leader>ff", "<CMD>Telescope find_files<CR>", desc = "Find File" },
            { "<leader>fg", "<CMD>Telescope live_grep<CR>", desc = "Grep Through Files" },
            { "<leader>fh", "<CMD>Telescope oldfiles<CR>", desc = "Find Recent Files" },
            { "<leader>fb", "<CMD>Telescope buffers<CR>", desc = "Find Buffer" },
            { "<leader>fd", "<CMD>Telescope help_tags<CR>", desc = "Find Documentation" },
            { "<leader>fm", "<CMD>Telescope marks<CR>", desc = "Find Bookmarks" },
            { "<leader>fw", "<CMD>Telescope current_buffer_fuzzy_find<CR>", desc = "Find Word In Buffer" },
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
    -- { "p00f/nvim-ts-rainbow" },
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
        event = { "BufReadPre", "BufNewFile" },
        opts = {
            current_line_blame = true,
            on_attach = function(buffer)
                local gs = package.loaded.gitsigns

                local map = function(mode, l, r, desc)
                    vim.keymap.set(mode, l, r, { buffer = buffer, desc = desc })
                end

                -- stylua: ignore start
                map("n", "]h", gs.next_hunk, "Next Hunk")
                map("n", "[h", gs.prev_hunk, "Prev Hunk")
                map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>", "Stage Hunk")
                map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>", "Reset Hunk")
                map("n", "<leader>ghS", gs.stage_buffer, "Stage Buffer")
                map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo Stage Hunk")
                map("n", "<leader>ghR", gs.reset_buffer, "Reset Buffer")
                map("n", "<leader>ghp", gs.preview_hunk, "Preview Hunk")
                map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame Line")
                map("n", "<leader>ghd", gs.diffthis, "Diff This")
                map("n", "<leader>ghD", function() gs.diffthis("~") end, "Diff This ~")
                map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "GitSigns Select Hunk")
                -- stylua: ignore end
            end,
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
    {
        "akinsho/toggleterm.nvim",
        version = "*",
        opts = {
            size = 20,
            open_mapping = [[<c-\>]],
            hide_numbers = true,
            shade_filetypes = {},
            shade_terminals = true,
            shading_factor = 2,
            start_in_insert = true,
            insert_mappings = true,
            persist_size = true,
            direction = "float",
            close_on_exit = true,
            shell = vim.o.shell,
            float_opts = {
                border = "curved",
                winblend = 0,
                highlights = {
                    border = "Normal",
                    background = "Normal",
                },
            },
        },
        -- TODO configure this
        -- config = function(_, opts)
        --     local toggleterm = require("toggleterm")
        --     local terminal = require("toggleterm.terminal").Terminal
        --
        --     -- creates new terminal object and returns a function that toggles it
        --     local function new_cmd(cmd)
        --         -- creates new terminal object
        --         local function new_term(cmd)
        --             return terminal:new({ cmd = cmd, hidden = true })
        --         end
        --
        --         local term = new_term(cmd)
        --         return function() term:toggle() end
        --     end
        --
        --     local python = new_cmd("python3")
        --     local lazygit = new_cmd("lazygit"),
        --
        --     toggleterm.setup(opts)
        -- end,
    },
    { "kevinhwang91/nvim-hlslens", config = true },
    {
        "glepnir/lspsaga.nvim",
        event = "BufRead",
        dependencies = {
            { "nvim-tree/nvim-web-devicons" },
            { "nvim-treesitter/nvim-treesitter" },
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
        -- config = function(_, opts)
        --     require("lspsaga").setup(opts)
        --     local keymap = vim.keymap.set
        -- end
    },
    {
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            plugin = { spelling = true },
            key_labels = {
                ["<leader>"] = "SPC",
                ["<cr>"] = "RET",
                ["<tab>"] = "TAB",
            },
        },
        config = function(_, opts)
            vim.o.timeout = true
            vim.o.timeoutlen = 300
            local wk = require("which-key")
            wk.setup(opts)
            wk.register({
                mode = { "n", "v" },
                ["g"] = { name = "+goto" },
                ["]"] = { name = "+next" },
                ["["] = { name = "+prev" },
                ["<leader>b"] = { name = "+buffer" },
                ["<leader>c"] = { name = "+code" },
                ["<leader>f"] = { name = "+file/find" },
                ["<leader>g"] = { name = "+git" },
                ["<leader>gh"] = { name = "+hunks" },
                ["<leader><tab>"] = { name = "+tabs" },
                -- ["<leader>q"] = { name = "+quit/session" },
                -- ["<leader>s"] = { name = "+search" },
                -- ["<leader>sn"] = { name = "+noice" },
                -- ["<leader>u"] = { name = "+ui" },
                ["<leader>w"] = { name = "+windows" },
                ["<leader>x"] = { name = "+diagnostics/quickfix" },
            })
        end,
    },
}
