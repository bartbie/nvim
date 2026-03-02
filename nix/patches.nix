{ inputs, ... }:
{
  perSystem =
    { inputs', ... }:
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
      ];
    };
}
