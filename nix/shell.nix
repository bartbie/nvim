{pkgs, ...}: let
  mkShell = nvim:
    pkgs.mkShell {
      name = "nvim-nix-shell";
      packages =
        [nvim]
        ++ nvim.passthru.extraPackages
        ++ builtins.attrValues {
          inherit
            (pkgs)
            stylua
            alejandra
            nil
            luarocks
            busted-nlua
            ;
          inherit
            (pkgs.luajitPackages)
            luacheck
            ;
        };
    };

  inherit (pkgs) nvimPackages;
  stable = mkShell nvimPackages.stable-dev;
  nightly = mkShell nvimPackages.nightly-dev;
in {
  inherit stable nightly;
  default = nightly;
}
