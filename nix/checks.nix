{
  pkgs,
  git-hooks,
  ...
}: {
  nvim = pkgs.neorocksTest {
    src = ../nvim; # Project containing the rockspec and .busted files.
    # Plugin name. If running multiple tests,
    # you can use pname for the plugin name instead
    name = "nvim";
    pname = "bartbie-nvim";
    version = "scm-1"; # Optional, defaults to "scm-1";
    neovim = pkgs.neovim-nightly; # Optional, defaults to neovim-nightly.
    luaPackages = ps: [ps.nvim-nio];
    extraPackages = []; # Optional. External test runtime dependencies.
  };

  pre-commit-check = git-hooks.lib.${pkgs.system}.run {
    src = ../.;
    hooks = {
      alejandra.enable = true;
      stylua.enable = true;
      luacheck.enable = true;
      editorconfig-checker.enable = true;
      markdownlint.enable = true;
      markdownlint.settings.configuration = {
        "MD013" = false; # Line length
        "MD041" = false; # First line heading requirement
        "MD033" = false; # Inline HTML elements
        # "MD009" = false; # Trailing spaces
      };
    };
  };
}
