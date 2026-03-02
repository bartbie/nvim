{ pkgs, ... }:
let
  devFmt = pkgs.devFmt;
  mkShell =
    nvim:
    pkgs.mkShell {
      name = "nvim-nix-shell";
      packages = [
        nvim
        devFmt
      ]
      ++ nvim.passthru.extraPackages
      ++ devFmt.passthru.runtimeInputs
      ++ builtins.attrValues {
        inherit (pkgs)
          nil
          luarocks
          busted-nlua
          ;
        inherit (pkgs.luajitPackages)
          luacheck
          ;
      };
    };

  inherit (pkgs) nvimPackages;
  stable = mkShell nvimPackages.stable-dev;
  nightly = mkShell nvimPackages.nightly-dev;
in
{
  inherit stable nightly;
  default = nightly;
}
