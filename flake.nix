{
  description = "bartbie Neovim config";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
  } @ inputs:
    flake-utils.lib.eachDefaultSystem
    (
      system: let
        pkgs = import nixpkgs {
          inherit system;
        };

        inherit (pkgs) lib;
        inherit (lib.trivial) pipe;

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

        bartbie-neovim =
          pkgs.neovim.override
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
                start = [bartbie-config];
              };
            };
          };

        # add runtime deps
        neovim = pkgs.symlinkJoin {
          name = "bartbie-nvim";
          paths = [bartbie-neovim] ++ bins;
          buildInputs = [pkgs.makeWrapper];
          postBuild = ''
            wrapProgram $out/bin/nvim \
              --prefix PATH : ${lib.makeBinPath bins}
          '';
        };
      in rec {
        packages.bartbie-nvim = neovim;
        packages.default = packages.bartbie-nvim;
        apps.bartbie-nvim = flake-utils.lib.mkApp {
          drv = packages.bartbie-nvim;
          name = "bartbie-nvim";
          exePath = "/bin/nvim";
        };
        apps.default = apps.bartbie-nvim;
        devShells.default = pkgs.mkShell {
          packages = let
            nfnl = pkgs.vimPlugins.nfnl;
            nfnl-scripts = pkgs.stdenv.mkDerivation {
              pname = "nfnl-scripts";
              version = nfnl.version;
              src = nfnl.src;
              buildInputs = with pkgs; [
                lua
                babashka
                makeWrapper
              ];
              dontUnpack = true;
              dontConfigure = true;
              dontBuild = true;
              installPhase = ''
                mkdir -p $out/share/script $out/bin

                cp -r $src/script $out/share/.
                chmod +x $out/share/script

                mv $out/share/script/bootstrap $out/bin/.
                mv $out/share/script/bootstrap-dev $out/bin/.
              '';
              postFixup = ''
                for s in $out/bin/*; do
                    wrapProgram $s \
                        --chdir "$out/share" \
                        --prefix PATH : ${lib.makeBinPath [pkgs.entr]}
                done
                for s in $out/share/script/*; do
                    wrapProgram $s \
                        --chdir "$out/share"
                done
              '';
            };
            nvim = pkgs.neovim.override {
              configure = {
                customRC = ''
                  source $MYVIMRC
                '';
		packages.NixBuiltPackage = with pkgs.vimPlugins; {
			start = [
				nvim-treesitter.withAllGrammars
			];
		};
              };
            };
          in
            [
              nvim
              nfnl-scripts
            ]
	    ++ (with pkgs; [
              stylua
	    ])
            ++ bins;
          shellHook = ''
            export MYVIMRC=$PWD/init.lua
          '';
        };
        devShell = devShells.default;
      }
    );
}
