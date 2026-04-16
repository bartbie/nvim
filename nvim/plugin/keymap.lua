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
    { "<leader>o", group = "orgmode" },
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

-- -- make macros activation harder to start accidentally
-- local q_modes = { "n", "x" }
-- map(q_modes, "qq", "q", { desc = "Start/Stop recording macro" })
-- map(q_modes, "q", "reg_recording() != '' ? 'q' : '<Nop>'", { expr = true, desc = "Stop recording macro" })

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
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
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
    local ts = ai.gen_spec.treesitter
    local ts_ai = function(node)
        return ts({ a = ("@%s.outer"):format(node), i = ("@%s.inner"):format(node) })
    end
    BG.custom_textobjects = {
        f = ts_ai("function"),
        m = ts_ai("call"),
        c = ts_ai("class"),
        l = ts_ai("loop"),
        i = ts_ai("conditional"),
        a = ts_ai("parameter"),
        r = ts_ai("return"),
        o = ts_ai("block"),
        C = ts_ai("comment"),
        ["="] = ts_ai("assignment"),
        O = ts({
            a = { "@table.outer", "@dict.outer", "@object.outer", "@array.outer" },
            i = { "@table.inner", "@dict.inner", "@object.inner", "@array.inner" },
        }),
        -- whole buffer
        g = function()
            local from = { line = 1, col = 1 }
            local to = {
                line = vim.fn.line("$"),
                col = math.max(vim.fn.getline("$"):len(), 1),
            }
            return { from = from, to = to }
        end,
        -- make b only match ()
        b = ai.gen_spec.pair("(", ")", { type = "balanced" }),
    }
end

BG.indent_mappings = {
    -- which lines around the scope are included for 'ai': 'top', 'bottom', 'both', or 'none'
    border = "both",
    -- set to '' to disable
    object_scope = "is",
    object_scope_with_border = "as",
    -- motions
    goto_top = "[i",
    goto_bottom = "]i",
}

local has_wf, _wf = pcall(require, "wildfire")
if has_wf then
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

