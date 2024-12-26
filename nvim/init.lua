local is_nix
do
    local in_store = vim.v.progpath:match("nix/store") ~= nil
    local uses_flake = in_store
        and vim.iter(vim.opt.rtp:get()):any(function(s)
            return s:match("nix/store.*rocks")
        end)
    is_nix = uses_flake
end

local install_location
local rocks_config
if not is_nix then
    -- Specifies where to install/use rocks.nvim
    install_location = vim.fs.joinpath(vim.fn.stdpath("data"), "rocks")

    -- Set up configuration options related to rocks.nvim (recommended to leave as default)
    rocks_config = {
        rocks_path = vim.fs.normalize(install_location),
    }

    vim.g.rocks_nvim = rocks_config

    -- Configure the package path (so that plugin code can be found)
    local luarocks_path = {
        vim.fs.joinpath(rocks_config.rocks_path, "share", "lua", "5.1", "?.lua"),
        vim.fs.joinpath(rocks_config.rocks_path, "share", "lua", "5.1", "?", "init.lua"),
    }
    package.path = package.path .. ";" .. table.concat(luarocks_path, ";")

    -- Configure the C path (so that e.g. tree-sitter parsers can be found)
    local luarocks_cpath = {
        vim.fs.joinpath(rocks_config.rocks_path, "lib", "lua", "5.1", "?.so"),
        vim.fs.joinpath(rocks_config.rocks_path, "lib64", "lua", "5.1", "?.so"),
    }
    package.cpath = package.cpath .. ";" .. table.concat(luarocks_cpath, ";")

    -- Add rocks.nvim to the runtimepath
    vim.opt.runtimepath:append(
        vim.fs.joinpath(rocks_config.rocks_path, "lib", "luarocks", "rocks-5.1", "rocks.nvim", "*")
    )
end

-- If rocks.nvim is not installed then install it!
if not is_nix and not pcall(require, "rocks") then
    local rocks_location = vim.fs.joinpath(vim.fn.stdpath("cache"), "rocks.nvim")

    if not vim.uv.fs_stat(rocks_location) then
        -- Pull down rocks.nvim
        vim.fn.system({
            "git",
            "clone",
            "--filter=blob:none",
            "https://github.com/nvim-neorocks/rocks.nvim",
            rocks_location,
        })
    end

    -- If the clone was successful then source the bootstrapping script
    assert(vim.v.shell_error == 0, "rocks.nvim installation failed. Try exiting and re-entering Neovim!")

    vim.cmd.source(vim.fs.joinpath(rocks_location, "bootstrap.lua"))

    vim.fn.delete(rocks_location, "rf")
end

vim.notify("hello")
