local defaults = { silent = true }
local map = function(mode, lhs, rhs, opts)
    vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", defaults, opts or {}))
end

-- better up/down
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true })

-- better indentation
map("v", "<", "<gv")
map("v", ">", ">gv")

-- save file
map({ "i", "v", "n", "s" }, "<C-s>", "<cmd>w<cr><esc>", { desc = "Save file" })

-- Clear search with <esc>
map({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and clear hlsearch" })

-- Move to window using the <ctrl> hjkl keys
map("n", "<C-h>", "<C-w>h", { desc = "Focus left window" })
map("n", "<C-j>", "<C-w>j", { desc = "Focus lower window" })
map("n", "<C-k>", "<C-w>k", { desc = "Focus upper window" })
map("n", "<C-l>", "<C-w>l", { desc = "Focus right window" })

-- Resize window using <ctrl> HJKL keys
map("n", "<C-H>", "<cmd>resize +2<cr>", { desc = "Increase window height" })
map("n", "<C-J>", "<cmd>resize -2<cr>", { desc = "Decrease window height" })
map("n", "<C-K>", "<cmd>vertical resize -2<cr>", { desc = "Decrease window width" })
map("n", "<C-L>", "<cmd>vertical resize +2<cr>", { desc = "Increase window width" })

-- Move selected text up/down
map("x", "K", ":move '<-2<CR>gv=gv")
map("x", "J", ":move '>+1<CR>gv=gv")

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
map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other buffer" })
map("n", "<leader>bd", "<CMD>bd<CR>", { desc = "Delete buffer" })
map("n", "<leader>bD", "<CMD>%bd<CR>", { desc = "Delete all buffers" })
map("n", "<TAB>", "<CMD>bnext<CR>", { desc = "Next buffer" })
map("n", "<S-TAB>", "<CMD>bprevious<CR>", { desc = "Prev buffer" })

-- Expand to current buffer's directory in command mode
map("c", "%%", function()
    if vim.fn.getcmdtype() == ":" then
        return vim.fn.expand("%:h") .. "/"
    else
        return "%%"
    end
end, { expr = true, desc = "Expand to current buffer's directory" })

-- command alias for saving the buffer
vim.api.nvim_create_user_command("W", "w", {})
