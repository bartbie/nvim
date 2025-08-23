{pkgs, ...}:
pkgs.nvimPackages
// {
  default = pkgs.nvim;
  nvim = pkgs.nvim;
}
