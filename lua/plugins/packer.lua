local fn = vim.fn
local install_path = fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
if fn.empty(fn.glob(install_path)) > 0 then
  packer_bootstrap = fn.system({'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path})
end

-- Packer can manage itself
local plugins = {'wbthomason/packer.nvim'}
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
