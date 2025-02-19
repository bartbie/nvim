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
    neovim-overlay = import ./nix/neovim-overlay.nix {inherit inputs;};
  in
    flake-utils.lib.eachDefaultSystem
    (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          # Add the neovim nightly package to the list of packages.
          (_: _: {
            neovim-nightly-unwrapped = neovim-nightly-overlay.packages.${system}.default;
          })
          neovim-overlay
        ];
      };
      mkShell = nvim:
        pkgs.mkShell {
          name = "bartbie-nvim-nix-shell";
          buildInputs =
            [nvim]
            ++ pkgs.bartbie-nvim-extraPackages
            ++ builtins.attrValues {
              inherit
                (pkgs)
                stylua
                alejandra
                nil
                ;
              inherit
                (pkgs.luajitPackages)
                luacheck
                ;
            };
        };
    in {
      packages = let
        nvim = pkgs.bartbie-nvim;
        nvim-nightly = pkgs.bartbie-nvim-nightly;
      in {
        inherit nvim nvim-nightly;
        inherit (pkgs) bartbie-nvim bartbie-nvim-nightly;
        default = nvim-nightly;
      };
      devShells = let
        stable = mkShell pkgs.devShell-nvim;
        nightly = mkShell pkgs.devShell-nvim-nightly;
      in {
        inherit stable nightly;
        default = nightly;
      };
      formatter = pkgs.alejandra;
    })
    // {
      overlays.default = neovim-overlay;
    };
}
