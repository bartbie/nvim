local function map(mode, lhs, rhs, opts)
    opts = vim.tbl_extend('force', {noremap = true, silent = true}, opts or {})
    if type(mode) == 'string' then
        vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
    else
        for _, m in ipairs(mode) do
            vim.api.nvim_set_keymap(m, lhs, rhs, opts)
        end
    end
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

-- GITSIGNS
map('n', ']c', "&diff ? ']c' : '<CMD>Gitsigns next_hunk<CR>'", {expr=true})
map('n', '[c', "&diff ? '[c' : '<CMD>Gitsigns prev_hunk<CR>'", {expr=true})
map({'n', 'v'}, '<leader>gs', '<CMD>Gitsigns stage_hunk<CR>')
map('n', '<leader>gu', '<cmd>Gitsigns undo_stage_hunk<CR>')
map('n', '<leader>gp', '<cmd>Gitsigns preview_hunk<CR>')
map({'n', 'v'}, '<leader>gr', '<CMD>Gitsigns reset_hunk<CR>')
map('n', '<leader>gS', '<cmd>Gitsigns stage_buffer<CR>')
map('n', '<leader>gR', '<cmd>Gitsigns reset_buffer<CR>')
map('n', '<leader>gd', '<cmd>Gitsigns diffthis<CR>')
