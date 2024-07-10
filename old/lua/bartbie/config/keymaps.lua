-- keymaps that don't require any plugins (besides lazy.nvim)
-- for keymaps associated with plugins see "keys" pairs in plugins.lua

local DEFAULTS = { silent = true }

--- function for setting up keymaps
---@param mode string | string[]
---@param lhs string
---@param rhs string | function
---@param opts table?
local map = function(mode, lhs, rhs, opts)
    local keys = require("lazy.core.handler").handlers.keys
    -- do not create the keymap if a lazy keys handler exists
    if keys.active[keys.parse({ lhs, mode = mode }).id] then
        return
    end
    opts = vim.tbl_extend("force", DEFAULTS, opts or {})
    vim.keymap.set(mode, lhs, rhs, opts)
end

-- better up/down
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, desc = "Move Down" })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, desc = "Move Up" })

-- better indentation
map("v", "<", "<gv", { desc = "Indent selected text left" })
map("v", ">", ">gv", { desc = "Indent selected text right" })

-- lazy
map("n", "<leader>l", "<cmd>:Lazy<cr>", { desc = "Open Lazy" })

-- save file
map({ "i", "v", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

-- Clear search with <esc>
map({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and clear hlsearch" })

-- Move to window using the <ctrl> hjkl keys
map("n", "<C-h>", "<C-w>h", { desc = "Focus left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Focus lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Focus upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Focus right window" })

-- Resize window using <ctrl> arrow keys
map("n", "<C-Up>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
map("n", "<C-Left>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("n", "<C-Right>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- Move selected text up/down
map("x", "K", ":move '<-2<CR>gv=gv", { desc = "Move selected text up" })
map("x", "J", ":move '>+1<CR>gv=gv", { desc = "Move selected text down" })

-- windows
map("n", "<leader>ww", "<C-W>p", { desc = "Other window" })
map("n", "<leader>wd", "<C-W>c", { desc = "Delete window" })
map("n", "<leader>wh", "<C-W>s", { desc = "Split window below" })
map("n", "<leader>wv", "<C-W>v", { desc = "Split window right" })
map("n", "<leader>w-", "<C-W>s", { desc = "Split window below" })
map("n", "<leader>w|", "<C-W>v", { desc = "Split window right" })
map("n", "<leader>-", "<C-W>s", { desc = "Split window below" })
map("n", "<leader>|", "<C-W>v", { desc = "Split window right" })

-- buffers
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other Buffer" })
map("n", "<leader>bd", "<CMD>bd<CR>", { desc = "Delete buffer" })
map("n", "<leader>bD", "<CMD>%bd<CR>", { desc = "Delete all buffers" })
map("n", "<TAB>", "<CMD>bnext<CR>", { desc = "Next Buffer" })
map("n", "<S-TAB>", "<CMD>bprevious<CR>", { desc = "Prev Buffer" })

-- command alias for saving the buffer
vim.api.nvim_create_user_command("W", "w", { desc = "Save File" })

-- make macros activation harder to start accidentally
local q_modes = { "n", "x" }
map(q_modes, "qq", "q", { desc = "Start/Stop recording macro" })
map(q_modes, "q", "reg_recording() != '' ? 'q' : '<Nop>'", { expr = true, desc = "Stop recording macro" })

-- yank into system clipboard
map({ "n", "v" }, "<leader>y", '"+y', { desc = "Yank motion (OS)" })
map({ "n", "v" }, "<leader>Y", '"+Y', { desc = "Yank line (OS)" })

-- delete into system clipboard
map({ "n", "v" }, "<leader>d", '"+d', { desc = "Delete motion (OS)" })
map({ "n", "v" }, "<leader>D", '"+D', { desc = "Delete line (OS)" })

-- paste from system clipboard
map("n", "<leader>p", '"+p', { desc = "Paste after (OS)" })
map("n", "<leader>P", '"+P', { desc = "Paste before (OS)" })

-- files
map("n", "<leader>fn", "<CMD>enew<CR>", { desc = "New File" })
