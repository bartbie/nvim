vim.g.is_nix = vim.g.is_nix or false
vim.g.is_nix_shim = vim.g.is_nix and vim.g.is_nix_shim or false

-- block from evaluating bootstrap twice
if package.loaded["bartbie.bootstrap"] then
    return
end

local bootstrap = require("bartbie.bootstrap")

bootstrap.setup_plugins_folder()
bootstrap.setup_ftonce_folders()

bootstrap.quickenter()
