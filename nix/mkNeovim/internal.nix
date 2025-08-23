{lib, ...}: let
  optionalString = lib.optionalString;

  concatLines = ls: lib.concatLines (builtins.filter (x: x != null && x != "") (lib.flatten ls));
in {
  inherit concatLines;

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

  when = cond: x:
    if cond
    then x
    else null;

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
          dofile(init_path)
        else
          vim.notify("shim couldn't find the config to load!")
        end
      end
    '';
}
