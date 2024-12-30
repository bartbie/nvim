vim.g.is_nix = vim.g.is_nix or false
vim.g.is_nix_shim = vim.g.is_nix_shim or false
local is_nix = vim.g.is_nix

if not is_nix then
    require("bartbie.bootstrap").bootstrap_rocks()
end
require("bartbie.config.options")
