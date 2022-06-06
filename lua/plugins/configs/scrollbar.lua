local colors = require("core.visuals").colors

require("scrollbar").setup({
    show_in_active_only = true,
    handlers = { search = true },
    marks = {
        Search = { color = colors.green },
        Error = { color = colors.red },
        Warn = { color = colors.yellow },
        Info = { color = colors.oceanblue },
        Hint = { color = colors.skyblue },
        Misc = { color = colors.purple },
    },
})
