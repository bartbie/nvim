{
  pkgs,
  # self,
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
}
