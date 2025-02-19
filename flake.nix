{
  description = "bartbie Neovim config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    neovim-nightly-overlay,
    ...
  }: let
    # This is where the Neovim derivation is built.
    overlay = import ./nix/overlay.nix {inherit inputs;};
  in
    flake-utils.lib.eachDefaultSystem
    (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [overlay];
      };
    in {
      formatter = pkgs.alejandra;
      devShells = import ./nix/shell.nix pkgs;
      packages = import ./nix/packages.nix pkgs;
    })
    // {
      overlays.default = overlay;
    };
}
