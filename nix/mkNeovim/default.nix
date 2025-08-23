# Function for creating a Neovim derivation
{
  pkgs,
  lib,
  stdenv,
  sqlite,
  neovim-unwrapped,
  # Set by the overlay to ensure we use a compatible version of `wrapNeovimUnstable`
  wrapNeovimUnstable,
  neovimUtils, # not used for now
}: let
  # This is the structure of a plugin definition.
  # Each plugin in the `plugins` argument list can also be defined as this attrset
  PLUGIN_DEFAULTS = {
    plugin = null; # e.g. nvim-lspconfig
    config = null; # plugin config
    # If `optional` is set to `false`, the plugin is installed in the 'start' packpath
    # set to `true`, it is installed in the 'opt' packpath, and can be lazy loaded with
    # ':packadd! {plugin-name}
    optional = false;
    runtime = {};
  };

  internal = import ./internal.nix {inherit lib;};
  luapkgs = neovim-unwrapped.lua.pkgs;

  inherit
    (internal)
    when
    ;

  inherit
    (lib)
    optionalString
    ;

  # Map all plugins to an attrset { plugin = <plugin>; config = <config>; optional = <tf>; ... }
  normalizePlugins = let
    coerceToPlugin = x:
      PLUGIN_DEFAULTS
      // (
        if x ? plugin
        then x
        else {plugin = x;}
      );
  in (map coerceToPlugin);

  mkPathFilter = src: regexes: path: _: let
    srcPrefix = builtins.toString src + "/";
    relPath = lib.removePrefix srcPrefix (builtins.toString path);
  in
    lib.all (regex: builtins.match regex relPath == null) regexes;

  mkWrapperArgs = internal.mkWrapperArgs {
    separators = {
      PATH = ":";
      LUA_CPATH = ";";
      LUA_PATH = ";";
    };
  };

  dynConfigSrc = internal.writeDynamicConfig pkgs;

  sqliteLibPath = "${sqlite.out}/lib/libsqlite3${stdenv.hostPlatform.extensions.sharedLibrary}";

  concatLibsPaths = fn: libs: when (libs != []) (lib.concatMapStringsSep ";" fn libs);
  mapBins = packages: when (packages != []) (lib.makeBinPath packages);
in
  {
    # NVIM_APPNAME - Defaults to 'nvim' if not set.
    # If set to something else, this will also rename the binary.
    appName ? "nvim",
    plugins ? [], # List of plugins
    # List of dev plugins (will be bootstrapped) - useful for plugin developers
    # { name = <plugin-name>; url = <git-url>; }
    devPlugins ? [],
    # Regexes for config files to ignore, relative to the nvim directory.
    # e.g. [ "^plugin/neogit.lua" "^ftplugin/.*.lua" ]
    ignoreConfigRegexes ? [],
    extraPackages ? [], # Extra runtime dependencies (e.g. ripgrep, ...)
    # The below arguments can typically be left as their defaults
    # Additional lua packages (not plugins), e.g. from luarocks.org.
    # e.g. p: [p.jsregexp]
    extraLuaPackages ? p: [],
    extraPython3Packages ? p: [], # Additional python 3 packages
    withPython3 ? true, # Build Neovim with Python 3 support?
    withRuby ? false, # Build Neovim with Ruby support?
    withNodeJs ? false, # Build Neovim with NodeJS support?
    withSqlite ? true, # Add sqlite? This is a dependency for some plugins
    # You probably don't want to create vi or vim aliases
    # if the appName is something different than "nvim"
    viAlias ? appName == "nvim", # Add a "vi" binary to the build output as an alias?
    vimAlias ? appName == "nvim", # Add a "vim" binary to the build output as an alias?
    wrapRc ? true,
    dynamicConfig ? false, # Don't use src, instead use init.lua shim that will try to load real config during startup
    src ?
      if dynamicConfig
      then dynConfigSrc
      else ../../nvim, # Use this repo as src?
    hideSystemConfig ? true, # Remove stdpath("config"|"configdirs") from RTP?
  }:
    assert dynamicConfig -> (src == dynConfigSrc); let
      appName' =
        if (appName == null || appName == "")
        then "nvim"
        else appName;
      isCustomAppName = appName' != "nvim";

      extraLuaLibs = extraLuaPackages luapkgs;
    in
      internal.mkNvim {
        inherit wrapNeovimUnstable neovim-unwrapped;
        luaRc =
          # The final init.lua content that we pass to the Neovim wrapper.
          internal.mkInitLua {
            inherit hideSystemConfig;
            inherit stdenv;
            src = lib.cleanSourceWith {
              inherit src;
              name = "${appName'}-src-filtered";
              filter = mkPathFilter src ignoreConfigRegexes;
            };
            init = builtins.readFile (src + /init.lua);
            beforeInit = [];
            afterInit = [
              # Bootstrap/load dev plugins
              (internal.vimPackPluginsStr devPlugins)
            ];
          };
        config = {
          inherit
            extraPython3Packages
            withPython3
            withRuby
            withNodeJs
            viAlias
            vimAlias
            wrapRc
            ;
          plugins = normalizePlugins plugins;
          wrapperArgs = builtins.concatStringsSep " " (
            lib.flatten [
              # Sqlite
              (mkWrapperArgs {
                set = {
                  LIBSQLITE_CLIB_PATH = when withSqlite sqliteLibPath;
                  LIBSQLITE = when withSqlite sqliteLibPath;
                };
                prefix = {
                  PATH = mapBins (lib.optional withSqlite sqlite);
                };
              })
              # Lua libs
              (mkWrapperArgs {
                suffix = {
                  # Native Lua libraries
                  LUA_CPATH = concatLibsPaths luapkgs.getLuaCPath extraLuaLibs;
                  # Lua libraries
                  LUA_PATH = concatLibsPaths luapkgs.getLuaPath extraLuaLibs;
                };
              })
              # nvim appname + extra packages
              (mkWrapperArgs {
                set = {
                  NVIM_APPNAME = when isCustomAppName appName';
                };
                prefix = {
                  # Add external packages to the PATH
                  PATH = mapBins extraPackages;
                };
              })
            ]
          );
        };
        overrideAttrs = prev: {
          buildPhase =
            prev.buildPhase
            + optionalString isCustomAppName ''
              mv $out/bin/nvim $out/bin/${lib.escapeShellArg appName'}
            '';
          passthru = lib.recursiveUpdate prev.passthru {inherit extraPackages;};
          meta.mainProgram =
            if isCustomAppName
            then appName'
            else prev.meta.mainProgram;
        };
      }
