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
    exclude, # {plugins = [""], rocks = [""]}
  }:
    with builtins; let
      inherit (fromTOML (readFile src)) plugins rocks;
      filterAttrsByName = keys: set:
        attrsets.filterAttrs (n: _: !(elem n keys)) set;
    in {
      rocks = filterAttrsByName exclude.rocks rocks;
      plugins = filterAttrsByName exclude.plugins plugins;
    };

  # dofile hack
  # instead of putting the config files into nix store,
  # we dynamically load them at runtime
  # obv use it only for devShell running in same dir as repo
  shim-init-lua =
    pkgs.writeTextDir "init.lua"
    # lua
    ''
      local __conf_path = vim.env.PWD .. "/nvim"
      if vim.fn.filereadable(__conf_path .. "/init.lua") then
          vim.opt.packpath:prepend(__conf_path)
          vim.opt.runtimepath:prepend(__conf_path)
          vim.opt.runtimepath:append(__conf_path .. "/after")
          dofile(__conf_path .. "/init.lua")
      end
    '';
}
