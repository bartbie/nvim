{
  description = "bartbie Neovim config";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    systems.url = "github:nix-systems/default";
    neorocks = {
      url = "github:nvim-neorocks/neorocks";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        neovim-nightly.follows = "neovim-nightly-overlay";
      };
    };

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      # inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      neovim-nightly-overlay,
      systems,
      neorocks,
      git-hooks,
      ...
    }:
    let
      # shortened and dumbened down from github:bartbie/nixos
      forSystems =
        systems: fn:
        let
          addSystem = sys: (builtins.mapAttrs (_: outp: { ${sys} = outp; }));
        in
        builtins.foldl' nixpkgs.lib.recursiveUpdate { } (
          builtins.map (sys: addSystem sys (fn sys)) systems
        );

      # This is where the Neovim derivation is built.
      overlay = import ./nix/overlay.nix { inherit inputs; };

      conjure-patch =
        _: prev:
        let
          conjure-patched = prev.vimPlugins.conjure.overrideAttrs (p: {
            nvimSkipModules = (p.nvimSkipModules or [ ]) ++ [ "conjure-spec.process_spec" ];
          });
        in
        {
          vimPlugins = prev.vimPlugins // {
            conjure = conjure-patched;
            cmp-conjure = prev.vimPlugins.cmp-conjure.overrideAttrs (p: {
              nvimSkipModules = (p.nvimSkipModules or [ ]) ++ [ "cmp_conjure" ];
              dependencies = [ ];
            });
          };
        };
    in
    {
      overlays.default = overlay;
    }
    // (forSystems (import systems) (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            conjure-patch
            overlay
          ];
        };

        devPkgs = import nixpkgs {
          inherit system;
          overlays = [
            overlay
            (_: prev: { neovim-unwrapped = inputs.neovim-nightly-overlay.packages.${prev.system}.default; })
            (_: prev: { devFmt = prev.callPackage ./nix/fmt.nix { }; })
            inputs.neorocks.overlays.default
            conjure-patch
          ];
        };
      in
      {
        formatter = devPkgs.devFmt;
        packages = import ./nix/packages.nix pkgs;
        devShells = import ./nix/shell.nix devPkgs;
        checks = import ./nix/checks.nix (devPkgs // { inherit git-hooks; });
      }
    ));
}
