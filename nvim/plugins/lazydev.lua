require("lazydev").setup({
    library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
        { path = "${3rd}/luassert/library", words = { "assert" } },
        { path = "${3rd}/busted/library", words = { "describe" } },
    },
})
