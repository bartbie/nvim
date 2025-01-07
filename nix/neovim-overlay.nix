# This overlay, when applied to nixpkgs, adds the final neovim derivation to nixpkgs.
{inputs}: final: prev:
with final.pkgs.lib; let
  pkgs = final;

  # Make sure we use the pinned nixpkgs instance for wrapNeovimUnstable,
  # otherwise it could have an incompatible signature when applying this overlay.
  # pkgs-wrapNeovim = inputs.nixpkgs.legacyPackages.${pkgs.system};

  # This is the helper function that builds the Neovim derivation.
  mkNeovim = pkgs.callPackage ./mkNeovim.nix {/*inherit pkgs-wrapNeovim;*/};

  helpers = pkgs.callPackage ./overlay-helpers.nix {};

  inherit (helpers) mkWithNewRocksToml shim-init-lua;

  inherit (pkgs) neovim-nightly-unwrapped neovim-unwrapped;
  ###

  src = mkWithNewRocksToml {
    src = ../nvim;
    exclude.plugins = [
      "rocks.nvim" # mkNeovim will add it
    ];
    exclude.rocks = [
    ];
  };

  plugins = with pkgs.vimPlugins; [
    nvim-treesitter.withAllGrammars
  ];

  extraPackages = with pkgs; [
    lua-language-server
    nil
    gcc
    ripgrep
    fd
    luarocks
  ];

  # we define both of them twice

  mkPkgNvim = neovim-unwrapped: mkNeovim {
    inherit src plugins extraPackages neovim-unwrapped;
    ignoreConfigRegexes = [
      "^lua/bartbie/bootstrap/rocks.lua" # we don't need rocks bootstrap
    ];
  };

  # nvim for devshell that dynamically loads config at runtime
  mkDevShellNvim = neovim-unwrapped: mkNeovim {
    inherit plugins extraPackages neovim-unwrapped;
    src = shim-init-lua;
    rocksConfigPath =
      /*
      lua
      */
      ''vim.fs.joinpath(vim.fs.root(vim.env.PWD, {"flake.nix"}), "nvim")'';
  };

in {
  # pass our extra packages via the overlay
  # maybe a bit ugly but hey it works
  bartbie-nvim-extraPackages = extraPackages;

  bartbie-nvim = mkPkgNvim neovim-unwrapped;
  bartbie-nvim-nightly = mkPkgNvim neovim-nightly-unwrapped;

  devShell-nvim = mkDevShellNvim neovim-unwrapped;
  devShell-nvim-nightly = mkDevShellNvim neovim-nightly-unwrapped;

  # This can be symlinked in the devShell's shellHook
  nvim-luarc-json = final.mk-luarc-json {
    inherit plugins;
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
