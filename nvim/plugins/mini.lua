require("mini.bracketed").setup()
require("mini.pairs").setup()
require("mini.comment").setup()
require("mini.surround").setup()
require("mini.cursorword").setup()
require("mini.ai").setup({
    n_lines = 500,
    custom_textobjects = require("bartbie.G").custom_textobjects,
})
