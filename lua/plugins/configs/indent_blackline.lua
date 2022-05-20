local opt = vim.opt

opt.list = true
opt.listchars:append("eol:↴")
-- opt.listchars:append("space:⋅")


require("indent_blankline").setup {
    show_end_of_line = true,
    show_current_context = true,
    show_current_context_start = true,
    space_char_blankline = " ",
}
