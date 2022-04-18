local pluginList = {

    { 
        'sainnhe/sonokai',
        config = function()
            require("plugins.configs.theme")
        end
    },

    {
        'ms-jpq/chadtree',
        branch = 'chad',
        run = 'python3 -m chadtree deps',
        config = function()
            require("plugins.configs.filetree")
        end
    },

    { 'tpope/vim-fugitive' },

    {
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate',
        config = function()
            require("plugins.configs.treesitter")
        end,
    },

    {
        {
            'ms-jpq/coq_nvim',
            branch = 'coq',
        },

        {
            'ms-jpq/coq.artifacts',
            branch = 'artifacts',
            after = "coq_nvim",
        },

        {
            'ms-jpq/coq.thirdparty',
            branch = '3p',
            after = "coq_nvim",
            config = function()
                require("plugins.configs.autocompletion")
            end
        },
    },


    { 'neovim/nvim-lspconfig' },

    { 
        'williamboman/nvim-lsp-installer',
        after = {"nvim-lspconfig", "coq_nvim"},
        config = function()
            require("plugins.configs.lsp")
        end
    },

--    {
--        'nvim-orgmode/orgmode',
--        config = function()
--            require('orgmode').setup_setup_ts_grammar()
--        end
--    },

    {
        'nvim-telescope/telescope.nvim',
        requires = { 'nvim-lua/plenary.nvim' },
        config = function()
            require("plugins.configs.telescope")
        end
    },

    {
        'lewis6991/gitsigns.nvim',
        requires = { 'nvim-lua/plenary.nvim' },
        config = function()
            require("plugins.configs.gitsigns")
        end,
        -- tag = 'release' -- To use the latest release
    },

    {
        'numToStr/Comment.nvim',
        config = function()
            require('Comment').setup()
        end,
    },

    { 'tpope/vim-surround' },

    { 'tpope/vim-unimpaired' },

    { 'tpope/vim-repeat' },

    {
        'zegervdv/nrpattern.nvim',
        config = function()
            require"nrpattern".setup()
        end,
    },

    { "tpope/vim-dadbod" },

    { "kristijanhusak/vim-dadbod-ui" },

    { "kristijanhusak/vim-dadbod-completion" },

    { 'ggandor/lightspeed.nvim' },

    {
        "themercorp/themer.lua",
        disable = true,
        -- config = function()
        --     require("themer").setup({
        --         colorscheme = "tokyodark",
        --         styles = {
        --             ["function"] = { style = 'italic' },
        --             functionbuiltin = { style = 'italic' },
        --             variable = { style = 'italic' },
        --             variableBuiltIn = { style = 'italic' },
        --             parameter  = { style = 'italic' },
        --         },
        --     })
        -- end
    },
}

return pluginList
