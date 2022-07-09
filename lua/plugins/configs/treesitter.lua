local col = require("core.lib").colors

local parser_config = require("nvim-treesitter.parsers").get_parser_configs()
parser_config.org = {
    install_info = {
        url = "https://github.com/milisims/tree-sitter-org",
        revision = "f110024d539e676f25b72b7c80b0fd43c34264ef",
        files = { "src/parser.c", "src/scanner.cc" },
    },
    filetype = "org",
}

require("nvim-treesitter.configs").setup({
    -- One of "all", "maintained" (parsers with maintainers), or a list of languages
    ensure_installed = "all",

    -- Install languages synchronously (only applied to `ensure_installed`)
    sync_install = true,

    -- List of parsers to ignore installing
    ignore_install = { "phpdoc" },

    highlight = {
        -- `false` will disable the whole extension
        enable = true,

        -- list of language that will be disabled
        disable = { "org" },

        -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
        -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
        -- Using this option may slow down your editor, and you may see some duplicate highlights.
        -- Instead of true it can also be a list of languages
        additional_vim_regex_highlighting = { "vim", "org" },
    },

    -- Incremental selection based on the named nodes from the grammar.
    incremental_selection = {
        enable = true,
        keymaps = {
            init_selection = "gnn",
            node_incremental = "grn",
            scope_incremental = "grc",
            node_decremental = "grm",
        },
    },

    -- Indentation based on treesitter for the = operator. NOTE: This is an experimental feature.
    indent = {
        enable = true,
    },

    rainbow = {
        enable = true,
        -- disable = { "jsx", "cpp" }, list of languages you want to disable the plugin for
        extended_mode = true, -- Also highlight non-bracket delimiters like html tags, boolean or table: lang -> boolean
        max_file_lines = nil, -- Do not enable for files with more than n lines, int
        colors = { col.skyblue, col.purple, col.white }, -- table of hex strings
        -- termcolors = {} -- table of colour name strings
    },
})
