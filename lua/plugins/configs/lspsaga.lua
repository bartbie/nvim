local lib = require("core.lib")
local icons = lib.diagnostics_symbols

require("lspsaga").setup({
    error_sign = icons.error,
    warn_sign = icons.warn,
    hint_sign = icons.hint,
    infor_sign = icons.info,
    diagnostic_header_icon = " " .. icons.bug .. "  ",
    code_action_icon = icons.action .. " ",
})
