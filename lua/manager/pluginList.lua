local pluginList = {

    'sainnhe/sonokai',

    {
        "ms-jpq/chadtree",
        branch = "chad",
        run = "python3 -m chadtree deps"
    },
    
    'tpope/vim-fugitive',

    {        
        'nvim-treesitter/nvim-treesitter',
	run = ':TSUpdate'
    }
}

return pluginList
