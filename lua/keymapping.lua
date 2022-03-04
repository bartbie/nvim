local function map(mode, lhs, rhs, opts)
    opts = vim.tbl_extend('force', {noremap = true, silent = true}, opts or {})
    vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
end

map('n','<space>','<Nop>')
vim.g.mapleader = ' '

-- CHADTREE
map('n', '<leader>n', '<CMD>CHADopen<CR>')

-- FUGITIVE
map('n', '<leader>gg', '<CMD>Git<CR>')
map('n', '<leader>gc', '<CMD>Git commit<CR>')

-- TELESCOPE
map('n', '<leader>ff', '<CMD>Telescope find_files<CR>')
map('n', '<leader>fg', '<CMD>Telescope live_grep<CR>')
map('n', '<leader>fb', '<CMD>Telescope buffers<CR>')
map('n', '<leader>fh', '<CMD>Telescope help_tags<CR>')
