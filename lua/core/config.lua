local o = vim.o
local g = vim.g
local cmd = vim.cmd
o.number = true
o.relativenumber = true
o.cursorline = true
o.smartcase = true
o.scrolloff = 1
o.termguicolors = true
o.mouse = "a"

o.tabstop = 4
o.softtabstop = 4
o.expandtab = true
o.shiftwidth = 4
o.smartindent = true

o.laststatus = 3

g.do_filetype_lua = 1
g.did_load_filetypes = 0
