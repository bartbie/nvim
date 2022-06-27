-- automatically install Packer
local fn = vim.fn
local install_path = fn.stdpath("data") .. "/site/pack/packer/start/packer.nvim"
local bootstrap = false

if fn.empty(fn.glob(install_path)) > 0 then
    bootstrap = fn.system({
        "git",
        "clone",
        "--depth",
        "1",
        "https://github.com/wbthomason/packer.nvim",
        install_path,
    })
    vim.cmd("packadd packer.nvim")
end

local packer = require("packer")

-- have Packer use popup window
packer.init({
    display = {
        open_fn = function()
            return require("packer.util").float({ border = "rounded" })
        end,
    },
})

-- adding all plugins from pluginList.lua to 'plugins' table
local plugins = require("plugins.pluginList")
-- Packer can manage itself
plugins.packer = { "wbthomason/packer.nvim" }

return packer.startup(function(use)
    -- My plugins here
    for _, v in pairs(plugins) do
        use(v)
    end

    -- Automatically set up your configuration after cloning packer.nvim
    -- Put this at the end after all plugins
    if bootstrap then
        packer.sync()
        vim.notify([[
        Packer is installing the Plugins,
        Please wait until finished,
        then restart Neovim
        ]])
    end
end)
