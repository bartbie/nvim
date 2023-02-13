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

            --            rainbow = {
            --                enable = true,
            --                -- disable = { "jsx", "cpp" }, list of languages you want to disable the plugin for
            --                extended_mode = true, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
            --                max_file_lines = nil, -- Do not enable for files with more than n lines, int
            --                --				colors = { col.skyblue, col.purple, col.white }, -- table of hex strings
            --                -- termcolors = {} -- table of colour name strings
            --            },
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
}
