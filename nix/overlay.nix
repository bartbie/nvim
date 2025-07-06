# This overlay, when applied to nixpkgs, adds the final neovim derivation to nixpkgs.
{inputs}: final: prev: let
  pkgs = prev;
  inherit (pkgs) lib;

  inherit
    (pkgs.callPackage ./lib {
      # Make sure we use the pinned nixpkgs instance for wrapNeovimUnstable,
      # otherwise it could have an incompatible signature when applying this overlay.
      # pkgs-wrapNeovim = inputs.nixpkgs.legacyPackages.${pkgs.system};
      /*
      inherit pkgs-wrapNeovim;
      */
    })
    mkNeovim # This is the helper function that builds the Neovim derivation.
    mkWithNewRocksToml
    shim-init-lua
    ;

  neovim-nightly-unwrapped = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
  inherit (pkgs) neovim-unwrapped;
  ###

  src = mkWithNewRocksToml {
    src = ../nvim;
    exclude.plugins = [
      "rocks.nvim" # mkNeovim will add it
    ];
    exclude.rocks = [
    ];
  };

  use-rocks = false;

  plugins = builtins.attrValues ({
      inherit
        (pkgs.vimPlugins.nvim-treesitter)
        withAllGrammars
        ;

      inherit
        (pkgs.vimPlugins)
        # rocks-treesitter-nvim
        # rocks-lazy-nvim
        kanagawa-nvim
        vim-fugitive
        blink-cmp
        oil-nvim
        nvim-lspconfig
        lazydev-nvim
        conform-nvim
        fzf-lua
        mini-nvim
        which-key-nvim
        nvim-parinfer
        blink-compat
        conjure
        cmp-conjure
        ;
      # lazy = pkgs.vimUtils.buildVimPlugin {
      #   pname = "";
      #   src = ./.;
      #   version = "";
      # };
    }
    // (lib.optionalAttrs use-rocks {
      inherit
        (pkgs.vimPlugins)
        rocks-config-nvim
        ;
    }));

  extraPackages = builtins.attrValues {
    inherit
      (pkgs)
      lua-language-server
      nil
      gcc
      ripgrep
      fd
      luarocks
      ;
  };

  # we define both of them twice

  mkPkgNvim = neovim-unwrapped:
    mkNeovim {
      inherit src plugins extraPackages neovim-unwrapped;
      ignoreConfigRegexes = [
        "^lua/bartbie/bootstrap/rocks.lua" # we don't need rocks bootstrap
      ];
      withNvimRocks = use-rocks;
    };

  # nvim for devshell that dynamically loads config at runtime
  mkDevShellNvim = neovim-unwrapped:
    mkNeovim {
      inherit plugins extraPackages neovim-unwrapped;
      src = shim-init-lua;
      rocksConfigPath =
        /*
        lua
        */
        ''vim.fs.joinpath(vim.fs.root(vim.env.PWD, {"flake.nix"}), "nvim")'';
      withNvimRocks = use-rocks;
    };
in {
  # pass our extra packages via the overlay
  # maybe a bit ugly but hey it works
  bartbie-nvim-extraPackages = extraPackages;

  bartbie-nvim = mkPkgNvim neovim-unwrapped;
  bartbie-nvim-nightly = mkPkgNvim neovim-nightly-unwrapped;

  devShell-nvim = mkDevShellNvim neovim-unwrapped;
  devShell-nvim-nightly = mkDevShellNvim neovim-nightly-unwrapped;
}
