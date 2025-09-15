{
  lib,
  runCommand,
  makeBinaryWrapper,
  treefmt,
  # runtimeInputs:
  nixfmt,
  stylua,
  prettier,
}:
let
  name = "treefmt";
  runtimeInputs = [
    nixfmt
    stylua
    prettier
  ];
in
runCommand name
  {
    nativeBuildInputs = [ makeBinaryWrapper ];
    treefmtExe = lib.getExe treefmt;
    binPath = lib.makeBinPath runtimeInputs;
    passthru = { inherit runtimeInputs; };
    inherit (treefmt) meta version;
  }
  ''
    mkdir -p $out/bin
    makeWrapper \
      $treefmtExe \
      $out/bin/treefmt \
      --prefix PATH : "$binPath"
  ''
