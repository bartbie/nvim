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
          (final: prev: {
            neovim-nightly-unwrapped = neovim-nightly-overlay.packages.${system}.default;
          })
          neovim-overlay
          # This adds a function can be used to generate a .luarc.json
          # containing the Neovim API all plugins in the workspace directory.
          # The generated file can be symlinked in the devShell's shellHook.
          gen-luarc.overlays.default
        ];
      };
      mkShell = nvim: pkgs.mkShell {
        name = "bartbie-nvim-nix-shell";
        buildInputs = with pkgs;
          [
            # Tools for Lua and Nix development, useful for editing files in this repo
            stylua
            luajitPackages.luacheck
            alejandra
            nvim
          ]
          ++ pkgs.bartbie-nvim-extraPackages;
        shellHook = ''
          # symlink the .luarc.json generated in the overlay
          ln -fs ${pkgs.nvim-luarc-json} .luarc.json
        '';
      };
    in {
      packages = rec {
        nvim = pkgs.bartbie-nvim;
        nvim-nightly = pkgs.bartbie-nvim-nightly;
        default = nvim-nightly;
      };
      devShells = rec {
        stable = mkShell pkgs.devShell-nvim;
        nightly = mkShell pkgs.devShell-nvim-nightly;
        default = nightly;
      };
    })
    // {
      # You can add this overlay to your NixOS configuration
      overlays.default = neovim-overlay;
    };
}
