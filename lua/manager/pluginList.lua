local pluginList = {

    'sainnhe/sonokai',

    {
        'ms-jpq/chadtree',
        branch = 'chad',
        run = 'python3 -m chadtree deps'
    },
    
    'tpope/vim-fugitive',

    {        
        'nvim-treesitter/nvim-treesitter',
        run = ':TSUpdate'
    },

    {
        'ms-jpq/coq_nvim',
        branch = 'coq'
    },

    {
        'ms-jpq/coq.artifacts',
        branch = 'artifacts'
    },

    {
        'ms-jpq/coq.thirdparty',
        branch = '3p'
    },

    'neovim/nvim-lspconfig',
    
    'williamboman/nvim-lsp-installer',
    
    {
        'nvim-orgmode/orgmode',
        config = function()
            require('orgmode').setup{}
        end
    },

    {
        'nvim-telescope/telescope.nvim',
        requires = { 'nvim-lua/plenary.nvim' }
    },

}

return pluginList
