local download_lazy = function()
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
end

local setup_lazy_with_plugins = function()
    require("lazy").setup({
        spec = {
            { import = "bartbie.plugins" },
        },
        performance = {
            -- TODO:
            -- find out where nix buildVimPlugin puts plugins and just add it instead
            reset_packpath = false,
            -- rtp = { paths = { } }
        },
        -- load the colorscheme when starting an installation during startup
        install = { colorscheme = { "kanagawa" } },
    })
end

download_lazy()
vim.g.mapleader = " "
setup_lazy_with_plugins()
require("bartbie").setup()
