{ inputs, ... }:
{
  perSystem =
    { inputs', pkgs, ... }:
    {
      nixpkgsOverlays = [
        inputs.neorocks.overlays.default
        (
          # conjure build fail patch
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
          }
        )
        (_: prev: {
          vimPlugins = prev.vimPlugins // {
            codecompanion-nvim = prev.vimPlugins.codecompanion-nvim.overrideAttrs {
              src = inputs.codecompanion-nvim;
            };
            org-super-agenda-nvim = pkgs.vimUtils.buildVimPlugin {
              pname = "org-super-agenda.nvim";
              version = "unstable"; # idk
              src = inputs.org-super-agenda-nvim;
            };
            org-modern-nvim = pkgs.vimUtils.buildVimPlugin {
              pname = "org-modern.nvim";
              version = "unstable";
              src = inputs.org-modern-nvim;
            };
          };
        })
      ];
    };
}
