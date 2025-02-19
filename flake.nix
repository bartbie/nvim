{
  description = "bartbie Neovim config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    gen-luarc.url = "github:mrcjkb/nix-gen-luarc-json";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    gen-luarc,
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
          # This adds a function can be used to generate a .luarc.json
          # containing the Neovim API all plugins in the workspace directory.
          # The generated file can be symlinked in the devShell's shellHook.
          gen-luarc.overlays.default
        ];
      };
      mkShell = nvim:
        pkgs.mkShell {
          name = "bartbie-nvim-nix-shell";
          buildInputs = with pkgs;
            [
              stylua
              luajitPackages.luacheck
              alejandra
              nvim
              nil
            ]
            ++ pkgs.bartbie-nvim-extraPackages;
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
    })
    // {
      overlays.default = neovim-overlay;
    };
}
