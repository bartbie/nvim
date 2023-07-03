{
  description = "bartbie Neovim config";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils } @ inputs:
    flake-utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
          dependencies = with pkgs; [
            fzf
            gcc
            ripgrep
            git
            curl
          ];

          # make our config a plugin for nvim to load
          bartbie-config = pkgs.vimUtils.buildVimPlugin {
            name = "bartbie-config";
            src = ./lua/bartbie;
          };
          # add dependencies for our plugins to neovim
          neovim-modified = pkgs.neovim-unwrapped.overrideAttrs (old: {
            buildInputs = old.buildInputs ++ dependencies;
          });
        in
        rec {
          packages.bartbie-nvim = pkgs.wrapNeovim neovim-modified
            {
              viAlias = true;
              vimAlias = true;
              # withNodeJs = true;
              # withPython3 = true;
              configure = {
                # since init.lua is outside our bartbie/ package,
                # we will add it manually
                customRC = ''
                  lua << EOF
                ''
                + pkgs.lib.readFile ./init.lua +
                ''
                  EOF
                '';
                packages.myPlugins = {
                  start = [ bartbie-config ];
                };
              };
            };
          packages.default = packages.bartbie-nvim;
          apps.bartbie-nvim = flake-utils.lib.mkApp {
            drv = packages.bartbie-nvim;
            name = "bartbie-nvim";
            exePath = "/bin/nvim";
          };
          apps.default = apps.bartbie-nvim;
          devShell = pkgs.mkShell {
            buildInputs = [ packages.bartbie-nvim ] ++ dependencies;
          };
        }

      );
}
