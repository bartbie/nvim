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
}
