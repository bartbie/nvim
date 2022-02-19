local map = vim.api.nvim_set_keymap

vim.g.mapleader = ' '

-- CHADTREE
map('n', '<leader>n', '<CMD>CHADopen<CR>', {silent=true})

-- FUGITIVE
map('n', '<leader>gg', '<CMD>Git<CR>', {noremap=true})
map('n', '<leader>gc', '<CMD>Git commit<CR>', {noremap=true})

-- TELESCOPE
map('n', '<leader>ff', '<CMD>Telescope find_files<CR>', {noremap=true})
map('n', '<leader>fg', '<CMD>Telescope live_grep<CR>', {noremap=true})
map('n', '<leader>fb', '<CMD>Telescope buffers<CR>', {noremap=true})
map('n', '<leader>fh', '<CMD>Telescope help_tags<CR>', {noremap=true})
