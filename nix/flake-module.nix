{
  lib,
  inputs,
  self,
  ...
}:
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
      config._module.args =
        let
          pkgs = import inputs.nixpkgs {
            inherit system;
            overlays = config.nixpkgsOverlays;
          };
          # Pin wrapNeovimUnstable to avoid signature mismatches when overlay is applied externally
          pkgs-locked = inputs.nixpkgs.legacyPackages.${system};
          mkNeovim = (import ./helpers/_mkNeovim.nix) { inherit self; } |> pkgs.callPackage;
          buildNeovim = (mkNeovim { inherit (pkgs-locked) wrapNeovimUnstable neovimUtils; }).override;
        in
        {
          inherit
            pkgs
            pkgs-locked
            mkNeovim
            buildNeovim
            ;
        };
    
      config.packages = config.testPackages;

      options = {
        nixpkgsOverlays = lib.mkOption {
          type = lib.types.listOf (lib.types.functionTo (lib.types.functionTo lib.types.attrs));
          description = "Overlays to apply to all nixpkgs instances.";
          default = [ ];
        };
        testPackages = lib.mkOption {
          type = lib.types.attrsOf lib.types.package;
          description = "Packages used for testing.";
          default = {};
        };
        nvim = {
          stable = lib.mkOption {
            type = lib.types.package; readOnly = true;
            description = "Stable neovim unwrapped package.";
            default = pkgs.neovim-unwrapped;
          };
          nightly = lib.mkOption {
            type = lib.types.package;
            readOnly = true;
            description = "Nightly neovim unwrapped package.";
            default = inputs'.neovim-nightly-overlay.packages.default;
          };
        };
      };
    };
}
