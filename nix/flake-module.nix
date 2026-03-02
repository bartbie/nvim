{ lib, inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.easyOverlay ];

  systems = import inputs.systems;

  perSystem =
    {
      system,
      pkgs,
      inputs',
      config,
      ...
    }:
    {
      config._module.args.pkgs = import inputs.nixpkgs {
        inherit system;
        overlays = config.nixpkgsOverlays;
      };

      options = {
        nixpkgsOverlays = lib.mkOption {
          type = lib.types.listOf (lib.types.functionTo (lib.types.functionTo lib.types.attrs));
          description = "Overlays to apply to all nixpkgs instances.";
          default = [ ];
        };
        nvim = {
          stable = lib.mkOption {
            type = lib.types.package;
            readOnly = true;
            description = "Stable neovim unwrapped package.";
            default = pkgs.neovim-unwrapped;
          };
          nightly = lib.mkOption {
            type = lib.types.package;
            readOnly = true;
            description = "Nightly neovim unwrapped package.";
            default = inputs'.neovim-nightly-overlay.packages.default;
          };

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
        };
      };
    };
}
