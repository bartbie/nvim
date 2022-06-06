local signs = require("core.visuals").diagnostics_symbols

require("nvim-tree").setup({
    hijack_unnamed_buffer_when_opening = true,
    open_on_setup = true,
    open_on_setup_file = true,
    open_on_tab = false,
    sort_by = "extension",
    view = {
        side = "left",
        number = false,
        relativenumber = false,
        signcolumn = "yes",
        mappings = {
            custom_only = false,
            list = {
                -- user mappings go here
            },
        },
    },
    renderer = {
        indent_markers = {
            enable = true,
        },
        icons = {
            webdev_colors = true,
            git_placement = "after",
        },
    },
    diagnostics = {
        enable = true,
        show_on_dirs = false,
        icons = {
            error = signs.error,
            warning = signs.warn,
            hint = signs.hint,
            info = signs.info,
        },
    },
    filters = {
        dotfiles = false,
        custom = { ".DS_Store" },
        exclude = {},
    },
    actions = {
        open_file = {
            quit_on_open = false,
            resize_window = false,
            window_picker = {
                enable = true,
                chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890",
                exclude = {
                    filetype = { "notify", "packer", "qf", "diff", "fugitive", "fugitiveblame" },
                    buftype = { "nofile", "terminal", "help" },
                },
            },
        },
    },
    trash = {
        cmd = "trash",
        require_confirm = true,
    },
})
