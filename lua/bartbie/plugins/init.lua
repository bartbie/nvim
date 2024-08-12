-- [nfnl] Compiled from fnl/bartbie/plugins/init.fnl by https://github.com/Olical/nfnl, do not edit.
print("hello")
local function _1_(_, opts)
  require("kanagawa").setup(opts)
  return vim.cmd("colorscheme kanagawa")
end
return {{"Olical/conjure", branch = "master"}, {"nvim-treesitter/nvim-treesitter", event = {"BufReadPost", "BufNewFile"}, opts = {auto_install = false}}, {"rebelot/kanagawa.nvim", priority = 1000, enabled = true, config = _1_, lazy = false}}
