vim.g.is_nix = vim.g.is_nix or false
vim.g.is_nix_shim = vim.g.is_nix_shim or false

local bootstrap = require("bartbie.bootstrap")
-- i really just prefer to store plugins outside lua/ lol
bootstrap.install_plugins_loader()
-- HOTFIX
bootstrap.load_all_plugin_configs()
