local toggleterm = require("toggleterm")
local terminal = require("toggleterm.terminal").Terminal

-- creates new terminal object
local function new_term(cmd)
    return terminal:new({ cmd = cmd, hidden = true })
end

-- returns a function that toggles the terminal
local function new_toggle(term)
    return function()
        term:toggle()
    end
end

-- creates new terminal object and returns a function that toggles it
local function new_cmd(cmd)
    local term = new_term(cmd)
    return function()
        term:toggle()
    end
end

local M = {}

M.functions = {
    new_term = new_term,
    new_toggle = new_toggle,
    new_cmd = new_cmd,
}

M.terminals = {
    python = new_cmd("python3"),
    lazygit = new_cmd("lazygit"),
}

M.setup = function()
    toggleterm.setup({
        size = 20,
        open_mapping = [[<c-\>]],
        hide_numbers = true,
        shade_filetypes = {},
        shade_terminals = true,
        shading_factor = 2,
        start_in_insert = true,
        insert_mappings = true,
        persist_size = true,
        direction = "float",
        close_on_exit = true,
        shell = vim.o.shell,
        float_opts = {
            border = "curved",
            winblend = 0,
            highlights = {
                border = "Normal",
                background = "Normal",
            },
        },
    })
    -- keymaps set in keymapping.lua
end

return M
