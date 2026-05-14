{ lib, ... }:
{
  perSystem = {
    options.nvim = {
      plugins = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        description = "Vim plugins to include in the neovim build.";
        default = [ ];
      };
      extraPackages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        description = "Extra packages to include in the neovim build.";
        default = [ ];
      };

      test = {
        plugins = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          description = "Plugins to include in the neovim testing build.";
          default = [ ];
        };
        extraPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          description = "Packages to include in the neovim testing build.";
          default = [ ];
        };
      };
    };
  };
}
