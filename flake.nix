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

          inherit (pkgs) lib;

          bins = with pkgs; [
            gcc
            cmake
            curl
            unzip
            git
            ripgrep
            fzf
            fd
            jq
          ];

          # make our config a plugin for nvim to load
          bartbie-config = pkgs.vimUtils.buildVimPlugin {
            name = "bartbie";
            src = ./.;
          };

          bartbie-neovim = pkgs.neovim.override
            {
              viAlias = true;
              vimAlias = true;
              # withNodeJs = true;
              # withPython3 = true;
              configure = {
                # since init.lua is outside our bartbie/ package,
                # we will add it manually
                customRC = "lua << EOF\n${pkgs.lib.readFile ./init.lua}\nEOF";
                packages.myPlugins = {
                  start = [ bartbie-config ];
                };
              };
            };

          # add runtime deps
          neovim = pkgs.symlinkJoin {
            name = "bartbie-nvim";
            paths = [ bartbie-neovim ] ++ bins;
            buildInputs = [ pkgs.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/nvim \
                --prefix PATH : ${lib.makeBinPath bins}
            '';
          };
        in
        rec {
          packages.bartbie-nvim = neovim;
          packages.default = packages.bartbie-nvim;
          apps.bartbie-nvim = flake-utils.lib.mkApp {
            drv = packages.bartbie-nvim;
            name = "bartbie-nvim";
            exePath = "/bin/nvim";
          };
          apps.default = apps.bartbie-nvim;
          devShell = pkgs.mkShell {
            packages = [ packages.bartbie-nvim ] ++ bins;
            shellHook = ''
                export NVIM_APPNAME=$PWD
            '';
          };
        }

      );
}
