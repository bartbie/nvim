local icons = require("bartbie.utils.lib").diagnostics_symbols
local diffview_opened = false

return {
    {
        "nvim-neo-tree/neo-tree.nvim",
        cmd = "Neotree",
        keys = {
            { "<leader>n", "<cmd>Neotree toggle<cr>", desc = "NeoTree" },
        },
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-tree/nvim-web-devicons",
            "MunifTanjim/nui.nvim",
        },
        opts = {
            filesystem = {
                hijack_netrw_behavior = "open_current",
            },
        },
        deactivate = function()
            vim.cmd([[Neotree close]])
        end,
        branch = "v3.x",
        init = function()
            vim.g.neo_tree_remove_legacy_commands = 1
            if vim.fn.argc() == 1 then
                local stat = vim.loop.fs_stat(vim.fn.argv(0))
                if stat and stat.type == "directory" then
                    vim.g.loaded_netrwPlugin = 1
                    vim.g.loaded_netrw = 1
                    require("neo-tree")
                end
            end
        end,
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
                -- "help",
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
        cmd = { "Git", "G" },
        keys = {
            {
                "<leader>gg",
                function()
                    local cmd = vim.bo.filetype == "fugitive" and "q" or "Git"
                    vim.cmd(cmd)
                end,
                desc = "Open Git Menu",
            },
            { "<leader>gC", "<CMD>Git commit<CR>", desc = "Commit Staged Files" },
            { "<leader>gp", "<CMD>Git pull<CR>", desc = "Pull changes" },
            { "<leader>gP", "<CMD>Git push<CR>", desc = "Push changes" },
        },
    },
    {
        "nvim-telescope/telescope.nvim",
        cmd = "Telescope",
        dependencies = {
            {
                "nvim-telescope/telescope-fzf-native.nvim",
                build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
            },
        },
        keys = {
            { "<leader>,", "<cmd>Telescope buffers show_all_buffers=true<cr>", desc = "Switch Buffer" },
            { "<leader>:", "<cmd>Telescope command_history<cr>", desc = "Command History" },
            -- find
            { "<leader>ff", "<CMD>Telescope find_files<CR>", desc = "Find Files" },
            { "<leader>fh", "<CMD>Telescope oldfiles<CR>", desc = "Find Recent Files" },
            { "<leader>fb", "<CMD>Telescope buffers show_all_buffers=true<CR>", desc = "Buffers" },
            -- search
            { "<leader>sg", "<CMD>Telescope live_grep<CR>", desc = "Grep" },
            { "<leader>sw", "<CMD>Telescope current_buffer_fuzzy_find<CR>", desc = "Buffer" },
            { "<leader>sd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
            { "<leader>sh", "<cmd>Telescope help_tags<cr>", desc = "Help Pages" },
            { "<leader>sk", "<cmd>Telescope keymaps<cr>", desc = "Key Maps" },
            { "<leader>sm", "<cmd>Telescope marks<cr>", desc = "Jump to Mark" },
            { "<leader>so", "<cmd>Telescope vim_options<cr>", desc = "Options" },
            -- git
            { "<leader>gc", "<cmd>Telescope git_commits<CR>", desc = "commits" },
            { "<leader>gs", "<cmd>Telescope git_status<CR>", desc = "status" },
        },
        ---@class TelescopeOpts
        opts = {
            extensions = {
                "harpoon",
            },
        },
        ---@param opts TelescopeOpts
        config = function(_, opts)
            local ts = require("telescope")
            ts.setup({})
            local fzf, _ = pcall(require, "fzf_lib")
            if fzf then
                ts.load_extension("fzf")
            end

            for k, v in pairs(opts.extensions) do
                ts.load_extension(type(k) == "number" and v or k)
            end
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
        keys = {
            { "<leader>xx", "<CMD>TroubleToggle<cr>", desc = "Toggle Menu" },
            { "<leader>xw", "<CMD>TroubleToggle workspace_diagnostics<cr>", desc = "Toggle Menu For Workspace" },
            { "<leader>xd", "<CMD>TroubleToggle document_diagnostics<cr>", desc = "Toggle Menu For Single File" },
            { "<leader>xl", "<CMD>TroubleToggle loclist<cr>", desc = "Show Location List" },
            { "<leader>xq", "<CMD>TroubleToggle quickfix<cr>", desc = "Show QuickFix List" },
        },
        opts = {
            signs = {
                error = icons.core.error,
                warning = icons.core.warning,
                hint = icons.core.hint,
                information = icons.core.info,
                --
                other = icons.rest.other,
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
        --- @type ibl.config
        opts = {
            indent = {
                char = "│",
                highlight = {
                    -- "IblCyan",
                    -- "IblViolet",
                    "IblBlue",
                    "IblAqua",
                    "IblGreen",
                    "IblYellow",
                    "IblOrange",
                    "IblRed",
                },
            },
            exclude = {
                filetypes = {
                    "",
                    -- "TelescopePrompt",
                    -- "TelescopeResults",
                    "checkhealth",
                    "fugitive",
                    "gitcommit",
                    "help",
                    "lspinfo",
                    "man",
                    "packer",
                },
            },
        },
        config = function(_, opts)
            vim.opt.list = true
            vim.opt.listchars:append("eol:↴")
            require("ibl").setup(opts)
            local hooks = require("ibl.hooks")
            hooks.register(hooks.type.WHITESPACE, hooks.builtin.hide_first_space_indent_level)
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
        "folke/which-key.nvim",
        event = "VeryLazy",
        opts = {
            plugin = { spelling = true },
            key_labels = {
                ["<leader>"] = "SPC",
                ["<cr>"] = "RET",
                ["<tab>"] = "TAB",
            },
            layout = {
                align = "center",
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
                -- ["<leader><tab>"] = { name = "+tabs" },
                ["<leader>q"] = { name = "+quit/session" },
                ["<leader>s"] = { name = "+search" },
                ["<leader>h"] = { name = "+harpoon" },
                -- ["<leader>sn"] = { name = "+noice" },
                ["<leader>o"] = { name = "+ui options" },
                ["<leader>of"] = { name = "+formatting options" },
                ["<leader>w"] = { name = "+windows" },
                ["<leader>x"] = { name = "+diagnostics/quickfix" },
            })
        end,
    },
    {
        "ggandor/flit.nvim",
        keys = function()
            local ret = {}
            for _, key in ipairs({ "f", "F", "t", "T" }) do
                ret[#ret + 1] = { key, mode = { "n", "x", "o" }, desc = key }
            end
            return ret
        end,
        opts = { labeled_modes = "nx" },
    },
    {
        "ggandor/leap.nvim",
        keys = {
            { "S", mode = { "n", "x", "o" }, desc = "Leap backward to" },
            { "gs", mode = { "n", "x", "o" }, desc = "Leap from windows" },
            { "s", "<Plug>(leap-forward-to)", mode = { "n", "x", "o" }, desc = "Leap forward to" },
            { "<leader>ss", "<Plug>(leap-forward-to)", mode = { "n", "x", "o" }, desc = "Leap forward to" },
        },
        config = function(_, opts)
            local leap = require("leap")
            for k, v in pairs(opts) do
                leap.opts[k] = v
            end
            leap.add_default_mappings()
            vim.keymap.del({ "x", "o" }, "x")
            vim.keymap.del({ "x", "o" }, "X")
        end,
    },
    {
        "folke/todo-comments.nvim",
        cmd = { "TodoTrouble", "TodoTelescope" },
        event = { "BufReadPost", "BufNewFile" },
        opts = {
            highlight = {
                keyword = "bg",
                pattern = {
                    [[.*<(KEYWORDS)\s*:]],
                    [[.*<(KEYWORDS)\s*]],
                },
            },
            search = {
                pattern = [[\b(KEYWORDS)\b]],
            },
        },
        keys = {
            -- stylua: ignore start
            {
                "]t",
                function()
                    require("todo-comments").jump_next()
                end,
                desc = "Next todo comment",
            },
            {
                "[t",
                function()
                    require("todo-comments").jump_prev()
                end,
                desc = "Previous todo comment",
            },
            -- stylua: ignore end
            { "<leader>xt", "<cmd>TodoTrouble<cr>", desc = "Todo (Trouble)" },
            { "<leader>xT", "<cmd>TodoTrouble keywords=TODO,FIX,FIXME<cr>", desc = "Todo/Fix/Fixme (Trouble)" },
            { "<leader>st", "<cmd>TodoTelescope<cr>", desc = "Todo" },
        },
    },
    {
        "sindrets/diffview.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        keys = {
            {
                "<leader>gd",
                desc = "Open diff menu",
                function()
                    if not diffview_opened then
                        vim.cmd("DiffviewOpen")
                        diffview_opened = true
                    else
                        vim.cmd("DiffviewClose")
                        diffview_opened = false
                    end
                end,
            },
        },
    },
    {
        "ThePrimeagen/harpoon",
        keys = {
            { "<leader>hh", "<cmd>Telescope harpoon marks<CR>", desc = "Open list" },
            {
                "<leader>ha",
                function()
                    require("harpoon.mark").add_file()
                end,
                desc = "Add file",
            },
            {
                "<leader>hr",
                function()
                    require("harpoon.mark").rm_file()
                end,
                desc = "Remove file",
            },
        },
        config = true,
    },
    {
        "mbbill/undotree",
        keys = {
            { "<leader>u", "<CMD>UndotreeToggle<CR>", desc = "undotree" },
        },
    },
    {
        "folke/zen-mode.nvim",
        config = true,
        keys = {
            { "<leader>z", "<CMD>ZenMode<CR>", desc = "zen-mode" },
        },
    },
    {
        "norcalli/nvim-colorizer.lua",
        config = function(_, opts)
            require("colorizer").setup()
        end,
    },
    {
        "nvim-treesitter/playground",
    },
}
