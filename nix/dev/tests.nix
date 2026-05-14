{
  lib,
  inputs,
  self,
  ...
}:
{
  perSystem =
    {
      pkgs,
      config,
      buildNeovim,
      ...
    }:
    let
      inherit (config.testPackages) nlua busted;

      # CORRECTNESS: nlua and rest expect normal nvim name
      test-nvim = config.testPackages.test-nvim.override { appName = null; };
    in
    {
      testPackages = {
        test-nvim = buildNeovim {
          appName = "test-nvim";
          neovim-unwrapped = config.nvim.nightly;
          src = pkgs.writeTextDir "init.lua" "";
          dynamicConfig = true;
          inherit (config.nvim.test) plugins extraPackages;
        };

        nlua = pkgs.lua51Packages.nlua.overrideAttrs (oa: {
          postFixup = builtins.replaceStrings [ "${pkgs.neovim-unwrapped}" ] [ "${test-nvim}" ] oa.postFixup;
        });

        busted = lib.makeOverridable (
          (
            {
              neovim,
              nlua,
              busted,
            }:
            pkgs.writers.writeBashBin "busted"
              {
                makeWrapperArgs = [
                  "--prefix"
                  "PATH"
                  ":"
                  "${lib.makeBinPath [
                    neovim
                    (pkgs.lua5_1.withPackages (ps: [
                      busted
                      nlua
                    ]))
                  ]}"
                ];
              }
              # bash
              ''
                busted --lua=nlua "$@"
              ''
          )
            {
              inherit nlua;
              neovim = test-nvim;
              busted = pkgs.lua51Packages.busted;
            }
        );

        run-tests = lib.makeOverridable (
          (
            {
              neovim,
              busted,
            }:
            pkgs.writers.writeBashBin "run-tests"
              {
                makeWrapperArgs = [
                  "--prefix"
                  "PATH"
                  ":"
                  "${lib.makeBinPath [
                    neovim
                    busted
                  ]}"
                ];
              }
              # bash
              ''
                export HOME=$(mktemp -d)
                cd $(jj root)/nvim
                busted "$@"
              ''
          )
            {
              inherit busted;
              neovim = test-nvim;
            }
        );
      };
      checks =
        let
          mkNvimCheck =
            let
              our-busted = busted;
            in
            lib.makeOverridable (
              {
                name,
                src ? self.lib.nvimPath,
                busted ? our-busted,
                neovim ? test-nvim,
                extraArgs ? [ ],
                extraPackages ? [ ],
              }:
              pkgs.runCommand name
                {
                  nativeBuildInputs = [
                    neovim
                    busted
                  ]
                  ++ extraPackages;
                  inherit src;
                }
                ''
                  export HOME=$(mktemp -d)
                  cd $src
                  busted ${lib.escapeShellArgs extraArgs}
                  touch $out
                ''
            );

          inherit (inputs) git-hooks;
        in
        {
          nvim = mkNvimCheck { name = "nvim-tests"; };

          pre-commit-check = git-hooks.lib.${pkgs.system}.run {
            src = ../.;
            hooks = {
              treefmt.enable = true;
              treefmt.packageOverrides.treefmt = pkgs.fmt;
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
        };
    };
}
