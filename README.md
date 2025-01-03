<div id="header" align="center">
    <h1>
    bartbie's Neovim config
    </h1>
    <img src="https://img.shields.io/badge/NeoVim-%2357A143.svg?&style=for-the-badge&logo=neovim&logoColor=white" alt="Neovim"/>
    <img src="https://img.shields.io/badge/lua-%232C2D72.svg?style=for-the-badge&logo=lua&logoColor=white" alt="Lua"/>
    <img src="https://img.shields.io/badge/nix-0175C2?style=for-the-badge&logo=NixOS&logoColor=white" alt="Nix"/>

</div>

## What's this about?
My spin on [PDE](https://youtu.be/QMVIJhC9Veg).

## File Structure and Architecture
 
```sh
nvim
├─ flake.nix
├─ flake.lock
├─ nvim                # sorted by order of initialization
│  ├─ init.lua         # entry-point
│  ├─ rocks.toml
│  ├─ lua              # lazy-loaded
│  │  └─ bartbie
│  │     ├─ health.lua
│  │     ├─ *          # my std-lib
│  │     └─ bootstrap
│  │        └─ *       # logic needed for bootstrapping
│  ├─ plugin
│  │  └─ *             # general non-plugin-specific configs
│  ├─ plugins
│  │  └─ *             # 3rd-party-plugins configs 
│  └─ after
│     └─ *             # configs (lazy-)loaded after everything else
└─ nix
   └─ *                # nix helpers
```

Follows Neovim's [order of initialization](https://neovim.io/doc/user/starting.html#_initialization)
with an added twist of plugins configs loaded after `plugin` (but before `after`).

`lua/` acts as the project's library and is not loaded unless explicitly by a `require` in configs.

## Installation

#### Nix

Use the provided flake.

You can use the provided devShell to hack on lua without needing to nix rebuild it everytime.

#### Non-Nix

Clone the repo's `nvim` folder

<br/>

`:Rocks sync` to install needed plugins

`:healthcheck` to check config's health

## Licensing

This repository as a whole is licensed under the GNU General Public License v2.0 (GPL-2.0), the same license as the template it is based on.

However, only files originating from the template's nix configuration are subject to the GPL.

All other files in this repository are original to this project and are dual-licensed under the MIT license.

You may freely reuse these non-GPL files under the terms of either the GPL or MIT license, at your discretion.
