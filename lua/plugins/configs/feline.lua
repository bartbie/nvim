local fn = vim.fn
local feline = require("feline")
local vi_mode = require("feline.providers.vi_mode")
local lsp = require("feline.providers.lsp")

local mode = require("plugins.configs.gruvbox").mode
local background = require("plugins.configs.gruvbox").background
local gruvbox_material_palette = fn["gruvbox_material#get_palette"](mode, background)
local colors = {



}


-- library of components to use in components table
local comps = {



}


-- Initialize the components table
local components = {
    left = {
        active = {},
        inactive = {}
    },
    mid = {
        active = {},
        inactive = {}
    },
    right = {
        active = {},
        inactive = {}
    }
}

feline.setup()
