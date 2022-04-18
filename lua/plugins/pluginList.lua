local pluginList = {

    { 'sainnhe/sonokai' },

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
        },

        {
            'ms-jpq/coq.thirdparty',
            branch = '3p',
        },
    },


    { 'neovim/nvim-lspconfig' },

    { 'williamboman/nvim-lsp-installer' },

--    {
--        'nvim-orgmode/orgmode',
--        config = function()
--            require('orgmode').setup_setup_ts_grammar()
--        end
--    },

    {
        'nvim-telescope/telescope.nvim',
        requires = { 'nvim-lua/plenary.nvim' }
    },

    {
        'lewis6991/gitsigns.nvim',
        requires = { 'nvim-lua/plenary.nvim' },
        -- tag = 'release' -- To use the latest release
    },

    {
        'numToStr/Comment.nvim',
        config = function()
            require('Comment').setup()
        end
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
