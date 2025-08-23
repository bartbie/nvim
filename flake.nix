{
  description = "bartbie Neovim config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    systems.url = "github:nix-systems/default";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    neovim-nightly-overlay,
    systems,
    ...
  }: let
    # shortened and dumbened down from github:bartbie/nixos
    forSystems = systems: fn: let
      addSystem = sys: (builtins.mapAttrs (_: outp: {${sys} = outp;}));
    in
      builtins.foldl' nixpkgs.lib.recursiveUpdate {} (builtins.map (sys: addSystem sys (fn sys)) systems);

    # This is where the Neovim derivation is built.
    overlay = import ./nix/overlay.nix {inherit inputs;};
  in
    {
      overlays.default = overlay;
    }
    // (forSystems (import systems) (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [overlay];
      };
    in {
      formatter = pkgs.alejandra;
      devShells = import ./nix/shell.nix pkgs;
      packages = import ./nix/packages.nix pkgs;
    }));
}
