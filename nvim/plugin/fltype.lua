local ftadd = vim.filetype.add

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
end
