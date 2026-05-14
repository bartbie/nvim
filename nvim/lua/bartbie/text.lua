local M = {}

--- Replace text in range [sr,sc]..[er,ec) with a plain string.
--- Handles line splitting and EOF clamping internally.
---@param buf integer
---@param sr integer
---@param sc integer
---@param er integer
---@param ec integer
---@param text string | string[]
function M.replace_range(buf, sr, sc, er, ec, text)
    local line_count = vim.api.nvim_buf_line_count(buf)
    if er >= line_count then
        er = line_count - 1
        ec = #vim.api.nvim_buf_get_lines(buf, er, er + 1, true)[1]
    end
    local lines = text
    if type(lines) == "string" then
        lines = vim.split(lines, "\n", { plain = true })
    end
    vim.api.nvim_buf_set_text(buf, sr, sc, er, ec, lines)
end

--- Insert a plain string at row and column
--- Handles line splitting and EOF clamping internally.
---@param buf integer
---@param sr integer
---@param sc integer
---@param text string | string[]
function M.insert_text(buf, sr, sc, text)
    M.replace_range(buf, sr, sc, sr, sc, text)
end

--- Delete text at row and column
--- Handles line splitting and EOF clamping internally.
---@param buf integer
---@param sr integer
---@param sc integer
---@param er integer
---@param ec integer
function M.delete_text(buf, sr, sc, er, ec)
    M.replace_range(buf, sr, sc, er, ec, {})
end

---@param fn function
function M.lockout_parinfer(fn)
    local parinfer_state = vim.g.parinfer_enabled
    vim.g.parinfer_enabled = false
    local ok, err = pcall(fn)
    vim.g.parinfer_enabled = parinfer_state
    if not ok then
        error(err, 0)
    end
end

--- Apply multiple edits without offset corruption.
--- Sorts bottom-up internally; callers don't think about order.
--- Each edit: { sr, sc, er, ec, text }
---@param buf integer
---@param edits { [1]: integer, [2]: integer, [3]: integer, [4]: integer, [5]: string|string[] }[]
function M.apply_disjoint_edits(buf, edits)
    M.lockout_parinfer(function()
        table.sort(edits, function(a, b)
            if a[1] ~= b[1] then
                return a[1] > b[1]
            end
            return a[2] > b[2]
        end)
        for _, e in ipairs(edits) do
            M.replace_range(buf, e[1], e[2], e[3], e[4], e[5])
        end
    end)
end

return M
