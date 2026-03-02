{
  perSystem =
    { pkgs, ... }:
    {
      nvim.plugins =
        let
          start = builtins.attrValues {
            inherit (pkgs.vimPlugins) nvim-nio;
          };
          opt = builtins.attrValues {
            inherit (pkgs.vimPlugins.nvim-treesitter) withAllGrammars;
            inherit (pkgs.vimPlugins)
              alpha-nvim
              blink-cmp
              blink-compat
              blink-indent
              cmp-conjure
              conform-nvim
              conjure
              crates-nvim
              dropbar-nvim
              fidget-nvim
              fzf-lua
              gitsigns-nvim
              kanagawa-nvim
              lazydev-nvim
              lualine-nvim
              mini-nvim
              neorg
              nvim-colorizer-lua
              nvim-hlslens
              nvim-lspconfig
              nvim-parinfer
              nvim-treesitter-textobjects
              oil-nvim
              rainbow-delimiters-nvim
              satellite-nvim
              todo-comments-nvim
              undotree
              vim-fugitive
              which-key-nvim
              wildfire-nvim
              ;
          };
        in
        start ++ opt;

      nvim.extraPackages = builtins.attrValues {
        inherit (pkgs)
          lua-language-server
          vscode-json-languageserver
          nil
          gcc
          ripgrep
          fd
          luarocks
          ;
      };
    };
}
