{
  pkgs,
  lib,
  stdenv,
}:
with lib; let
  rpipe = ps: x: pipe x ps;
in rec {
  # Use this to create a plugin from a flake input
  mkNvimPlugin = src: pname:
    pkgs.vimUtils.buildVimPlugin {
      inherit pname src;
      version = src.lastModifiedDate;
    };
  # A plugin can either be a package or an attrset, such as
  # { plugin = <plugin>; # the package, e.g. pkgs.vimPlugins.nvim-cmp
  #   config = <config>; # String; a config that will be loaded with the plugin
  #   # Boolean; Whether to automatically load the plugin as a 'start' plugin,
  #   # or as an 'opt' plugin, that can be loaded with `:packadd!`
  #   optional = <true|false>; # Default: false
  #   ...
  # }

  # map string -> plugin from pkgs.vimPlugins
  mapNameToPlugin = rpipe [
    (builtins.replaceStrings ["."] ["-"])
    (x: pkgs.vimPlugins."${x}")
  ];

  mapNamesToPlugins = rpipe (with attrsets; [
    # (filterAttrs (_: v: builtins.isString v))
    (mapAttrsToList (n: _: (mapNameToPlugin n)))
  ]);

  # isPluginGit = v: v ? "git";
  # mapGitPluginsToBuild = rpipe (with attrsets; [
  #   (filterAttrs (_: isPluginGit))
  #   (mapAttrsToList (n: _: (mapNameToPlugin n)))
  # ]);

  readRocksToml = {
    src, # path
    exclude ? {}, # {plugins = [""], rocks = [""]}
    override ? {},
  }:
    with builtins; let
      default-exclude = {
        plugins = [
          /*
          "rocks.nvim"
          */
        ];
        rocks = [
          /*
          "toml"
          */
        ];
      };
      filterAttrsByName = keys: set:
        attrsets.filterAttrs (n: _: !(elem n keys)) set;
      exc = default-exclude // exclude;
      old = fromTOML (readFile src);
      new = {
        rocks = filterAttrsByName exc.rocks old.rocks;
        plugins = filterAttrsByName exc.plugins old.plugins;
      };
    in
      attrsets.recursiveUpdate old new;

  overwriteRocksToml = {
    data,
    src,
    name ? "nvim",
    toml-path ? "./rocks.toml",
  }: let
    inherit (pkgs.formats.toml {}) generate;
    rocks-toml = generate "rocks.toml" data;
  in
    pkgs.runCommand "${name}-rocks.nvim-overwritten" {
      inherit src;
    } ''
      cp -r "$src"/* .
      rm "${toml-path}"
      cp -r "${rocks-toml}" "${toml-path}"
      mkdir -p "$out"
      cp -r ./* "$out"
    '';

  mkWithNewRocksToml = {
    src,
    name ? "nvim",
    exclude ? {},
    override ? {},
  }:
    overwriteRocksToml {
      inherit src name;
      data = readRocksToml {
        src = "${src}/rocks.toml";
        inherit exclude override;
      };
    };

  # dofile hack
  # instead of putting the config files into nix store,
  # we dynamically load them at runtime
  # obv use it only for devShell running in same dir as repo

  shim-init-lua =
    pkgs.writeTextDir "init.lua"
    # lua
    ''
      do
          -- set global flag to mark our shim config
          vim.g.is_nix_shim = true

          local join = vim.fs.joinpath
	      local pwd = vim.env.PWD

          -- find our config
          local conf_path = (function()
	      local root = vim.fs.root(pwd, {"flake.nix"})
	      return join(root, "nvim")
          end)()

          local init_path = join(conf_path, "init.lua")
          if #vim.fs.find(init_path) and vim.fn.filereadable(init_path) then
              package.path = package.path .. ";" .. join(conf_path, "/?.lua")
              vim.opt.packpath:prepend(conf_path)
              vim.opt.runtimepath:prepend(conf_path)
              vim.opt.runtimepath:append(join(conf_path, "after"))
              dofile(init_path)
          else
              vim.notify("shim couldn't find the config to load!")
          end
      end
    '';
}
