{
  inputs,
  self,
  ...
}:
{
  perSystem =
    {
      pkgs,
      system,
      inputs',
      config,
      lib,
      mkNeovim,
      ...
    }:
    let
      # Pin wrapNeovimUnstable to avoid signature mismatches when overlay is applied externally
      pkgs-locked = inputs.nixpkgs.legacyPackages.${system};
      buildNeovim = (mkNeovim { inherit (pkgs-locked) wrapNeovimUnstable neovimUtils; }).override;

      shared = {
        src = self.lib.nvimPath;
        inherit (config.nvim) plugins extraPackages;
        customPluginDefaults.optional = false;
        viAlias = false;
      };
      variants = {
        release = { };
        dev = {
          dynamicConfig = true;
        };
      };
      channels = {
        inherit (config.nvim) stable nightly;
      };

      nvimPackages =
        {
          variant = lib.attrsToList variants;
          channel = lib.attrsToList channels;
        }
        |> lib.mapCartesianProduct (
          {
            variant,
            channel,
          }:
          {
            name = if variant.name == "release" then channel.name else "${channel.name}-${variant.name}";
            value = buildNeovim ({ neovim-unwrapped = channel.value; } // variant.value // shared);
          }
        )
        |> lib.listToAttrs
        |> (
          x:
          x
          // {
            clean = buildNeovim {
              neovim-unwrapped = config.nvim.nightly;
              src = pkgs.writeTextDir "init.lua" "";
              dynamicConfig = true;
              cleanRuntimePaths = false;
            };
          }
        );
    in
    {
      overlayAttrs = { inherit nvimPackages; };

      packages = (nvimPackages |> lib.mapAttrs' (n: v: lib.nameValuePair "nvim-${n}" v)) // {
        default = nvimPackages.nightly;
        nvim = nvimPackages.nightly;
      };
    };
}
