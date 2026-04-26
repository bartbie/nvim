{ lib, inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      fennel-nvim = pkgs.vimUtils.buildVimPlugin {
        name = "fennel-nvim";
        src = pkgs.runCommand "fennel-nvim-src" { } ''
          mkdir -p $out/lua
          cp ${pkgs.luajitPackages.fennel}/share/lua/5.1/fennel.lua $out/lua/fennel.lua
        '';
      };

      fennel-ls =
        let
          fennel-ls-docsets = pkgs.runCommand "fennel-ls-data" { } ''
            DOCSETS_PATH=$out/fennel-ls/docsets
            mkdir -p $DOCSETS_PATH
            cp ${inputs.fennel-ls-nvim-docsets} $DOCSETS_PATH/nvim.lua
          '';
        in
        pkgs.symlinkJoin {
          name = "fennel-ls";
          paths = [ pkgs.fennel-ls ];
          buildInputs = [ pkgs.makeWrapper ];
          postBuild = ''
            wrapProgram $out/bin/fennel-ls \
              --set XDG_DATA_HOME ${fennel-ls-docsets}
          '';
        };
    in
    {
      nvim.plugins = [ fennel-nvim ];
      nvim.extraPackages = [ fennel-ls ];
      packages = {
        inherit fennel-nvim fennel-ls;
        inherit (pkgs) fnlfmt;
      };
    };
}
