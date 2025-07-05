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
        cmdline = {
            keymap = {
                preset = "enter",
                ["<Tab>"] = {
                    "show",
                    "snippet_forward",
                    "select_next",
                    "fallback",
                },
                ["<S-Tab>"] = { "snippet_backward", "select_prev", "fallback" },
            },
        },
        completion = {
            list = {
                selection = {
                    preselect = false,
                    auto_insert = function(ctx)
                        return ctx.mode == "cmdline"
                    end,
                },
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
            kind_icons = require("bartbie.symbols").lsp_kind,
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
