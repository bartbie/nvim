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
    exclude,
  }:
    overwriteRocksToml {
      inherit src name;
      data = readRocksToml {
        src = "${src}/rocks.toml";
        inherit exclude;
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
          local join = vim.fs.joinpath

          -- find our config
          local conf_path
          do
              local pwd = vim.env.PWD
              local nvim_root = vim.fs.root(pwd, {"init.lua"})
              local repo_root = not nvim_root and vim.fs.root(pwd, {"flake.nix"})
              conf_path = nvim_root or join(repo_root or pwd, "nvim")
          end

          -- hide the system-wide config
          do
            local rtp = vim.opt.runtimepath
            local system_conf = vim.fn.stdpath("config")
            if not system_conf:match("nix/store") then
                rtp:remove(system_conf)
                rtp:remove(join(system_conf, "after"))
            end
          end

          local init_path = join(conf_path, "init.lua")
          if #vim.fs.find(init_path) and vim.fn.filereadable(init_path) then
              vim.opt.packpath:prepend(conf_path)
              vim.opt.runtimepath:prepend(conf_path)
              vim.opt.runtimepath:append(join(conf_path, "after"))
              dofile(init_path)
          else
              vim.notify("shim couldn't find the config to load!")
          end
      end
    '';

  mkShimConfig = {src}:
    pkgs.runCommand "nvim-shim-config" {inherit src;} ''
      if [ -f "$src/rocks.toml" ]; then
        cp -r "$src/rocks.toml" .
      fi
      cp -r ${shim-init-lua}/init.lua .
      mkdir -p "$out"
      cp -r ./* "$out"
    '';
}
