local opts = {
        highlight = {
            enable = true,
            additional_vim_regex_highlighting = false,
        },
        indent = {
            enable = true,
        },
        incremental_selection = {
            enable = true,
            keymaps = require("bartbie.G").incremental_selection,
        },
    sync_install = false,
    auto_install = false,
}

require("nvim-treesitter.configs").setup(opts)
