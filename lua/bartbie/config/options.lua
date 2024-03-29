local o = vim.o
local g = vim.g
local cmd = vim.cmd

-- general
o.number = true
o.relativenumber = true
o.cursorline = true
o.smartcase = true
o.scrolloff = 1
o.termguicolors = true
o.mouse = "a"
o.signcolumn = "yes"

-- indent
o.tabstop = 4
o.softtabstop = 4
o.expandtab = true
o.shiftwidth = 4
o.smartindent = true

-- status
o.laststatus = 3
