local blink = require("blink.cmp")
local from_keymap = require("bartbie.G").blink
blink.setup(
    ---@module 'blink.cmp'
    ---@type blink.cmp.Config
    {
        keymap = from_keymap.keymap,
        cmdline = from_keymap.cmdline,
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
                conjure = { name = "Conjure", module = "blink.compat.source" },
            },
        },
    }
)
