local o = vim.o
local g = vim.g

g.mapleader = " "
g.maplocalleader = " "

-- general
o.compatible = false
g.editorconfig = true
o.mouse = "a"

-- search
o.path = o.path .. "**"
o.smartcase = true

-- indent
o.expandtab = true
local tab_size = 4
o.tabstop = tab_size
o.softtabstop = tab_size
o.shiftwidth = tab_size
o.smartindent = true

-- spell-checking
o.spell = true
o.spelllang = "en"

-- undo
o.undofile = true

-- fold
o.foldenable = true

-- window-split
o.splitright = true
o.splitbelow = true

-- ui
o.number = true
o.relativenumber = true
o.cursorline = true
o.laststatus = 3
o.scrolloff = 1
o.signcolumn = "yes"
o.cmdheight = 0
o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]

-- search-ui
o.showmatch = true
o.incsearch = true
o.hlsearch = true

o.termguicolors = vim.fn.has("termguicolors") == 1
o.lazyredraw = true
