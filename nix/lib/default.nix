{
  pkgs,
  lib,
  stdenv,
  # Set by the overlay to ensure we use a compatible version of `wrapNeovimUnstable`
  pkgs-wrapNeovim ? pkgs,
} @ args:
{
  mkNeovim = import ./mkNeovim.nix args;
}
// (import ./overlay-helpers.nix args)
