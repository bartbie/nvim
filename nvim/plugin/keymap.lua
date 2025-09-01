local defaults = { silent = true }

local BG = require("bartbie.G")

---@alias mode "n" | "v" | "i" | "x" | "s" | "c"

---@param mode mode | mode[]
---@param lhs string | string[]
---@param rhs string | function
---@param opts? vim.keymap.set.Opts
local function map(mode, lhs, rhs, opts)
    opts = vim.tbl_extend("force", defaults, opts or {})
    if type(lhs) == "table" then
        for _, l in ipairs(lhs) do
            vim.keymap.set(mode, l, rhs, opts)
        end
    else
        vim.keymap.set(mode, lhs, rhs, opts)
    end
end

---@generic T
---@param fn fun(...: T)
---@param ... T
---@return function
local function wrap(fn, ...)
    local args = { ... }
    local n = #args
    return n > 0 and function()
        return fn(unpack(args))
    end or function()
        return fn()
    end
end

BG.keymap_groups = {
    { "<leader>f", group = "file" },
    { "<leader>s", group = "search" },
    { "<leader>g", group = "git" },
    { "<leader>c", group = "code" },
    { "<leader>w", group = "windows" },
    { "<leader>b", group = "buffers" },
}

vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- better up/down
map("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })
map("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true })

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
local win = require("bartbie.win")

---@param key bartbie.win.Hjkl
local function resize(key)
    return function()
        win.resize(0, win.key_to_dirn[key], 3, { adaptive = true })
    end
end
map("n", "<C-H>", resize("h"), { desc = "Decrease window width" })
map("n", "<C-J>", resize("j"), { desc = "Decrease window height" })
map("n", "<C-K>", resize("k"), { desc = "Increase window height" })
map("n", "<C-L>", resize("l"), { desc = "Increase window width" })

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
-- TODO: when/if making bartbie.buf, move it there and refactor to take current bufnr
local function close_other_bufs()
    local current = vim.api.nvim_get_current_buf()
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if buf ~= current and vim.bo[buf].buflisted and not vim.bo[buf].modified then
            vim.bo[buf].buflisted = false
            vim.api.nvim_buf_delete(buf, { unload = true })
        end
    end
end

map("n", "<leader>bb", "<cmd>e #<cr>", { desc = "Switch to Other buffer" })
map("n", "<leader>bd", "<CMD>bd<CR>", { desc = "Delete buffer" })
map("n", "<leader>bo", close_other_bufs, { desc = "Delete all other buffers" })
map("n", "<leader>bD", "<CMD>%bd<CR>", { desc = "Delete all buffers" })
map("n", "<TAB>", "<CMD>bnext<CR>", { desc = "Next buffer" })
map("n", "<S-TAB>", "<CMD>bprevious<CR>", { desc = "Prev buffer" })

-- Expand to current buffer's directory in command mode
map("c", "%%", function()
    return vim.fn.getcmdtype() == ":" and (vim.fn.expand("%:h") .. "/") or "%%"
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

-- diagnostics
do
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

    local diag = require("bartbie.diag")

    map("n", "gro", vim.diagnostic.open_float, { desc = "Show Line Diagnostics" })
    map("n", "grj", diag_jmp(1), { desc = "Jump to Next Diagnostic" })
    map("n", "grk", diag_jmp(-1), { desc = "Jump to Prev Diagnostic" })
    map("n", "]e", diag_jmp(1, vim.diagnostic.severity.ERROR), { desc = "Next Error" })
    map("n", "[e", diag_jmp(-1, vim.diagnostic.severity.ERROR), { desc = "Prev Error" })

    map("n", "<leader>cd", wrap(diag.toggle_virt_diag), { desc = "Toggle Lines or Text Diagnostics" })
    map("n", "<leader>cD", wrap(diag.toggle_virt_diag_err_only), { desc = "Toggle Lines or Text Diagnostics" })
end

-- LSP
do
    local lspb = vim.lsp.buf

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
                return wrap(has_fzf and fzf_fn or vim_fn)
            end

            map("n", "<leader>cl", "<cmd>LspInfo<cr>", { desc = "Lsp Info" })
            map("n", "<leader>cA", source_code_action, { desc = "Source Action" })
            -- + diagnostics cd

            map("n", { "gd", "grd" }, fzf_or(fzf.lsp_definitions, lspb.definition), { desc = "Goto Definition" })
            map("n", "grr", fzf_or(fzf.lsp_references, lspb.references), { desc = "Goto References" })
            map("n", "grt", fzf_or(fzf.lsp_typedefs, lspb.type_definition), { desc = "Goto Type Definition" })
            map("n", "grD", fzf_or(fzf.lsp_declarations, lspb.declaration), { desc = "Goto Declaration" })
            map("n", "gri", fzf_or(fzf.lsp_implementations, lspb.implementation), { desc = "Goto implementation" })
            map("n", "gra", fzf_or(fzf.lsp_code_actions, lspb.code_action), { desc = "Goto code actions" })
            map("i", "C-I", wrap(lspb.signature_help), { desc = "Show Symbol Signature" })
            -- same as defaults (https://neovim.io/doc/user/lsp.html#lsp-defaults)
            map("n", "grn", wrap(lspb.rename), { desc = "Rename" })
            map("n", "gO", wrap(lspb.document_symbol), { desc = "List all buffer symbols in loclist" })
            map("n", "K", wrap(lspb.hover), { desc = "Show Symbol Hover Info" })
            -- + diagnostics gro grj grk
        end,
    })
end

-- blink.cmp
-- 'default' for mappings similar to built-in completion
-- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
-- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
BG.blink = {
    keymap = {
        preset = "enter",
        ["<Tab>"] = {
            "snippet_forward",
            "select_next",
            "fallback",
        },
        ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
    },
    cmdline = {
        keymap = {
            preset = "enter",
            ["<Tab>"] = {
                "show",
                "snippet_forward",
                "select_next",
                "fallback",
            },
            ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
        },
    },
}

-- Oil
local has_oil, oil = pcall(require, "oil")
if has_oil then
    map("n", "-", oil.open, { desc = "Open file browser" })
end

-- fzf
local has_fzf, fzf = pcall(require, "fzf-lua")
if has_fzf then
    map("n", "<leader>:", fzf.command_history, { desc = "Command History" })
    -- find
    map("n", { "<leader>,", "<leader>fb" }, fzf.buffers, { desc = "Find Buffers" })
    map("n", "<leader>ff", fzf.files, { desc = "Find Files" })
    map("n", "<leader>fh", fzf.oldfiles, { desc = "Find Recent Files" })
    -- search
    map("n", "<leader>sg", fzf.live_grep_native, { desc = "Grep" })
    map("n", "<leader>sw", fzf.grep_curbuf, { desc = "Buffer" })
    map("n", "<leader>sd", fzf.diagnostics_document, { desc = "Diagnostics" })
    map("n", "<leader>sD", fzf.diagnostics_workspace, { desc = "Diagnostics (Workspace)" })
    map("n", "<leader>sh", fzf.helptags, { desc = "Helptags" })
    map("n", "<leader>sk", fzf.keymaps, { desc = "Keymaps" })
    map("n", "<leader>sm", fzf.marks, { desc = "Marks" })
    -- git
    map("n", "<leader>gc", fzf.git_commits, { desc = "commits" })
    map("n", "<leader>gs", fzf.git_status, { desc = "status" })
end

local has_minimove, move = pcall(require, "mini.move")
if has_minimove then
    map("x", "H", wrap(move.move_selection, "left"), { desc = "Move left" })
    map("x", "J", wrap(move.move_selection, "down"), { desc = "Move down" })
    map("x", "K", wrap(move.move_selection, "up"), { desc = "Move up" })
    map("x", "L", wrap(move.move_selection, "right"), { desc = "Move right" })

    map("x", { ">", "<TAB>" }, wrap(move.move_line, "right"), { desc = "Move line right" })
    map("x", { "<", "<S-TAB>" }, wrap(move.move_line, "left"), { desc = "Move line left" })
else -- these are strictly worse but i will leave them here
    -- better indentation
    map("v", "<tab>", ">gv")
    map("v", "<s-tab>", "<gv")
    map("v", ">", ">gv")
    map("v", "<", "<gv")

    -- Move selected text up/down
    map("x", "K", ":move '<-2<CR>gv=gv")
    map("x", "J", ":move '>+1<CR>gv=gv")
end

local has_miniai, ai = pcall(require, "mini.ai")
if has_miniai then
    local treesitter = ai.gen_spec.treesitter
    BG.custom_textobjects = {
        f = treesitter({ a = "@function.outer", i = "@function.inner" }),
        c = treesitter({ a = "@class.outer", i = "@class.inner" }),
        o = treesitter({
            a = { "@conditional.outer", "@loop.outer" },
            i = { "@conditional.inner", "@loop.inner" },
        }),
    }
end

local has_ts, _ts = pcall(require, "nvim-treesitter.configs")
if has_ts then
    BG.incremental_selection = {
        init_selection = "gnn",
        node_incremental = "grn",
        node_decremental = "grl",
        scope_incremental = "gro",
    }
end

local has_conform, conform = pcall(require, "conform")
if has_conform then
    map("n", "<leader>cf", function()
        conform.format()
    end, { desc = "Format Code" })
end

if vim.cmd.UndotreeToggle then
    map("n", "<leader>u", vim.cmd.UndotreeToggle, {
        desc = "Undo tree",
    })
end
