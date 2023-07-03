require("bartbie.config") -- load options just to be sure
return {
    { "folke/lazy.nvim", version = "*" },
    { "bartbie/nvim", priority = 10000, lazy = false, config = true, cond = true, version = "*" },
}
