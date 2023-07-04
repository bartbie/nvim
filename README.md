<div id="header" align="center">
    <h1>
    bartbie's Neovim config
    </h1>
    <img src="https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white" alt="Neovim"/>
    <img src="https://img.shields.io/badge/lua-%232C2D72.svg?style=for-the-badge&logo=lua&logoColor=white" alt="Lua"/>
</div>

## What's this about?
Neovim is a lightweight yet powerful text editor/IDE/[PDE](https://youtu.be/QMVIJhC9Veg) focused on extensibility and user ergonomics.
This config written in Lua is tailor-made for me for (completely subjective) maximum comfort and occasional productivity.
Enjoy if you want.

## File Structure and Architecture
This config is essentially divided into three parts:
1. `init.lua`, which, when put in `$XDG_CONFIG_HOME/nvim`, bootstraps the plugin manager and installs the plugin part,
2. `lua/bartbie`, which acts as a plugin that managers can download and load,
3. `assets`, which is a folder containing all the assets needed for the config that are not `lua` files.
 
```sh
bartbie/nvim
3. ├─ assets
   │  └─ lsp_configs
   │     └─ # config files of lsps, like pyrightconfig.json
2. ├─ lua
   │  └─ bartbie
   │     ├─ utils
   │     ├─ plugins
   │     │  └─ # specs of the plugins
   │     │ # modules not dependent on plugins other than lazy
   │     ├─ config.lua
   │     ├─ keymaps.lua
   │     ├─ autocmds.lua
   │     │ # plugin's init.lua and healthcheck
   │     ├─ health.lua
   │     └─ init.lua
1. └─  init.lua # nvim's init.lua
```
### Rationale
This architecture allows this config to pull updates via `lazy.nvim`, without the need for the user to pull the newest git changes themselves.

Moreover, by de facto separating `lua/bartbie/`, as it now acts as a standalone plugin, defining the Nix flake for the package turns out to be relatively easy. 
## Installation
### Nix
Use the provided flake.
### Nvim's config
Clone the repo either on `main` branch and let the `init.lua` handle the rest.
```sh
# change these if different XDG setup
mv .config/nvim .config/nvim.bak
mv ~/.local/share/nvim ~/.local/share/nvim.bak
git clone --depth 1 https://github.com/bartbie/nvim ~/.config/nvim
nvim
```
### manually added plugin (lazy.nvim)
I don't think anyone will particularly use this repo as a plugin in their very own config, but it is technically possible, and very much leveraged by the previously mentioned Installation strategies.

## Acknowledgments
Thanks to [@folke](https://github.com/folke) for creating both `lazy.nvim`, which powers this whole thing, and `LazyVim`, which I got inspired a lot while creating this personalized and lovely mess of a config.
