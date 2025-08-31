local BG = require("bartbie.G")
require("mini.bracketed").setup()
require("mini.pairs").setup()
require("mini.comment").setup()
require("mini.surround").setup()
require("mini.cursorword").setup()
require("mini.ai").setup({
    n_lines = 500,
    custom_textobjects = BG.custom_textobjects,
})

require("mini.move").setup({
    -- disable all, they are set manually in plugin/keymap.lua
    mappings = {
        -- Move visual selection in Visual mode
        left = "",
        right = "",
        down = "",
        up = "",

        -- Move current line in Normal mode
        line_left = "",
        line_right = "",
        line_down = "",
        line_up = "",
    },
})
