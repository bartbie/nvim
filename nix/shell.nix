{pkgs, ...}: let
  mkShell = nvim:
    pkgs.mkShell {
      name = "bartbie-nvim-nix-shell";
      buildInputs =
        [nvim]
        ++ pkgs.bartbie-nvim-extraPackages
        ++ builtins.attrValues {
          inherit
            (pkgs)
            stylua
            alejandra
            nil
            ;
          inherit
            (pkgs.luajitPackages)
            luacheck
            ;
        };
    };

  stable = mkShell pkgs.devShell-nvim;
  nightly = mkShell pkgs.devShell-nvim-nightly;
in {
  inherit stable nightly;
  default = nightly;
}
