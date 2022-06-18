local M = {}

M.colors = {
    -- took it from bufferline highlight group, i have no idea where it came from but it's cool
    dark_bg = "#151818",
    -- darker, meshes with editor's background
    darker_bg = "#1d2021",
    -- lighter, makes the statusline more distinct
    bg = "#282828",
    black = "#282828",
    yellow = "#fabd2f",
    aqua = "#8ec07c",
    oceanblue = "#45707a",
    green = "#b8bb26",
    orange = "#fe8019",
    magenta = "#c14a4a",
    white = "#ebdbb2",
    fg = "#ebdbb2",
    skyblue = "#7daea3",
    red = "#fb4934",
    purple = "#d3869b",
}

M.diagnostics_symbols = {
    error = "",
    warn = "",
    hint = "",
    info = "",
    other = "✓",
    action = "",
    bug = "",
}

M.special_types = {
    filetypes = {
        "NvimTree",
        "dbui",
        "packer",
        "startify",
        "fugitive",
        "gitcommit",
        "fugitiveblame",
        "Trouble",
        "TelescopePrompt",
    },
    buftypes = {},
    bufnames = {},
}
return M
