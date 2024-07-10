local utils = require("bartbie.utils")
local fn = require("bartbie.plugins.lsp.utils")
local settings = require("bartbie.plugins.lsp.settings")
local fmt = require("bartbie.plugins.lsp.format")

local DEFAULT_ON_ATTACH = function(client, bufnr)
    fn.setup_keymaps(client, bufnr, settings.KEYMAPS)
    fn.setup_cursor()
end

return {
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            { "folke/neoconf.nvim", cmd = "Neoconf", config = true },
            { "folke/neodev.nvim", opts = { experimental = { pathStrict = true } } },
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
        },
        ---@class PluginLSPOpts
        opts = {
            diagnostics = {
                underline = true,
                update_in_insert = false,
                virtual_text = {
                    format = fn.format_diagnostics,
                    prefix = "",
                    -- spacing = 4,
                },
                severity_sort = true,
            },
            ---@type lspconfig.options
            servers = settings.SERVER_CONFIGS,
            ---@type table<string, fun(server:string, opts:_.lspconfig.options):boolean?>
            setup = settings.SERVER_SETUPS,
        },
        ---@param opts PluginLSPOpts
        config = function(_, opts)
            fn.setup_signs()
            fn.setup_workspace_cmd()
            fmt.setup(settings.FORMATTING_DISABLED)

            -- load opts & servers config
            vim.diagnostic.config(opts.diagnostics)

            local DEFAULT_SERVER_CONFIG = {
                capabilities = vim.tbl_deep_extend(
                    "force",
                    require("lspconfig").util.default_config.capabilities,
                    require("cmp_nvim_lsp").default_capabilities()
                ),
                on_attach = DEFAULT_ON_ATTACH,
            }

            local custom_server_configs = opts.servers or {}
            local custom_server_setups = opts.setup or {}
            --- run configs and setups
            require("mason-lspconfig").setup_handlers({
                ---@param server string
                function(server)
                    -- combine default config with custom if exists
                    ---@type _.lspconfig.options
                    local server_config = vim.tbl_deep_extend(
                        "force",
                        DEFAULT_SERVER_CONFIG,
                        custom_server_configs[server] or {}
                    )

                    -- check if custom setup exists and run it if yes
                    if custom_server_setups[server] then
                        if custom_server_setups[server](server, server_config) then
                            return
                        end
                    end
                    require("lspconfig")[server].setup(server_config)
                end,
            })
        end,
    },
    {
        "williamboman/mason.nvim",
        event = { "BufReadPre", "BufNewFile" },
        cmd = "Mason",
        keys = {
            { "<leader>m", "<CMD>Mason<CR>", desc = "Mason" },
        },
        config = true,
    },
    {
        "williamboman/mason-lspconfig.nvim",
        opts = {
            ensure_installed = settings.ENSURE_INSTALLED_SERVERS,
        },
    },
    {
        "nvimtools/none-ls.nvim",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = { "mason.nvim" },
        opts = function()
            -- local nls = require("null-ls")
            return {
                root_dir = require("null-ls.utils").root_pattern(".null-ls-root", ".neoconf.json", "Makefile", ".git"),
                -- vvv Anything not supported by mason.
                -- sources = {}
            }
        end,
    },
    {
        "jay-babu/mason-null-ls.nvim",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            "williamboman/mason.nvim",
            "nvimtools/none-ls.nvim",
        },
        opts = {
            ensure_installed = settings.ENSURE_INSTALLED_TOOLS,
            automatic_setup = true,
            handlers = {},
        },
    },
    {
        "smjonas/inc-rename.nvim",
        config = true,
    },
    {
        "simrat39/symbols-outline.nvim",
        keys = {
            { "<leader>N", "<CMD>SymbolsOutline<CR>", desc = "Symbols Outline" },
        },
        opts = {
            autofold_depth = 0,
            symbols = vim.tbl_map(function(sym)
                return { icon = sym }
            end, utils.lib.cmp_icons),
        },
    },
    {
        "RRethy/vim-illuminate",
        event = { "BufReadPre", "BufNewFile" },
    },
    {
        "kosayoda/nvim-lightbulb",
        opts = {
            autocmd = {
                enabled = true,
            },
        },
        config = function(_, opts)
            require("nvim-lightbulb").setup(opts)
            fn.sign_define("LightBulbSign", utils.lib.diagnostics_symbols.rest.action)
        end,
    },
    { -- rust
        {
            "simrat39/rust-tools.nvim",
            opts = {
                tools = {
                    runnables = {
                        use_telescope = true,
                    },
                    inlay_hints = {
                        auto = true,
                        show_parameter_hints = false,
                        parameter_hints_prefix = "",
                        other_hints_prefix = "",
                    },
                },

                -- all the opts to send to nvim-lspconfig
                -- these override the defaults set by rust-tools.nvim
                -- see https://github.com/neovim/nvim-lspconfig/blob/master/CONFIG.md#rust_analyzer
                server = {
                    -- on_attach is a callback called when the language server attachs to the buffer
                    on_attach = DEFAULT_ON_ATTACH,
                    settings = {
                        -- to enable rust-analyzer settings visit:
                        -- https://github.com/rust-analyzer/rust-analyzer/blob/master/docs/user/generated_config.adoc
                        ["rust-analyzer"] = {
                            -- enable clippy on save
                            checkOnSave = {
                                command = "clippy",
                            },
                        },
                    },
                },
            },
        },
        {
            "saecki/crates.nvim",
            event = { "BufRead Cargo.toml" },
            dependencies = { "nvim-lua/plenary.nvim" },
            config = true,
        },
    },
}
