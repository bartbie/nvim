local augroup = require("bartbie.augroup")
local autocmd = vim.api.nvim_create_autocmd

-- Check if we need to reload the file when it changed
autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
    group = augroup("checktime"),
    command = "checktime",
})

-- Highlight on yank
autocmd("TextYankPost", {
    group = augroup("highlight_yank"),
    callback = function()
        vim.highlight.on_yank()
    end,
})

-- resize splits if window got resized
autocmd({ "VimResized" }, {
    group = augroup("resize_splits"),
    callback = function()
        vim.cmd("tabdo wincmd =")
    end,
})

-- go to last loc when opening a buffer
autocmd("BufReadPost", {
    group = augroup("last_loc"),
    callback = function()
        local mark = vim.api.nvim_buf_get_mark(0, '"')
        local lcount = vim.api.nvim_buf_line_count(0)
        if mark[1] > 0 and mark[1] <= lcount then
            pcall(vim.api.nvim_win_set_cursor, 0, mark)
        end
    end,
})

-- close some filetypes with <q>
autocmd("FileType", {
    group = augroup("close_with_q"),
    pattern = {
        "PlenaryTestPopup",
        "help",
        "lspinfo",
        "man",
        "notify",
        "qf",
        "spectre_panel",
        "startuptime",
        "tsplayground",
        "checkhealth",
        "fugitive",
    },
    callback = function(event)
        vim.bo[event.buf].buflisted = false
        vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = event.buf, silent = true })
    end,
})

-- wrap and check for spell in text filetypes
autocmd("FileType", {
    group = augroup("wrap_spell"),
    pattern = { "gitcommit", "markdown" },
    callback = function()
        vim.opt_local.wrap = true
        vim.opt_local.spell = true
    end,
})

-- Auto create dir when saving a file, in case some intermediate directory does not exist
autocmd({ "BufWritePre" }, {
    group = augroup("auto_create_dir"),
    callback = function(event)
        if vim.bo[event.buf].filetype == "oil" then
            return
        end
        local file = vim.uv.fs_realpath(event.match) or event.match
        vim.fn.mkdir(vim.fn.fnamemodify(file, ":p:h"), "p")
    end,
})

-- Show diagnostic popup on cursor hover
autocmd("CursorHold", {
    group = augroup("diagnostic_float"),
    callback = function()
        vim.diagnostic.open_float(nil, { focusable = false })
    end,
})

---@param buf integer
---@return boolean
local function is_buf_empty(buf)
    local line_count = vim.api.nvim_buf_line_count(buf)
    if line_count > 1 then
        return false
    end

    local first_line = vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1]
    return first_line == ""
end

-- close scratch buffers if empty and another buffer opens
autocmd("BufWinLeave", {
    group = augroup("close_empty_scratch_bufs"),
    callback = function(ev)
        local buf = ev.buf
        if vim.bo[buf].modified and not is_buf_empty(buf) then
            return
        end

        local buftype = vim.bo[buf].buftype
        buftype = buftype == "" and "nofile" or buftype

        local file = ev.file
        local bufname = vim.api.nvim_buf_get_name(buf)

        if buftype == "nofile" and file == "" and bufname == "" then
            vim.schedule(function()
                if vim.api.nvim_buf_is_valid(buf) then
                    vim.api.nvim_buf_delete(buf, { force = true })
                end
            end)
        end
    end,
})
