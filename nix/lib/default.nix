{lib}: let
  # map string -> plugin from pkgs.vimPlugins
  mapNameToPlugin = pkgs: s:
    lib.pipe s [
      (builtins.replaceStrings ["."] ["-"])
      (x: pkgs.vimPlugins."${x}")
    ];
in {
  inherit mapNameToPlugin;

  # Use this to create a plugin from a flake input
  mkNvimPlugin = pkgs: src: pname:
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

  mapNamesToPlugins = attrs:
    lib.pipe attrs [
      # (filterAttrs (_: v: builtins.isString v))
      (lib.attrsets.mapAttrsToList (n: _: (mapNameToPlugin n)))
    ];

  # isPluginGit = v: v ? "git";
  # mapGitPluginsToBuild = rpipe (with attrsets; [
  #   (filterAttrs (_: isPluginGit))
  #   (mapAttrsToList (n: _: (mapNameToPlugin n)))
  # ]);

  # dofile hack
  # instead of putting the config files into nix store,
  # we dynamically load them at runtime
  # obv use it only for devShell running in same dir as repo

  shim-init-lua = pkgs:
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
