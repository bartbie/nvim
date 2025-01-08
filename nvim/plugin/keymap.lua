local defaults = { silent = true }
local function map(mode, lhs, rhs, opts)
    vim.keymap.set(mode, lhs, rhs, vim.tbl_extend("force", defaults, opts or {}))
end

vim.g.mapleader = " "
vim.g.maplocalleader = " "

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
-- FIXME
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

-- LSP
do
    local lspb = vim.lsp.buf

    ---jump diagnostics
    ---@param count 1 | -1
    ---@param severity? vim.diagnostic.Severity|vim.diagnostic.Severity[]|{ min: vim.diagnostic.Severity, max: vim.diagnostic.Severity }
    local function diag_jmp(count, severity)
        return function()
            vim.diagnostic.jump({
                count = count,
                severity = severity,
            })
        end
    end

    local function source_code_action()
        lspb.code_action({ context = { only = { "source" }, diagnostics = {} } })
    end

    vim.api.nvim_create_autocmd("LspAttach", {
        group = require("bartbie.augroup")("lsp_attach_keymaps"),
        callback = function()
            local has_fzf, fzf = pcall(require, "fzf-lua")
            fzf = fzf or {}
            ---@param fzf_fn function
            ---@param vim_fn function
            ---@return function
            local function fzf_or(fzf_fn, vim_fn)
                return has_fzf and fzf_fn or vim_fn
            end

            map("n", "<leader>cl", "<cmd>LspInfo<cr>", { desc = "Lsp Info" })
            map("n", "<leader>cA", source_code_action, { desc = "Source Action" })

            -- defaults from nvim docs (https://neovim.io/doc/user/lsp.html#lsp-defaults)
            -- "grn"    - N   - lspb.rename()
            -- "gO"     - N   - lspb.document_symbol()
            -- "CTRL-S" - I   - lspb.signature_help()
            -- "K"      - N   - lspb.hover()

            map("n", "gd", fzf_or(fzf.lsp_definitions, lspb.definition), { desc = "Goto Definition" })
            map("n", "grd", fzf_or(fzf.lsp_definitions, lspb.definition), { desc = "Goto Definition" })
            map("n", "grr", fzf_or(fzf.lsp_references, lspb.references), { desc = "Goto References" })
            map("n", "grt", fzf_or(fzf.lsp_typedefs, lspb.type_definition), { desc = "Goto Type Definition" })
            map("n", "grD", fzf_or(fzf.lsp_declarations, lspb.declaration), { desc = "Goto Declaration" })
            map("n", "gri", fzf_or(fzf.lsp_implementations, lspb.implementation), { desc = "Goto implementation" })
            map("n", "gra", fzf_or(fzf.lsp_code_actions, lspb.code_action), { desc = "Goto implementation" })
            --
            map("n", "gro", vim.diagnostic.open_float, { desc = "Show Line Diagnostics" })
            map("n", "grj", diag_jmp(1), { desc = "Jump to Next Diagnostic" })
            map("n", "grk", diag_jmp(-1), { desc = "Jump to Prev Diagnostic" })
            map("n", "]e", diag_jmp(1, "ERROR"), { desc = "Next Error" })
            map("n", "[e", diag_jmp(-1, "ERROR"), { desc = "Prev Error" })
        end,
    })
end
