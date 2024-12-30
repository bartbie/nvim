local blink = require("blink.cmp")
blink.setup(
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    {
        -- 'default' for mappings similar to built-in completion
        -- 'super-tab' for mappings similar to vscode (tab to accept, arrow keys to navigate)
        -- 'enter' for mappings similar to 'super-tab' but with 'enter' to accept
        -- See the full "keymap" documentation for information on defining your own keymap.
        keymap = {
            preset = "enter",
            ["<Tab>"] = {
                "snippet_forward",
                "select_next",
                "fallback",
            },
            ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
        },
        completion = {
            list = {
                selection = function(ctx)
                    return ctx.mode == "cmdline" and "auto_insert" or "manual"
                end,
            },
            ghost_text = { enabled = true },
            menu = {
                draw = {
                    treesitter = { "lsp" },
                    columns = {
                        { "label", "label_description", gap = 1 },
                        { "kind_icon", "kind", gap = 1 },
                        { "source_name" },
                    },
                },
            },
            documentation = {
                auto_show = true,
                auto_show_delay_ms = 0,
            },
        },
        signature = { enabled = true },
        appearance = {
            -- Sets the fallback highlight groups to nvim-cmp's highlight groups
            -- Useful for when your theme doesn't support blink.cmp
            -- Will be removed in a future release
            use_nvim_cmp_as_default = true,
            -- Set to 'mono' for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
            -- Adjusts spacing to ensure icons are aligned
            nerd_font_variant = "mono",
        },

        -- Default list of enabled providers defined so that you can extend it
        -- elsewhere in your config, without redefining it, due to `opts_extend`
        sources = {
            default = { "lsp", "path", "snippets", "buffer", "lazydev" },
            providers = {
                lsp = { fallbacks = { "lazydev" } },
                lazydev = { name = "LazyDev", module = "lazydev.integrations.blink" },
            },
        },
    }
)

local servers = {
    lua_ls = {},
}

local lspconfig = require("lspconfig")
for name, opts in pairs(servers) do
    local overwrite = { capabilities = blink.get_lsp_capabilities(opts.capabilities) }
    lspconfig[name].setup(
        vim.tbl_extend("force", opts, overwrite)
    )
end

require("lazydev").setup({
    library = {
        -- See the configuration section for more details
        -- Load luvit types when the `vim.uv` word is found
        { path = "${3rd}/luv/library", words = { "vim%.uv" } },
    },
})
