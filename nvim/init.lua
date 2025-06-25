vim.g.is_nix = vim.g.is_nix or false
vim.g.is_nix_shim = vim.g.is_nix_shim or false
local is_nix = vim.g.is_nix

if not is_nix then
    require("bartbie.bootstrap.rocks").bootstrap_rocks()
end

-- i really just prefer to store plugins outside lua/ lol
require("bartbie.bootstrap.plugins").bootstrap_plugins_loader()
-- HOTFIX
require("bartbie.bootstrap.plugins").load_all_plugin_configs()
