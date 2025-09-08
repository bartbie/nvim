{pkgs, ...}:
(builtins.removeAttrs pkgs.nvimPackages ["mkNeovim"])
// {
  default = pkgs.nvim;
  nvim = pkgs.nvim;
}
