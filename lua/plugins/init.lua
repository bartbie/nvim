-- automatically install Packer
local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  packer_bootstrap = fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
end

-- autocommand that reloads neovim automatically after saving pluginList.lua
vim.cmd([[
  augroup packer_user_config
    autocmd!
    autocmd BufWritePost pluginList.lua source <afile> | PackerSync
  augroup end
]])

local ok, packer = pcall(require, 'packer')
if not ok then
    return
end

-- have Packer use popup window
packer.init {
    display = {
        open_fn = function()
            return require("packer.util").float { border = "rounded" }
        end,
    },
}

-- Packer can manage itself
local plugins = {'wbthomason/packer.nvim'}
-- adding all plugins from pluginList.lua to 'plugins' table
for _, v in ipairs(require('plugins.pluginList')) do
        table.insert(plugins, v)
end

return require('packer').startup(function(use)

  -- My plugins here
  for _, v in ipairs(plugins) do
    use(v)
  end 

  -- Automatically set up your configuration after cloning packer.nvim
  -- Put this at the end after all plugins
  if packer_bootstrap then
    require('packer').sync()
  end
end)
