{
  description = "bartbie Neovim config";

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./nix);

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
    neorocks = {
      url = "github:nvim-neorocks/neorocks";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        neovim-nightly.follows = "neovim-nightly-overlay";
      };
    };
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
    };
    org-super-agenda-nvim = {
      url = "github:hamidi-dev/org-super-agenda.nvim";
      flake = false;
    };

    org-modern-nvim = {
      url = "github:danilshvalov/org-modern.nvim";
      flake = false;
    };
  };
}
