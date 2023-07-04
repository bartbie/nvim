-- this file is used only when running as .config/nvim (or whatever your XDG setup is)
-- which is what i personally do

--- set up the config
--- runs only when in nvim's init.lua
---@param developing_mode boolean
---@param dev_path string
local function init(developing_mode, dev_path)
    -- set up lazy.nvim
    local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
    if not vim.loop.fs_stat(lazypath) then
        vim.fn.system({
            "git",
            "clone",
            "--filter=blob:none",
            "https://github.com/folke/lazy.nvim.git",
            "--branch=stable", -- latest stable release
            lazypath,
        })
    end
    vim.opt.rtp:prepend(lazypath)

    vim.g.mapleader = " "
    require("lazy").setup({
        spec = {
            -- manage self as a plugin
            { "bartbie/nvim", config = true, import = "bartbie.plugins", dev = developing_mode },
        },
        install = { colorscheme = { "kanagawa" } },
        defaults = { dev = { path = dev_path } },
    })
end

-- change it when developing or forking/using different machine
init(false, "~/Projects/Personal/Lua")
