return {
    --- load settings that are standalone from other plugins
    setup = function()
        require("bartbie.config.options")
        require("bartbie.config.autocmds")
        require("bartbie.config.keymaps")
    end,
}
