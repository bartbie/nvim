local BG = require("bartbie.G")
require("mini.bracketed").setup()
require("mini.comment").setup()
require("mini.surround").setup()
require("mini.cursorword").setup()

require("mini.ai").setup({
    silent = true,
    n_lines = 1000,
    custom_textobjects = BG.custom_textobjects,
    search_method = "cover_or_next",
    mappings = BG.miniai_mappings,
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

require("mini.pairs").setup()
vim.api.nvim_create_autocmd("FileType", {
    group = require("bartbie.augroup")("mini_pairs_disable_in_lisps)"),
    pattern = { "fennel", "clojure", "scheme", "lisp", "racket", "janet" },
    callback = function(ev)
        vim.b[ev.buf].minipairs_disable = true
    end,
})