-- org / notes
do
    BG.agenda_keymaps = {
        ["TODO"] = { keymap = "ot", shortcut = "t" },
        ["PROGRESS"] = { keymap = "op", shortcut = "p" },
        ["WAITING"] = { keymap = "ow", shortcut = "w" },
        ["DONE"] = { keymap = "od", shortcut = "d" },
        ["CANCELLED"] = { keymap = "ox", shortcut = "x" },
    }

    BG.org_mappings = {
        org_agenda = false,

        org_capture = "<leader>oc",

        org_agenda_later = "f",
        org_agenda_earlier = "b",
        org_agenda_goto_today = ".",
        org_agenda_day_view = "vd",
        org_agenda_week_view = "vw",
        org_agenda_month_view = "vm",
        org_agenda_year_view = "vy",
        org_agenda_quit = "q",
        org_agenda_switch_to = "<CR>",
        org_agenda_goto = "<TAB>",
        org_agenda_goto_date = "J",
        org_agenda_redo = "r",
        org_agenda_todo = "t",
        org_agenda_clock_in = "I",
        org_agenda_clock_out = "O",
        org_agenda_clock_cancel = "X",
        org_agenda_priority = "<Leader>o,",
        org_agenda_priority_up = "+",
        org_agenda_priority_down = "-",
        org_agenda_archive = "<Leader>o$",
        org_agenda_set_tags = "<Leader>ot",
        org_agenda_deadline = "<Leader>oid",
        org_agenda_schedule = "<Leader>ois",
        org_agenda_refile = "<Leader>or",
        org_agenda_filter = "/",
        org_agenda_preview = "K",
        org_agenda_show_help = "g?",

        org_capture_finalize = "<C-c>",
        org_capture_refile = "<Leader>or",
        org_capture_kill = "<Leader>ok",
        org_capture_show_help = "g?",

        org_note_finalize = "<C-c>",
        org_note_kill = "<Leader>ok",

        org_refile = "<Leader>or",
        org_timestamp_up = "<C-a>",
        org_timestamp_down = "<C-x>",
        org_timestamp_up_day = "<S-UP>",
        org_timestamp_down_day = "<S-DOWN>",
        org_change_date = "cid",
        org_priority = "<Leader>o,",
        org_priority_up = "ciR",
        org_priority_down = "cir",
        org_todo = "cit",
        org_todo_prev = "ciT",
        org_toggle_checkbox = "<C-Space>",
        org_toggle_heading = "<Leader>o*",
        org_insert_link = "<Leader>oli",
        org_store_link = "<Leader>ols",
        org_open_at_point = "<Leader>oo",
        org_edit_special = "<Leader>o'",
        org_add_note = "<Leader>ona",
        org_cycle = "<TAB>",
        org_global_cycle = "<S-TAB>",
        org_archive_subtree = "<Leader>o$",
        org_set_tags_command = "<Leader>ot",
        org_do_promote = "<<",
        org_do_demote = ">>",
        org_promote_subtree = "<s",
        org_demote_subtree = ">s",
        org_meta_return = "<Leader><CR>",
        org_insert_heading_respect_content = "<Leader>oih",
        org_insert_todo_heading = "<Leader>oiT",
        org_insert_todo_heading_respect_content = "<Leader>oit",
        org_move_subtree_up = "<Leader>oK",
        org_move_subtree_down = "<Leader>oJ",
        org_export = "<Leader>oe",
        org_next_visible_heading = "}",
        org_previous_visible_heading = "{",
        org_forward_heading_same_level = "]]",
        org_backward_heading_same_level = "[[",
        outline_up_heading = "g{",
        org_deadline = "<Leader>oid",
        org_schedule = "<Leader>ois",
        org_time_stamp = "<Leader>oi.",
        org_time_stamp_inactive = "<Leader>oi!",
        org_clock_in = "<Leader>oxi",
        org_clock_out = "<Leader>oxo",
        org_clock_cancel = "<Leader>oxq",
        org_clock_goto = "<Leader>oxj",
        org_set_effort = "<Leader>oxe",
        org_babel_tangle = "<Leader>obt",
        org_show_help = "g?",

        org_edit_src_abort = "<Leader>ok",
        org_edit_src_save = "<Leader>ow",
        org_edit_src_save_exit = "<Leader>'",
        org_edit_src_show_help = "g?",

        inner_heading = "ih",
        around_heading = "ah",
        inner_subtree = "ir",
        around_subtree = "ar",
        inner_heading_from_root = "Oh",
        around_heading_from_root = "OH",
        inner_subtree_from_root = "Or",
        around_subtree_from_root = "OR",
    }

    BG.org_super_agenda_mappings = {
        filter_reset = "oa", -- reset all filters
        toggle_other = "oo", -- toggle catch-all "Other" section
        filter = "of", -- live filter (exact text)
        filter_fuzzy = "oz", -- live filter (fuzzy)
        filter_query = "oq", -- advanced query input
        undo = "u", -- undo last change
        reschedule = "cs", -- set/change SCHEDULED
        set_deadline = "cd", -- set/change DEADLINE
        cycle_todo = "t", -- cycle TODO state
        set_state = "s", -- set state directly (st, sd, etc.) or show menu
        reload = "r", -- refresh agenda
        refile = "R", -- refile via Telescope/org-telescope
        hide_item = "x", -- hide current item
        preview = "K", -- preview headline content
        clock_in = "I", -- clock in on current headline
        clock_out = "O", -- clock out active clock
        clock_cancel = "X", -- cancel active clock
        clock_goto = "gI", -- jump to active/recent clocked task
        reset_hidden = "gX", -- clear hidden list
        fold_all = "zM", -- collapse all groups
        unfold_all = "zR", -- expand all groups
        toggle_duplicates = "D", -- duplicate items may appear in multiple groups
        cycle_view = "ov", -- switch view (classic/compact)
        bulk_mark = "m", -- toggle mark on current item (● indicator)
        bulk_unmark_all = "M", -- clear all marks
        bulk_reselect = "gv", -- reselect last marks
        bulk_action = "B", -- run action on all marked items
        open_view = "V", -- open custom view picker
    }

    local notes = require("bartbie.notes")
    local md_folder = notes.notes_folder or notes.org_folder
    local org_folder = notes.org_folder

    if md_folder then
        map("n", "<leader>om", ("<CMD>e %s<CR>"):format(md_folder), { desc = "Open markdown notes" })
    end
    if org_folder then
        map("n", "<leader>oo", ("<CMD>e %s<CR>"):format(org_folder), { desc = "Open org notes" })
    end

    local has_org = pcall(require, "orgmode")
    local has_super = pcall(require, "org-super-agenda")

    if has_super then
        map("n", "<leader>ov", "<CMD>OrgSuperAgenda!<CR>", { desc = "Agenda" })
    end
end

-- folds
do
    local fold = require("bartbie.fold")
    map("n", "zC", fold.close_all_folds, { desc = "Close all folds" })
    map("n", "zO", fold.open_all_folds, { desc = "Open all folds" })
    map("n", "zm", fold.close_more_folds, { desc = "Close more folds" })
    map("n", "zl", fold.open_more_folds, { desc = "Open more folds" })
end
