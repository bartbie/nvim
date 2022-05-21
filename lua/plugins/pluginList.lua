local pluginList = {

    gruvbox = {
        'sainnhe/gruvbox-material',
        config = function()
            require("plugins.configs.gruvbox")
        end
    },

    nvim_tree = {
        'kyazdani42/nvim-tree.lua',
        requires = {
            'kyazdani42/nvim-web-devicons', -- optional, for file icon
        },
        tag = 'nightly', -- optional, updated every week. (see issue #1193)
        config = function()
            require("plugins.configs.nvimtree")
        end,
    },

    fugitive = { 'tpope/vim-fugitive' },

    treesitter = {
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate',
        config = function()
            require("plugins.configs.treesitter")
        end,
    },

    coq = {
        'ms-jpq/coq_nvim',
        branch = 'coq',
        {
            'ms-jpq/coq.artifacts',
            branch = 'artifacts',
        },

        {
            'ms-jpq/coq.thirdparty',
            branch = '3p',
            config = function()
                require("plugins.configs.coq")
            end
        },
    },

    lsp = {
        'williamboman/nvim-lsp-installer',
        after = {"coq_nvim"},
        {
            'neovim/nvim-lspconfig',
            config = function()
                require("plugins.configs.lsp")
            end
        },
    },

    telescope = {
        'nvim-telescope/telescope.nvim',
        requires = { 'nvim-lua/plenary.nvim' },
        config = function()
            require("plugins.configs.telescope")
        end
    },

    gitsigns = {
        'lewis6991/gitsigns.nvim',
        requires = { 'nvim-lua/plenary.nvim' },
        after = "vim-fugitive",
        config = function()
            require("plugins.configs.gitsigns")
        end,
        -- tag = 'release' -- To use the latest release
    },

    comment = {
        'numToStr/Comment.nvim',
        config = function()
            require('Comment').setup()
        end,
    },

    surround = { 'tpope/vim-surround' },

    unimpaired = { 'tpope/vim-unimpaired' },

    vim_repeat = { 'tpope/vim-repeat' },

    nrpattern = {
        'zegervdv/nrpattern.nvim',
        config = function()
            require"nrpattern".setup()
        end,
    },

    dadbot = { "tpope/vim-dadbod" },

    dadbot_ui = { "kristijanhusak/vim-dadbod-ui", after = { "vim-dadbod", "vim-dadbod-completion" } },

    dadbot_autocompletion = { "kristijanhusak/vim-dadbod-completion", after = "vim-dadbod", },

    lightspeed = { 'ggandor/lightspeed.nvim' },

    themer = {
        "themercorp/themer.lua",
    },

    indent_blackline = {
        "lukas-reineke/indent-blankline.nvim",
        config = function()
            require("plugins.configs.indent_blackline")
        end,
    }
}

return pluginList
