local M = {}

local symbols = require("bartbie.symbols")

local symbols_table = {
    [vim.diagnostic.severity.ERROR] = symbols.diagnostics.error,
    [vim.diagnostic.severity.WARN] = symbols.diagnostics.warn,
    [vim.diagnostic.severity.INFO] = symbols.diagnostics.info,
    [vim.diagnostic.severity.HINT] = symbols.diagnostics.hint,
}

---@param state boolean
---@param severity? vim.diagnostic.Severity
local function vl_enabled(state, severity)
    return state
        and {
            severity = severity,
            format = function(d)
                return ("%s %s [%s]"):format(symbols_table[d.severity], d.message, d.code)
            end,
        }
end

---@param state boolean
local function vt_enabled(state)
    return state
        and {
            prefix = "",
            format = function(d)
                return ("%s %s"):format(symbols_table[d.severity], d.message)
            end,
        }
end

local function curr_config()
    local prev_conf = vim.diagnostic.config()
    assert(prev_conf ~= nil, "vim.diagnostic.config is set to nil!")
    return {
        has_vl = not not prev_conf.virtual_lines,
        has_vt = not not prev_conf.virtual_text,
    }
end

function M.toggle_virt_diag()
    local prev = curr_config()
    if not prev.has_vl and not prev.has_vt then
        return
    end
    vim.diagnostic.config({
        virtual_lines = vl_enabled(not prev.has_vl),
        virtual_text = vt_enabled(not prev.has_vt),
    })
end

-- too tired to refactor this nicely
function M.toggle_virt_diag_err_only()
    local prev = curr_config()
    if not prev.has_vl and not prev.has_vt then
        return
    end
    vim.diagnostic.config({
        virtual_lines = vl_enabled(not prev.has_vl, vim.diagnostic.severity.ERROR),
        virtual_text = vt_enabled(not prev.has_vt),
    })
end

M.defaults = {
    signs = { text = symbols_table },
    virtual_lines = vl_enabled(false),
    virtual_text = vt_enabled(true),
    severity_sort = true,
}

return M
