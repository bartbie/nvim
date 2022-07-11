-- TODO:
-- make unnormal mappings use WhichKey API

-- used for toggleterm shortcuts
local terminals = require("plugins.configs.toggleterm").terminals

local function map(mode, lhs, rhs, opts)
    opts = vim.tbl_extend("force", { silent = true }, opts or {})
    vim.keymap.set(mode, lhs, rhs, opts)
end

local M = {}

M.map = map

M.opts = {
    mode = "n", -- NORMAL mode
    -- prefix: use "<leader>f" for example for mapping everything related to finding files
    -- the prefix is prepended to every mapping part of `mappings`
    buffer = nil, -- Global mappings. Specify a buffer number for buffer local mappings
    silent = true, -- use `silent` when creating keymaps
    noremap = true, -- use `noremap` when creating keymaps
    nowait = false, -- use `nowait` when creating keymaps
}

M.keymaps = {}

M.keymaps["<leader>"] = {
    l = { ":noh<CR>", "Turn Off Search Highlight" },
    -- NVIM-TREE
    n = { "<CMD>NvimTreeToggle<CR>", "Toggle FileTree" },
    f = {
        name = "Finder",
        -- TELESCOPE
        f = { "<CMD>Telescope find_files<CR>", "Find File" },
        g = { "<CMD>Telescope live_grep<CR>", "Grep Through Files" },
        h = { "<CMD>Telescope oldfiles<CR>", "Find Recent Files" },
        b = { "<CMD>Telescope buffers<CR>", "Find Buffer" },
        d = { "<CMD>Telescope help_tags<CR>", "Find Documentation" },
        m = { "<CMD>Telescope marks<CR>", "Find Bookmarks" },
        w = { "<CMD>Telescope current_buffer_fuzzy_find<CR>", "Find Word In Buffer" },
    },
    g = {
        name = "Git",
        -- FUGITIVE
        g = { "<CMD>Git<CR>", "Open Status Menu" },
        c = { "<CMD>Git commit<CR>", "Commit" },
        -- GITSIGNS
        s = { "<CMD>Gitsigns stage_hunk<CR>", "Stage Hunk" },
        u = { "<cmd>Gitsigns undo_stage_hunk<CR>", "Unstage Hunk" },
        r = { "<CMD>Gitsigns reset_hunk<CR>", "Reset Hunk" },
        p = { "<cmd>Gitsigns preview_hunk<CR>", "Preview Hunk" },
        S = { "<cmd>Gitsigns stage_buffer<CR>", "Stage Buffer" },
        R = { "<cmd>Gitsigns reset_buffer<CR>", "Reset Buffer" },
        d = { "<cmd>Gitsigns diffthis<CR>", "Diff This File" },
        ["'"] = { "<CMD>Gitsigns toggle_current_line_blame<CR>", "Toggle Line Blame" },
        -- TELESCOPE
        f = { "<CMD>Telescope git_status<CR>", "Find Changed Files In Git" },
        h = { "<CMD>Telescope git_bcommits<CR>", "Show Commits For This File" },
    },
    x = {
        name = "Diagnostics Menu",
        -- TROUBLE
        x = { "<CMD>TroubleToggle<cr>", "Toggle Menu" },
        w = { "<CMD>TroubleToggle workspace_diagnostics<cr>", "Toggle Menu For Workspace" },
        d = { "<CMD>TroubleToggle document_diagnostics<cr>", "Toggle Menu For Single File" },
        l = { "<CMD>TroubleToggle loclist<cr>", "Show Location List" },
        q = { "<CMD>TroubleToggle quickfix<cr>", "Show QuickFix List" },
    },
    k = { [[g*<Cmd>lua require('hlslens').start()<CR>]], "Search For This Word" },

    d = {
        name = "Database Menu",
        -- DADBOT UI
        u = { "<CMD>DBUIToggle<CR>", "Toggle Database Menu" },
        f = { "<CMD>DBUIFindBuffer<CR>", "Find Database Buffer" },
        r = { "<CMD>DBUIRenameBuffer<CR>", "Rename Database Buffer" },
        l = { "<CMD>DBUILastQueryInfo<CR>", "Last Query Info" },
    },

    t = {
        name = "Terminal Menu",
        g = { terminals.lazygit, "Toggle Lazygit" },
        p = { terminals.python, "Toggle Python REPL" },
    },
}

