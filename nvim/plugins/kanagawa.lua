local kanagawa = require("kanagawa")

kanagawa.setup({
    colors = {
        theme = {
            all = {
                ui = {
                    bg_gutter = "none",
                },
            },
        },
    },
    ---@param colors { theme: kanagawa.ThemeColors, palette: kanagawa.PaletteColors}
    overrides = function(colors)
        local theme = colors.theme
        local palette = colors.palette
        return {
            NormalFloat = { bg = "none" },
            FloatBorder = { bg = "none" },
            FloatTitle = { bg = "none" },

            -- Save an hlgroup with dark background and dimmed foreground
            -- so that you can use it where your still want darker windows.
            -- E.g.: autocmd TermOpen * setlocal winhighlight=Normal:NormalDark
            NormalDark = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m3 },

            -- Popular plugins that open floats will link to NormalFloat by default;
            -- set their background accordingly if you wish to keep them dark and borderless
            LazyNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },
            MasonNormal = { bg = theme.ui.bg_m3, fg = theme.ui.fg_dim },

            -- borderless Telescope
            TelescopeTitle = { fg = theme.ui.special, bold = true },
            TelescopePromptNormal = { bg = theme.ui.bg_p1 },
            TelescopePromptBorder = { fg = theme.ui.bg_p1, bg = theme.ui.bg_p1 },
            TelescopeResultsNormal = { fg = theme.ui.fg_dim, bg = theme.ui.bg_m1 },
            TelescopeResultsBorder = { fg = theme.ui.bg_m1, bg = theme.ui.bg_m1 },
            TelescopePreviewNormal = { bg = theme.ui.bg_dim },
            TelescopePreviewBorder = { bg = theme.ui.bg_dim, fg = theme.ui.bg_dim },

            -- dark cmp menu
            Pmenu = { fg = theme.ui.shade0, bg = theme.ui.bg_p1 },
            PmenuSel = { fg = "NONE", bg = theme.ui.bg_p2 },
            PmenuSbar = { bg = theme.ui.bg_m1 },
            PmenuThumb = { bg = theme.ui.bg_p2 },

            -- Alpha
            AlphaHeader = { fg = palette.lightBlue },
            -- AlphaHeader = { fg = palette.lotusTeal2 },
            AlphaButtons = { fg = palette.lotusYellow4 },
            AlphaShortcut = { fg = palette.oniViolet },
            AlphaFooter = { fg = palette.fujiGray },

            -- cmp kinds
            -- Cmp
            -- CmpDocumentation = {},
            -- CmpDocumentationBorder = {},

            -- CmpItemAbbr = {},
            -- CmpItemAbbrDeprecated = {},
            -- CmpItemAbbrMatch = {},
            -- CmpItemAbbrMatchFuzzy = {},

            -- CmpItemMenu = {},
            --
            -- CmpItemKindDefault = {},

            CmpItemKindKeyword = { fg = palette.lightBlue },

            CmpItemKindVariable = { fg = palette.oniViolet },
            CmpItemKindConstant = { fg = palette.lotusViolet4 },
            CmpItemKindReference = { fg = palette.oniViolet },
            -- CmpItemKindValue = {},
            CmpItemKindCopilot = { fg = palette.dragonTeal },

            CmpItemKindFunction = { fg = palette.springBlue },
            CmpItemKindMethod = { fg = palette.crystalBlue },
            CmpItemKindConstructor = {},

            CmpItemKindClass = { fg = palette.surimiOrange },
            CmpItemKindInterface = { fg = palette.surimiOrange },
            CmpItemKindStruct = { fg = palette.surimiOrange },
            CmpItemKindEvent = { fg = palette.surimiOrange },
            CmpItemKindEnum = { fg = palette.surimiOrange },
            CmpItemKindUnit = { fg = palette.surimiOrange },

            CmpItemKindModule = { fg = palette.autumnYellow },

            CmpItemKindProperty = { fg = palette.springGreen },
            CmpItemKindField = { fg = palette.springGreen },
            CmpItemKindTypeParameter = { fg = palette.springGreen },
            CmpItemKindEnumMember = { fg = palette.lotusGreen },
            CmpItemKindOperator = { fg = palette.springGreen },
            CmpItemKindSnippet = { fg = palette.fujiGray },

            IblRed = { fg = palette.dragonRed },
            IblYellow = { fg = palette.dragonYellow },
            IblBlue = { fg = palette.dragonBlue },
            IblOrange = { fg = palette.dragonOrange },
            IblGreen = { fg = palette.dragonGreen },
            -- IblViolet = { fg = palette.dragonViolet},
            -- IblCyan = { fg = palette.dragonTeal },
            IblAqua = { fg = palette.dragonAqua },
        }
    end,
})

vim.cmd("colorscheme kanagawa")
