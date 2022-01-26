local map = vim.api.nvim_set_keymap
vim.g.mapleader = ' '
-- CHADTREE
map('n', '<C-n>', '<CMD>CHADopen<CR>', {silent=true})

-- FUGITIVE
map('n', '<leader>gg', '<CMD>Git<CR>', {noremap=true})
map('n', '<leader>gc', '<CMD>Git commit<CR>', {noremap=true})
