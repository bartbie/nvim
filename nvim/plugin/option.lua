local o = vim.o
local g = vim.g
local opt = vim.opt

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

-- swap
o.updatetime = 100

-- fold
o.foldenable = true

-- window-split
o.splitright = true
o.splitbelow = true

-- netrw
vim.g.netrw_liststyle = 1

-- ui
o.number = true
o.relativenumber = true
o.cursorline = true
o.laststatus = 3
o.scrolloff = 1
o.signcolumn = "yes"
o.cmdheight = 0
o.fillchars = [[eob: ,fold: ,foldopen:,foldsep: ,foldclose:]]
o.list = true
opt.listchars:append("eol:󱞤")

-- search-ui
o.showmatch = true
o.incsearch = true
o.hlsearch = true

o.termguicolors = vim.fn.has("termguicolors") == 1
o.lazyredraw = true

-- diagnostics ui

local symbols = require("bartbie.symbols")

local symbols_table = {
    [vim.diagnostic.severity.ERROR] = symbols.diagnostics.error,
    [vim.diagnostic.severity.WARN] = symbols.diagnostics.warn,
    [vim.diagnostic.severity.INFO] = symbols.diagnostics.info,
    [vim.diagnostic.severity.HINT] = symbols.diagnostics.hint,
}

vim.diagnostic.config({
    signs = {
        text = symbols_table,
    },
    virtual_text = {
        prefix = function(d, _, _)
            return symbols_table[d.severity]
        end,
    },
    severity_sort = true,
})
