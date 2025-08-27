local augroup = require("bartbie.augroup")
local ftadd = vim.filetype.add

local autocmd = vim.api.nvim_create_autocmd

---@param ft string
---@param group_name string
---@param callback fun(event: vim.api.keyset.create_autocmd.callback_args)
local ftautocmd = function(ft, group_name, callback)
    autocmd({ "FileType" }, {
        group = augroup(group_name),
        pattern = ft,
        callback = function(ev)
            vim.api.nvim_buf_call(ev.buf, function()
                callback(ev)
            end)
        end,
    })
end

---@param ft string
---@param fn fun(path: string, buf: integer): boolean
local ftfilter = function(ft, fn)
    return function(path, buf)
        if not path or not buf or vim.bo[buf].filetype == "bigfile" then
            return
        end
        if path ~= vim.api.nvim_buf_get_name(buf) then
            return
        end
        if fn(path, buf) then
            return ft
        end
    end
end

--- bigfile
do
    local MAX_SIZE = 1.5 * 1024 * 1024
    local MAX_AVG_LINE_LEN = 1000
    ftadd({
        pattern = {
            [".*"] = {
                ftfilter("bigfile", function(path, buf)
                    local size = vim.fn.getfsize(path)
                    if size <= 0 then
                        return false
                    end
                    if size > MAX_SIZE then
                        return true
                    end
                    local lines = vim.api.nvim_buf_line_count(buf)
                    return (size - lines) / lines > MAX_AVG_LINE_LEN
                end),
            },
        },
    })

    ftautocmd("bigfile", "handle_big_files", function(ev)
        vim.notify("big file detected")
        -- disable paren matching
        if vim.fn.exists(":NoMatchParen") ~= 0 then
            vim.cmd([[NoMatchParen]])
        end
        -- re-enable original non-ts syntax hl
        vim.schedule(function()
            if vim.api.nvim_buf_is_valid(ev.buf) then
                vim.bo[ev.buf].syntax = vim.filetype.match({ buf = ev.buf }) or ""
            end
        end)
    end)
end
