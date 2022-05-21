local opt = vim.opt

opt.list = true
opt.listchars:append("eol:↴")
-- opt.listchars:append("space:⋅")


require("indent_blankline").setup {
    use_treesitter = true,
    show_end_of_line = true,
    show_current_context = true,
    show_current_context_start = true,
    -- char_blankline = '┆',
    -- space_char_blankline = "",
    show_trailing_blankline_indent = false,
    show_first_indent_level = false,
    filetype_exclude = {
        "lspinfo",
        "packer",
        "checkhealth",
        "help",
        "man",
        "fugitive",
        "",
    },
}
