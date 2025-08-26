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
  mkWrapperArgs = {
    separators ? {},
    extra ? [],
  }: {
    set ? {},
    prefix ? {},
    suffix ? {},
  }: let
    clean = lib.filterAttrs (n: v: v != null);
    process = lib.mapAttrsToList (n: v: ''${n} "${v}"'');
    process-fix = lib.mapAttrsToList (n: v: ''${n} ${separators.${n}} "${v}"'');
    mapFlag = flag: builtins.map (x: "--${flag} ${x}");
  in
    extra
    ++ (mapFlag "set" (process (clean set)))
    ++ (mapFlag "prefix" (process-fix (clean prefix)))
    ++ (mapFlag "suffix" (process-fix (clean suffix)));

  mkNvim = {
    wrapNeovimUnstable,
    neovim-unwrapped,
    luaRc,
    config,
    overrideAttrs,
  }: let
    concatLines = ls: lib.concatLines (builtins.filter (x: x != null && x != "") (lib.flatten ls));

    # Wraps the user init.lua, prepends the lua lib directory to the RTP
    # and prepends the nvim and after directory to the RTP
    mkInitLua = {
      stdenv,
      src,
      init,
      hideSystemConfig ? true,
      beforeInit ? null,
      afterInit ? null,
    }: let
      # Split runtimepath into 3 directories:
      # - lua, to be prepended to the rtp at the beginning of init.lua
      # - nvim, containing plugin, ftplugin, ... subdirectories
      # - after, to be sourced last in the startup initialization
      # See also: https://neovim.io/doc/user/starting.html
      srcSplitByRtp = stdenv.mkDerivation {
        inherit src;
        name = "nvim-rtp";
        buildPhase = ''
          mkdir -p $out/nvim
          mkdir -p $out/lua
          rm init.lua
        '';

        installPhase = ''
          # Copy nvim/after only if it exists
          if [ -d "lua" ]; then
              cp -r lua $out/lua
              rm -r lua
          fi
          # Copy nvim/after only if it exists
          if [ -d "after" ]; then
              cp -r after $out/after
              rm -r after
          fi
          # Copy rest of nvim/ subdirectories only if they exist
          if [ ! -z "$(ls -A)" ]; then
              cp -r -- * $out/nvim
          fi
        '';
      };
      luaRcContent = concatLines [
        # lua
        ''
          vim.g.is_nix = true
          vim.loader.enable()
          -- prepend lua directory
          vim.opt.rtp:prepend('${srcSplitByRtp}/lua')
        ''
        (optionalString hideSystemConfig
          # lua
          ''
            -- hide the system-wide config
            do
                local stdp = vim.fn.stdpath
                local rtp = vim.opt.runtimepath
                local system_confs = {stdp("config"), unpack(stdp("config_dirs"))}
                for _, path in ipairs(system_confs) do
                    if not path:match("nix/store") then
                        rtp:remove(path)
                        rtp:remove(vim.fs.joinpath(path, "after"))
                    end
                end
            end
          '')
        beforeInit
        # Wrap init.lua
        # lua
        ''
          do
          ${init}
          end
        ''
        afterInit
        # Prepend nvim and after directories to the runtimepath
        # NOTE: This is done after init.lua,
        # because of a bug in Neovim that can cause filetype plugins
        # to be sourced prematurely, see https://github.com/neovim/neovim/issues/19008
        # We prepend to ensure that user ftplugins are sourced before builtin ftplugins.
        # lua
        ''
          vim.opt.rtp:prepend('${srcSplitByRtp}/nvim')
          vim.opt.rtp:prepend('${srcSplitByRtp}/after')
        ''
      ];
    in {
      inherit luaRcContent;
      rtpDrv = srcSplitByRtp;
    };

    # wrapNeovimUnstable is the nixpkgs utility function for building a Neovim derivation.
    wrapped = wrapNeovimUnstable neovim-unwrapped (config // {inherit (luaRc) luaRcContent;});
  in
    (wrapped.overrideAttrs overrideAttrs).overrideAttrs (prev: {passthru = lib.recursiveUpdate prev.passthru luaRc;});

  # dofile hack
  # instead of putting the config files into nix store,
  # we dynamically load them at runtime
  # obv use it only for devShell running in same dir as repo
  writeDynamicConfig = pkgs:
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
          local lua_patterns = {
            join(conf_path, "lua", "?.lua"),
            join(conf_path, "lua", "?", "init.lua"),
          }
          package.path = table.concat(lua_patterns, ";") .. ";" .. package.path
          dofile(init_path)
        else
          vim.notify("shim couldn't find the config to load!")
        end
      end
    '';

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

  optionalString = lib.optionalString;

  vimPackPluginsStr = devPlugins: let
    plugs = lib.generators.toLua {} (
      builtins.map (p: {
        inherit (p) name;
        src = p.url;
      })
      devPlugins
    );
  in
    optionalString (devPlugins != [])
    ''
      vim.pack.add(${plugs})
    '';

  when = cond: x:
    if cond
    then x
    else null;

  luapkgs = neovim-unwrapped.lua.pkgs;

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

  wrapArgs = mkWrapperArgs {
    separators = {
      PATH = ":";
      LUA_CPATH = ";";
      LUA_PATH = ";";
    };
  };

  dynConfigSrc = writeDynamicConfig pkgs;

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
      mkNvim {
        inherit wrapNeovimUnstable neovim-unwrapped;
        # The final init.lua content that we pass to the Neovim wrapper.
        luaRc = {
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
            (vimPackPluginsStr devPlugins)
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
              (wrapArgs {
                set = {
                  LIBSQLITE_CLIB_PATH = when withSqlite sqliteLibPath;
                  LIBSQLITE = when withSqlite sqliteLibPath;
                };
                prefix = {
                  PATH = mapBins (lib.optional withSqlite sqlite);
                };
              })
              # Lua libs
              (wrapArgs {
                suffix = {
                  # Native Lua libraries
                  LUA_CPATH = concatLibsPaths luapkgs.getLuaCPath extraLuaLibs;
                  # Lua libraries
                  LUA_PATH = concatLibsPaths luapkgs.getLuaPath extraLuaLibs;
                };
              })
              # nvim appname + extra packages
              (wrapArgs {
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
