vim.notify("big file detected")
local buf = vim.api.nvim_get_current_buf()
-- disable paren matching
if vim.fn.exists(":NoMatchParen") ~= 0 then
    vim.cmd([[NoMatchParen]])
end
-- re-enable original non-ts syntax hl
vim.schedule(function()
    if vim.api.nvim_buf_is_valid(buf) then
        vim.bo[buf].syntax = vim.filetype.match({ buf = buf }) or ""
    end
end)