M.keymaps[""] = {
    -- GITSIGNS
    ["]c"] = { "&diff ? ']c' : '<CMD>Gitsigns next_hunk<CR>'", "Jump To Next Hunk", expr = true },
    ["[c"] = { "&diff ? '[c' : '<CMD>Gitsigns prev_hunk<CR>'", "Jump to Previous Hunk", expr = true },
    -- HLSLENS
    ["n"] = {
        [[<Cmd>execute('normal! ' . v:count1 . 'n')<CR><Cmd>lua require('hlslens').start()<CR>]],
        "Jump To Next Search",
    },
    ["N"] = {
        [[<Cmd>execute('normal! ' . v:count1 . 'N')<CR><Cmd>lua require('hlslens').start()<CR>]],
        "Jump To Previous Search",
    },
    ["*"] = { [[*<Cmd>lua require('hlslens').start()<CR>]], "Jump To Next Search" },
    ["#"] = { [[#<Cmd>lua require('hlslens').start()<CR>]], "Jump To Previous Search" },
    -- improve those descriptions
    ["g*"] = { [[g*<Cmd>lua require('hlslens').start()<CR>]], "Jump To Next Search" },
    ["g#"] = { [[g#<Cmd>lua require('hlslens').start()<CR>]], "Jump To Previous Search" },
    ["<TAB>"] = { "<CMD>bnext<CR>", "Next Window" },
    ["<S-TAB>"] = { "<CMD>bprevious<CR>", "Previous Window" },

    ["<C-h>"] = { "<C-w>h", "Focus Left Window" },
    ["<C-j>"] = { "<C-w>j", "Focus Down Window" },
    ["<C-k>"] = { "<C-w>k", "Focus Upper Window" },
    ["<C-l>"] = { "<C-w>l", "Focus Right Window" },
}

M.lsp_keymaps = {
    ["<leader>"] = {
        w = {
            name = "Workspace",
            a = { vim.lsp.buf.add_workspace_folder, "Add This Folder To Workspace" },
            r = { vim.lsp.buf.remove_workspace_folder, "Remove This Folder From Workspace" },
            l = {
                function()
                    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
                end,
                "List Workspace Folders",
            },
        },
        x = {
            f = { vim.lsp.buf.formatting, "Format This Buffer" },
        },
    },
    g = {
        D = { vim.lsp.buf.declaration, "Go To Declaration" },
        d = { vim.lsp.buf.definition, "Go To Definition" },
        i = { vim.lsp.buf.implementation, "Go To Implementation" },
        r = { "<CMD>TroubleToggle lsp_references<cr>", "Show References" },
        t = { vim.lsp.buf.type_definition, "Go to Type Definition" },
        p = { "<CMD>Lspsaga preview_definition<cr>", "Preview Definition" },
        n = { "<CMD>Lspsaga rename<cr>", "Rename Variable" },
        x = { "<CMD>Lspsaga code_action<cr>", "Show Code Actions" },
        o = { "<CMD>Lspsaga show_line_diagnostics<cr>", "Show Line Diagnostics" },
        j = { "<CMD>Lspsaga diagnostic_jump_next<cr>", "Jump To Next Line Diagnostic" },
        k = { "<CMD>Lspsaga diagnostic_jump_prev<cr>", "Jump To Previous Line Diagnostic" },
    },
    K = { "<cmd>Lspsaga hover_doc<cr>", "Hover Documentation" },
    -- no idea what it does
    -- ["<C-u>"] = { require('lspsaga.action').smart_scroll_with_saga(-1, '<c-u>'), "" },
    -- ["<C-d>"] = { require('lspsaga.action').smart_scroll_with_saga(1, '<c-d>'), "" },
    -- ["<C-p>"] = { vim.lsp.buf.signature_help, "Show Signature Help" }
    --     map(0, "x", "gx", ":<c-u>Lspsaga range_code_action<cr>", {silent = true, noremap = true})
}

M.term_keymaps = function()
    function _G.set_terminal_keymaps()
        local opts = { buffer = 0 }
        vim.keymap.set("t", "<esc>", [[<C-\><C-n>]], opts)
        vim.keymap.set("t", "<C-h>", [[<C-\><C-n><C-W>h]], opts)
        vim.keymap.set("t", "<C-j>", [[<C-\><C-n><C-W>j]], opts)
        vim.keymap.set("t", "<C-k>", [[<C-\><C-n><C-W>k]], opts)
        vim.keymap.set("t", "<C-l>", [[<C-\><C-n><C-W>l]], opts)
    end
    vim.cmd("autocmd! TermOpen term://* lua set_terminal_keymaps()")
end

M.setup = function()
    map("n", "<space>", "<Nop>")
    vim.g.mapleader = " "

    -- stage hunks in visual mode
    map("v", "<leader>gs", "<CMD>Gitsigns stage_hunk<CR>")
    map("v", "<leader>gr", "<CMD>Gitsigns reset_hunk<CR>")

    -- better indentation
    map("v", "<", "<gv")
    map("v", ">", ">gv")

    -- Move selected text up/down
    map("x", "K", ":move '<-2<CR>gv=gv")
    map("x", "J", ":move '>+1<CR>gv=gv")

    M.term_keymaps()
end

return M
