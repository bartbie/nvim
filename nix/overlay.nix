# This overlay, when applied to nixpkgs, adds the final neovim derivation to nixpkgs.
{inputs}: final: prev: let
  pkgs = prev;
  # Make sure we use the pinned nixpkgs instance for wrapNeovimUnstable,
  # otherwise it could have an incompatible signature when applying this overlay.
  pkgs-locked = inputs.nixpkgs.legacyPackages.${pkgs.system};

  mkNeovim = neovim-unwrapped:
    pkgs.callPackage ./mkNeovim {
      inherit (pkgs-locked) wrapNeovimUnstable neovimUtils;
      inherit neovim-unwrapped;
    };

  src = ../nvim;

  plugins = builtins.attrValues {
    inherit
      (pkgs.vimPlugins.nvim-treesitter)
      withAllGrammars
      ;

    inherit
      (pkgs.vimPlugins)
      mini-nvim
      # theme
      kanagawa-nvim
      # cmp
      blink-cmp
      blink-compat
      cmp-conjure
      # fs
      oil-nvim
      # lsp
      nvim-lspconfig
      lazydev-nvim
      # fmt
      conform-nvim
      # fzf
      fzf-lua
      # lisp
      nvim-parinfer
      # vcs
      vim-fugitive
      # repl
      conjure
      # hl
      nvim-colorizer-lua
      # ui
      which-key-nvim
      ;
  };

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

  nightly = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
  stable = pkgs.neovim-unwrapped;

  static = {};
  # nvim for devshell that dynamically loads config at runtime
  dynamic = {dynamicConfig = true;};

  shared = {
    inherit src;
    inherit plugins extraPackages;
    viAlias = false;
  };

  mk = dyn: nvim: mkNeovim nvim (dyn // shared);
in {
  nvim = final.nvimPackages.nightly;
  nvimPackages = {
    stable = mk static stable;
    nightly = mk static nightly;
    stable-dev = mk dynamic stable;
    nightly-dev = mk dynamic nightly;
  };
}
