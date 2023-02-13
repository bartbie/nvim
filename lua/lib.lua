local M = {
    diagnostics_symbols = {
        error = "",
        warn = "",
        hint = "",
        info = "",
        other = "✓",
        action = "",
        bug = "",
    },
}

---@param name string
---@param symbol string
---@param use_space boolean | nil
local sign_define = function(name, symbol, use_space)
    if use_space == nil then
        use_space = true
    end
    vim.fn.sign_define(name, { text = symbol .. (use_space and " " or ""), texthl = name })
end

sign_define("DiagnosticSignError", M.diagnostics_symbols.error)
sign_define("DiagnosticSignWarn", M.diagnostics_symbols.warn)
sign_define("DiagnosticSignInfo", M.diagnostics_symbols.info)
sign_define("DiagnosticSignHint", M.diagnostics_symbols.hint)

return M
