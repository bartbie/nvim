local UTILS = require("bartbie.utils")
local LIB = UTILS.lib
return {
    {
        "folke/tokyonight.nvim",
        enabled = false,
        lazy = false,
        priority = 1000,
        opts = {
            style = "night",
        },
        -- opts = function()
        --     local util = require("tokyonight.util")
        --     return {
        --         style = "night",
        --         -- style = "moon",
        --         ---@param c ColorScheme "#0db9d7"
        --         on_colors = function(c)
        --             -- c.bg = util.lighten(c.black, 0.99)
        --         end,
        --
        --         ---@param hl Highlights
        --         ---@param c ColorScheme
        --         on_highlights = function(hl, c)
        --             -- local prompt = "#2d3149"
        --
        --             hl.Type.fg = util.lighten(c.yellow, 0.9)
        --             hl["@keyword"].fg = util.lighten(c.red, 0.9)
        --             -- hl["@keyword.return"].fg = c.red
        --
        --             -- hl.TelescopeNormal = {
        --             --     bg = c.bg_dark,
        --             --     fg = c.fg_dark,
        --             -- }
        --             -- hl.TelescopeBorder = {
        --             --     bg = c.bg_dark,
        --             --     fg = c.bg_dark,
        --             -- }
        --             -- hl.TelescopePromptNormal = {
        --             --     bg = prompt,
        --             -- }
        --             -- hl.TelescopePromptBorder = {
        --             --     bg = prompt,
        --             --     fg = prompt,
        --             -- }
        --             -- hl.TelescopePromptTitle = {
        --             --     bg = prompt,
        --             --     fg = prompt,
        --             -- }
        --             -- hl.TelescopePreviewTitle = {
        --             --     bg = c.bg_dark,
        --             --     fg = c.bg_dark,
        --             -- }
        --             -- hl.TelescopeResultsTitle = {
        --             --     bg = c.bg_dark,
        --             --     fg = c.bg_dark,
        --             -- }
        --             --
        --         end,
        --     }
        -- end,
        config = function(_, opts)
            local tokyonight = require("tokyonight")
            tokyonight.setup(opts)
            vim.cmd("colorscheme tokyonight")
        end,
    },
    {
        "rebelot/kanagawa.nvim",
        lazy = false,
        priority = 1000,
        enabled = true,
        opts = {
            colors = {
                theme = {
                    all = {
                        ui = {
                            bg_gutter = "none",
                        },
                    },
                },
            },
            ---@param colors { theme: ThemeColors, palette: PaletteColors}
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
        },
        config = function(_, opts)
            require("kanagawa").setup(opts)
            vim.cmd("colorscheme kanagawa")
        end,
    },
    { "nvim-tree/nvim-web-devicons" },
    { "MunifTanjim/nui.nvim" },
    {
        "rcarriga/nvim-notify",
        keys = {
            {
                "<leader>on",
                function()
                    require("notify").dismiss({ silent = true, pending = true })
                end,
                desc = "Delete all Notifications",
            },
        },
        opts = {
            timeout = 3000,
            max_height = function()
                return math.floor(vim.o.lines * 0.75)
            end,
            max_width = function()
                return math.floor(vim.o.columns * 0.75)
            end,
        },
    },
    {
        "stevearc/dressing.nvim",
        lazy = true,
        init = function()
            vim.ui.select = function(...)
                require("lazy").load({ plugins = { "dressing.nvim" } })
                return vim.ui.select(...)
            end
            vim.ui.input = function(...)
                require("lazy").load({ plugins = { "dressing.nvim" } })
                return vim.ui.input(...)
            end
        end,
    },
    {
        "folke/noice.nvim",
        event = "VeryLazy",
        opts = {
            lsp = {
                override = {
                    ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
                    ["vim.lsp.util.stylize_markdown"] = true,
                },
            },
            presets = {
                bottom_search = true,
                command_palette = true,
                long_message_to_split = true,
                inc_rename = true,
            },
        },
        config = function(_, opts)
            local noice = require("noice")
            noice.setup(opts)
            vim.lsp.handlers["textDocument/hover"] = noice.hover
            vim.lsp.handlers["textDocument/signatureHelp"] = noice.signature
        end,
    },
    {
        "akinsho/bufferline.nvim",
        event = "VeryLazy",
        version = "v3.*",
        dependencies = "nvim-tree/nvim-web-devicons",
        keys = {
            { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle pin" },
            { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete non-pinned buffers" },
        },
        opts = {
            options = {
                always_show_bufferline = false,
                diagnostics = "nvim_lsp",
                diagnostics_indicator = function(_, _, diag)
                    local icons = LIB.diagnostics_symbols.core
                    local ret = (diag.error and icons.error .. diag.error .. " " or "")
                        .. (diag.warning and icons.warn .. diag.warning or "")
                    return vim.trim(ret)
                end,
                -- NOTE: this will be called a lot so don't do any heavy processing here
                custom_filter = function(buf_number)
                    local types = LIB.special_types
                    local filetype = vim.bo[buf_number].filetype
                    local bufname = vim.fn.bufname(buf_number)
                    local buftype = vim.bo[buf_number].buftype
                    return not (
                        vim.tbl_contains(types.filetypes, filetype)
                        or vim.tbl_contains(types.bufnames, bufname)
                        or vim.tbl_contains(types.buftypes, buftype)
                    )
                end,
                offsets = {
                    {
                        filetype = "neo-tree",
                        -- text = "Neo-tree",
                        text = "♪.ılılıll|̲̅̅●̲̅̅|̲̅̅=̲̅̅|̲̅̅●̲̅̅|llılılı.♪",
                        highlight = "Directory",
                        text_align = "center",
                    },
                },
                hover = {
                    enabled = true,
                    delay = 200,
                    reveal = { "close" },
                },
            },
        },
    },
    {
        "nvim-lualine/lualine.nvim",
        -- for some reasom, after we moved to config-as-plugin,
        -- this cannot be lazy or we get vanilla statusline when opening neovim
        -- event = "VeryLazy",
        opts = function()
            local theme = require("lualine.themes.auto")
            for _, mode in ipairs(vim.tbl_keys(theme)) do
                -- theme[mode].b.bg = theme.normal.c.bg
                theme[mode].b = theme.normal.c
            end

            local function get_curr_mode()
                return require("lualine.highlight").get_mode_suffix():gsub("_", "")
            end

            local function color_text(_)
                return { fg = theme[get_curr_mode()].a.bg }
            end

            ---create simple extention
            ---@param filetypes string[]
            ---@param text function | string | nil
            ---@param rest? table | nil
            ---@return table
            local function create_extention(filetypes, text, rest)
                local lualine_a = { { "mode" } }
                if text then
                    lualine_a[1].fmt = type(text) == "function" and text
                        or function()
                            return text
                        end
                end
                lualine_a[1] = vim.tbl_extend("force", lualine_a[1], rest or {})
                -- vim.notify(vim.inspect(lualine_a))
                return {
                    filetypes = filetypes,
                    sections = {
                        lualine_a = lualine_a,
                        lualine_b = { { "branch", color = color_text } },
                    },
                }
            end

            local function get_short_cwd()
                return vim.fn.fnamemodify(vim.fn.getcwd(), ":~")
            end

            return {
                options = {
                    theme = function()
                        return theme
                    end,
                    globalstatus = true,
                    disabled_filetypes = { statusline = { "dashboard", "alpha" } },
                    component_separators = { left = "", right = "" },
                    section_separators = { left = "", right = "" },
                },
                sections = {
                    lualine_a = { "mode" },
                    lualine_b = {
                        { "filetype", icon_only = true, separator = "", padding = { left = 1, right = 0 } },
                        {
                            "filename",
                            path = 1,
                            symbols = { modified = "", readonly = "✘", unnamed = "", new = "" },
                        },
                    },
                    lualine_c = {
                        {
                            "branch",
                            color = color_text,
                        },
                        {
                            "diff",
                            source = function()
                                local gitsigns = vim.b.gitsigns_status_dict
                                if gitsigns then
                                    return {
                                        added = gitsigns.added,
                                        modified = gitsigns.changed,
                                        removed = gitsigns.removed,
                                    }
                                end
                            end,
                        },
                        --- macro recording
                        {
                            padding = { right = 0 },
                            function(_, _)
                                return "@"
                            end,
                            cond = function(_, _)
                                local rec_reg = vim.fn.reg_recording()
                                return rec_reg ~= ""
                            end,
                            color = color_text,
                        },
                        {
                            padding = { left = 0 },
                            function(_, _)
                                return vim.fn.reg_recording()
                            end,
                        },
                    },

                    lualine_x = {
                        { "diagnostics", symbols = LIB.diagnostics_symbols.core },
                        --- lsp server display
                        {
                            --- lsp icon
                            "filetype",
                            icon_only = true,
                            separator = "",
                            padding = { left = 1, right = 0 },
                            cond = function()
                                local no_clients = next(vim.lsp.get_active_clients({ bufnr = 0 })) == nil
                                return not no_clients
                            end,
                        },
                        {
                            --- lsp names
                            function(_, _)
                                local servers = {}
                                local tools = {}
                                local buf_clients = vim.lsp.get_active_clients({ bufnr = 0 })
                                for _, client in ipairs(buf_clients) do
                                    -- null-ls gathers each of its tools into one client
                                    if client.name == "null-ls" then
                                        local nls = require("null-ls")
                                        for _, tool in ipairs(nls.get_source({ filetype = vim.bo.filetype })) do
                                            table.insert(tools, tool.name)
                                        end
                                    else
                                        table.insert(servers, client.name)
                                    end
                                end
                                return table.concat(servers, " ") .. " " .. table.concat(tools, " ")
                            end,
                        },
                    },
                    lualine_y = {
                        { "encoding", fmt = string.upper },
                        {
                            "fileformat",
                            symbols = {
                                unix = UTILS.os.is_macos and "" or "",
                                dos = "",
                                mac = "",
                            },
                            padding = { left = 1, right = 0 },
                            color = color_text,
                        },
                        {
                            "fileformat",
                            symbols = {
                                unix = "UNIX",
                                dos = "DOS",
                                mac = "MAC",
                            },
                            padding = { left = 0, right = 1 },
                        },
                        "progress",
                        "selectioncount",
                    },
                    lualine_z = {
                        {
                            "location",
                            fmt = function(str, _)
                                return " " .. vim.trim(str) .. " "
                            end,
                        },
                    },
                },
                extensions = {
                    "lazy",
                    "fugitive",
                    "man",
                    -- "neo-tree",
                    "nvim-dap-ui",
                    "quickfix",
                    -- "symbols-outline",
                    "toggleterm",
                    "trouble",
                    create_extention({ "TelescopePrompt" }, "Telescope", {
                        color = function()
                            local mode = get_curr_mode()
                            return mode == "command" and theme.normal.a or theme[mode].a
                        end,
                    }),
                    create_extention({ "undotree" }, "Undo-tree"),
                    create_extention({ "Outline" }, "Outline"),
                    create_extention({ "neo-tree" }, get_short_cwd),
                },
            }
        end,
        config = function(_, opts)
            local lualine = require("lualine")
            lualine.setup(opts)
            -- https://www.reddit.com/r/neovim/comments/xy0tu1/comment/irfegvd
            -- ^ thanks
            vim.api.nvim_create_autocmd("RecordingEnter", {
                callback = function()
                    lualine.refresh({
                        place = { "statusline" },
                    })
                end,
            })
            vim.api.nvim_create_autocmd("RecordingLeave", {
                callback = function()
                    -- This is going to seem really weird!
                    -- Instead of just calling refresh we need to wait a moment because of the nature of
                    -- `vim.fn.reg_recording`. If we tell lualine to refresh right now it actually will
                    -- still show a recording occuring because `vim.fn.reg_recording` hasn't emptied yet.
                    -- So what we need to do is wait a tiny amount of time (in this instance 50 ms) to
                    -- ensure `vim.fn.reg_recording` is purged before asking lualine to refresh.
                    local timer = vim.loop.new_timer()
                    timer:start(
                        50,
                        0,
                        vim.schedule_wrap(function()
                            lualine.refresh({
                                place = { "statusline" },
                            })
                        end)
                    )
                end,
            })
        end,
    },
    {
        "utilyre/barbecue.nvim",
        name = "barbecue",
        event = { "BufReadPre", "BufNewFile" },
        version = "*",
        cmd = "Barbecue",
        keys = {
            {
                "<leader>cn",
                "n",
                function()
                    require("barbecue.ui").toggle()
                end,
                desc = "Toggle code navigation",
            },
        },
        dependencies = {
            "SmiteshP/nvim-navic",
            "nvim-tree/nvim-web-devicons",
        },
        opts = {
            kinds = LIB.cmp_icons,
        },
    },
    {
        "goolord/alpha-nvim",
        event = "VimEnter",
        opts = function()
            local logo = {
                [[    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿    ]],
                [[    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⣠⣶⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿    ]],
                [[    ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣡⣾⣿⣿⣿⣿⣿⢿⣿⣿⣿⣿⣿⣿⣟⠻⣿⣿⣿⣿⣿⣿⣿⣿⣿    ]],
                [[    ⣿⣿⣿⣿⣿⣿⣿⣿⡿⢫⣷⣿⣿⣿⣿⣿⣿⣿⣾⣯⣿⡿⢧⡚⢷⣌⣽⣿⣿⣿⣿⣿⣶⡌⣿⣿⣿⣿⣿⣿⣿    ]],
                [[    ⣿⣿⣿⣿⣿⣿⣿⣿⠇⢸⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣮⣇⣘⠿⢹⣿⣿⣿⣿⣿⣻⢿⣿⣿⣿⣿⣿⣿    ]],
                [[    ⣿⣿⣿⣿⣿⣿⣿⣿⠀⢸⣿⣿⡇⣿⣿⣿⣿⣿⣿⣿⣿⡟⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣦⣻⣿⣿⣿⣿⣿    ]],
                [[    ⣿⣿⣿⣿⣿⣿⣿⡇⠀⣬⠏⣿⡇⢻⣿⣿⣿⣿⣿⣿⣿⣷⣼⣿⣿⣸⣿⣿⣿⣿⣿⣿⣿⣿⣿⢻⣿⣿⣿⣿⣿    ]],
                [[    ⣿⣿⣿⣿⣿⣿⣿⠀⠈⠁⠀⣿⡇⠘⡟⣿⣿⣿⣿⣿⣿⣿⣿⡏⠿⣿⣟⣿⣿⣿⣿⣿⣿⣿⣿⣇⣿⣿⣿⣿⣿    ]],
                [[    ⣿⣿⣿⣿⣿⣿⡏⠀⠀⠐⠀⢻⣇⠀⠀⠹⣿⣿⣿⣿⣿⣿⣩⡶⠼⠟⠻⠞⣿⡈⠻⣟⢻⣿⣿⣿⣿⣿⣿⣿⣿    ]],
                [[    ⣿⣿⣿⣿⣿⣿⡇⠀⠀⠀⠀⠀⢿⠀⡆⠀⠘⢿⢻⡿⣿⣧⣷⢣⣶⡃⢀⣾⡆⡋⣧⠙⢿⣿⣿⣟⣿⣿⣿⣿⣿    ]],
                [[    ⣿⣿⣿⣿⣿⣿⡿⠀⠀⠀⠀⠀⠀⠀⡥⠂⡐⠀⠁⠑⣾⣿⣿⣾⣿⣿⣿⡿⣷⣷⣿⣧⣾⣿⣿⣿⣿⣿⣿⣿⣿    ]],
                [[    ⣿⣿⡿⣿⣍⡴⠆⠀⠀⠀⠀⠀⠀⠀⠀⣼⣄⣀⣷⡄⣙⢿⣿⣿⣿⣿⣯⣶⣿⣿⢟⣾⣿⣿⢡⣿⣿⣿⣿⣿⣿    ]],
                [[    ⣿⡏⣾⣿⣿⣿⣷⣦⠀⠀⠀⢀⡀⠀⠀⠠⣭⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠟⣡⣾⣿⣿⢏⣾⣿⣿⣿⣿⣿⣿    ]],
                [[    ⣿⣿⣿⣿⣿⣿⣿⣿⡴⠀⠀⠀⠀⠀⠠⠀⠰⣿⣿⣿⣷⣿⠿⠿⣿⣿⣭⡶⣫⠔⢻⢿⢇⣾⣿⣿⣿⣿⣿⣿⣿    ]],
                [[    ⣿⣿⣿⡿⢫⣽⠟⣋⠀⠀⠀⠀⣶⣦⠀⠀⠀⠈⠻⣿⣿⣿⣾⣿⣿⣿⣿⡿⣣⣿⣿⢸⣾⣿⣿⣿⣿⣿⣿⣿⣿    ]],
                [[    ⡿⠛⣹⣶⣶⣶⣾⣿⣷⣦⣤⣤⣀⣀⠀⠀⠀⠀⠀⠀⠉⠛⠻⢿⣿⡿⠫⠾⠿⠋⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿    ]],
                [[    ⢀⣾⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣀⡆⣠⢀⣴⣏⡀⠀⠀⠀⠉⠀⠀⢀⣠⣰⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿    ]],
                [[    ⠿⠛⠛⠛⠛⠛⠛⠻⢿⣿⣿⣿⣿⣯⣟⠷⢷⣿⡿⠋⠀⠀⠀⠀⣵⡀⢠⡿⠋⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿    ]],
                [[    ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠉⠛⢿⣿⣿⠂⠀⠀⠀⠀⠀⢀⣽⣿⣿⣿⣿⣿⣿⣿⣍⠛⠿⣿⣿⣿⣿⣿⣿⣿    ]],
                [[                               __                ]],
                [[  ___     ___    ___   __  __ /\_\    ___ ___    ]],
                [[ / _ `\  / __`\ / __`\/\ \/\ \\/\ \  / __` __`\  ]],
                [[/\ \/\ \/\  __//\ \_\ \ \ \_/ |\ \ \/\ \/\ \/\ \ ]],
                [[\ \_\ \_\ \____\ \____/\ \___/  \ \_\ \_\ \_\ \_\]],
                [[ \/_/\/_/\/____/\/___/  \/__/    \/_/\/_/\/_/\/_/]],
                -- [[       Neovim  Genesis  Evangelion      ]],
                --                   --                   --
            } --

            local DASH = require("alpha.themes.dashboard")
            local buttons = {
                DASH.button("f", " " .. " Find file", ":Telescope find_files <CR>"),
                DASH.button("n", " " .. " New file", ":ene <BAR> startinsert <CR>"),
                DASH.button("h", " " .. " Recent files", ":Telescope oldfiles <CR>"),
                DASH.button("g", " " .. " Find text", ":Telescope live_grep <CR>"),
                DASH.button("c", " " .. " Config", ":e $MYVIMRC <CR>"),
                DASH.button("s", " " .. " Restore Session", [[:lua require("persistence").load() <cr>]]),
                DASH.button("l", "󰒲 " .. " Lazy", ":Lazy<CR>"),
                DASH.button("q", " " .. " Quit", ":qa<CR>"),
            }

            DASH.section.header.val = logo
            DASH.section.buttons.val = buttons

            for _, button in ipairs(DASH.section.buttons.val) do
                button.opts.hl = "AlphaButtons"
                button.opts.hl_shortcut = "AlphaShortcut"
            end
            DASH.section.header.opts.hl = "AlphaHeader"
            DASH.section.buttons.opts.hl = "AlphaButtons"
            DASH.section.footer.opts.hl = "AlphaFooter"
            DASH.opts.layout[1].val = 8
            return DASH
        end,
        config = function(_, DASH)
            -- close Lazy and re-open when the dashboard is ready
            if vim.o.filetype == "lazy" then
                vim.cmd.close()
                vim.api.nvim_create_autocmd("User", {
                    pattern = "AlphaReady",
                    callback = function()
                        require("lazy").show()
                    end,
                })
            end

            require("alpha").setup(DASH.opts)

            vim.api.nvim_create_autocmd("User", {
                callback = function()
                    local stats = require("lazy").stats()
                    local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
                    local ver = vim.version()
                    local version = ver and " " .. ver.major .. "." .. ver.minor .. "." .. ver.patch or ""
                    DASH.section.footer.val = (
                        "  Neovim"
                        .. version
                        .. " loaded "
                        .. stats.count
                        .. " plugins in "
                        .. ms
                        .. "ms"
                    )
                    pcall(vim.cmd.AlphaRedraw)
                end,
            })
        end,
    },
}
