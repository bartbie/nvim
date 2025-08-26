local todo = require("todo-comments")
-- TODO
-- add lower-case HL
todo.setup({
    keywords = {
        SAFETY = { icon = "󰖷 ", color = "safety" },
        INVARIANT = { icon = " ", color = "warning", alt = { "CORRECTNESS" } },
    },
    colors = {
        safety = { "@keyword.exception" },
    },
    highlight = {
        keyword = "bg",
        pattern = [[\c.*<(KEYWORDS)\s*]],
    },
    search = {
        command = "rg",
        args = {
            "--color=never",
            "--no-heading",
            "--with-filename",
            "--line-number",
            "--column",
            "--ignore-case",
        },
        pattern = [[\b(KEYWORDS):]], -- ripgrep regex
    },
})
