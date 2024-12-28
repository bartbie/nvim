# This overlay, when applied to nixpkgs, adds the final neovim derivation to nixpkgs.
{inputs}: final: prev:
with final.pkgs.lib; let
  pkgs = final;

  # Make sure we use the pinned nixpkgs instance for wrapNeovimUnstable,
  # otherwise it could have an incompatible signature when applying this overlay.
  pkgs-wrapNeovim = inputs.nixpkgs.legacyPackages.${pkgs.system};

  # This is the helper function that builds the Neovim derivation.
  mkNeovim = pkgs.callPackage ./mkNeovim.nix {inherit pkgs-wrapNeovim;};

  helpers = pkgs.callPackage ./overlay-helpers.nix {};

  inherit (helpers) readRocksToml mapNamesToPlugins shim-init-lua;

  ###

  rocks-toml = readRocksToml {
    src = ../nvim/rocks.toml;
    exclude.plugins = [
      # "rocks-treesitter.nvim"
      "rocks-git.nvim"
    ];
    exclude.rocks = [
    ];
  };

  all-plugins = with pkgs.vimPlugins; [
    nvim-treesitter.withAllGrammars
    rocks-nvim
  ];
  # ++ (mapNamesToPlugins rocks-toml.plugins);

  extraPackages = with pkgs; [
    lua-language-server
    nil
    gcc
    ripgrep
    fd
    luarocks
  ];
in {
  # pass our extra packages via the overlay
  # maybe a bit ugly but hey it works
  bartbie-nvim-extraPackages = extraPackages;

  bartbie-nvim = mkNeovim {
    plugins = all-plugins;
    inherit extraPackages;
  };

  # This can be symlinked in the devShell's shellHook
  nvim-luarc-json = final.mk-luarc-json {
    plugins = all-plugins;
  };

  # nvim for devshell that dynamically loads config at runtime
  devShell-nvim = mkNeovim {
    src = shim-init-lua;
    plugins = all-plugins;
    inherit extraPackages;
  };
  # You can add as many derivations as you like.
  # Use `ignoreConfigRegexes` to filter out config
  # files you would not like to include.
  #
  # For example:
  #
  # nvim-pkg-no-telescope = mkNeovim {
  #   plugins = [];
  #   ignoreConfigRegexes = [
  #     "^plugin/telescope.lua"
  #     "^ftplugin/.*.lua"
  #   ];
  #   inherit extraPackages;
  # };
}
