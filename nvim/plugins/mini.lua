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
