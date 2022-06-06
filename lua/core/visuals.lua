local M = {}

-- darker, meshes with editor's background
-- local bg = "#1d2021"
-- lighter, makes the statusline more distinct
local bg = "#282828"

M.colors = {
    bg = bg,
    black = bg,
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
}

return M
