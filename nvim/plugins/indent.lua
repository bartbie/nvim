require("blink.indent").setup({
    mappings = require("bartbie.G").indent_mappings,
    static = {
        char = "▏",
    },
    scope = {
        char = "▏",
        -- enable to show underlines on the line above the current scope
        underline = {
            enabled = true,
        },
    },
})
