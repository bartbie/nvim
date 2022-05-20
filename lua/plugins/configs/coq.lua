vim.g.coq_settings = {
    ["auto_start"] = "shut-up"
}

require("coq_3p") {
    {
        src = "repl",
        sh = "zsh",
        shell = { p = "perl", n = "node"},
        max_lines = 99,
        deadline = 500,
        unsafe = { "rm", "poweroff", "mv"}
    },

    {
        src = "nvimlua",
        short_name = "nLUA",
        conf_only = true
    },

    {
        src = "bc",
        short_name = "MATH",
        precision = 6
    },

    {
        src = "orgmode",
        short_name = "ORG"
    },

    {
        src = "vim_dadbod_completion",
        short_name = "DB"
    },
}

vim.cmd('COQnow -s')
