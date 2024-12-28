{
  description = "bartbie Neovim config";

  inputs = {
    #  lua-language-server build's broken, this commit fixes it, remove later
    nixpkgs.url = "github:NixOS/nixpkgs/1a9767900c410ce390d4eee9c70e59dd81ddecb5";
    flake-utils.url = "github:numtide/flake-utils";
    gen-luarc.url = "github:mrcjkb/nix-gen-luarc-json";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    flake-utils,
    gen-luarc,
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
          neovim-overlay
          # This adds a function can be used to generate a .luarc.json
          # containing the Neovim API all plugins in the workspace directory.
          # The generated file can be symlinked in the devShell's shellHook.
          gen-luarc.overlays.default
        ];
      };
      shell = pkgs.mkShell {
        name = "nvim-devShell";
        buildInputs = with pkgs; [
          # Tools for Lua and Nix development, useful for editing files in this repo
          lua-language-server
          nil
          stylua
          luajitPackages.luacheck
          devShell-nvim
	  # keep it in sync with nvim deps
	  gcc
	  ripgrep
	  fd
	  luarocks
        ];
        shellHook = ''
          # symlink the .luarc.json generated in the overlay
          ln -fs ${pkgs.nvim-luarc-json} .luarc.json
        '';
      };
    in {
      packages = rec {
        nvim = pkgs.bartbie-nvim;
        default = nvim;
      };
      devShells = {
        default = shell;
      };
    })
    // {
      # You can add this overlay to your NixOS configuration
      overlays.default = neovim-overlay;
    };
}
