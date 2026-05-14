{
  description = "bartbie Neovim config";

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./nix);

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    neovim-nightly-overlay.url = "github:nix-community/neovim-nightly-overlay";
    systems.url = "github:nix-systems/default";
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:vic/import-tree";
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

    fennel-ls-nvim-docsets = {
      url = "https://git.sr.ht/~micampe/fennel-ls-nvim-docs/blob/main/nvim.lua";
      flake = false;
    };
  };
}
