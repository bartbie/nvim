local UTILS = require("bartbie.utils")
local LIB = UTILS.lib
return {
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
                    },

                    lualine_x = {
                        { "diagnostics", symbols = LIB.diagnostics_symbols.core },
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
