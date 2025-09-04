local bG = require("bartbie.G")

local M = {}

---@class bartbie.nix.Info
---@field is_nix boolean
---@field is_nix_shim boolean
---@field shell bartbie.nix.Info.Shell?

---@class bartbie.nix.Info.Shell
---@field purity "pure" | "impure"
---@field name string?
---@field ours boolean

---@return bartbie.nix.Info
function M.info()
    local is_nix = bG.is_nix
    local is_nix_shim = bG.is_nix_shim

    ---@type string?
    local in_nix_shell = vim.env.IN_NIX_SHELL

    local shell = in_nix_shell
        and {
            purity = in_nix_shell,
            name = vim.env.name or nil,
            ours = is_nix_shim,
        }

    return {
        is_nix = is_nix,
        is_nix_shim = is_nix_shim,
        shell = shell,
    }
end

---@return string?
function M.flake_root()
    local runtime = require("bartbie.runtime")
    if bG.is_nix_shim then
        vim.fs.parents("~")
        runtime.config_root("nvim")
    end
    return nil
end

-- TODO readd this func maybe as flake_root?
-- function find.loc_root(source, nix)
--     if nix and nix.is_nix then
--         if nix.shell.ours then
--             return fs.root(source, "flake.nix")
--         elseif nix.shell.exists and nix.shell.name:match("bartbie%-nvim%-nix%-shell") then
--             return fs.root(vim.env.PWD, "flake.nix")
--         else
--             return vim.NIL -- using this sentinel value is pretty ugly but eh
--         end
--     end
--     return fs.root(source, "flake.nix") or fs.root(source, "rocks.toml")
-- end

return M
