{pkgs, ...}: let
  inherit (pkgs) bartbie-nvim bartbie-nvim-nightly;
in {
  inherit bartbie-nvim bartbie-nvim-nightly;
  nvim = bartbie-nvim;
  nvim-nightly = bartbie-nvim-nightly;
  default = bartbie-nvim-nightly;
}
