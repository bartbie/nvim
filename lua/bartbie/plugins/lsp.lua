local FN = require("bartbie.plugins.lsp.lsp_utils")
local UTILS = require("bartbie.utils")

-- PERF this functionality is quite slow, in future i should move to a better lazy-loading solution
---loads json config from /assets/lsp_configs/
---@param name string
---@return table
local function load_config(name)
    local x = UTILS.assets.lsp_config(name)
    return x and x:decode() or {}
end

-----

local ENSURE_INSTALLED_SERVERS = {
    "vimls",
    "grammarly",
    "lua_ls",
    "rust_analyzer",
    "pyright",
    "eslint",
    "tsserver",
    "tailwindcss",
    "html",
    "jsonls",
}

local ENSURE_INSTALLED_TOOLS = {
    "stylua",
    "shfmt,",
    "black",
}

-- INFO:
-- instead of writing custom setup for each server inside config function
-- add it via opts inside config table
-- if more control is needed, you can use the SERVER_SETUPS table
--
---@type lspconfig.options
local SERVER_CONFIGS = {
    pyright = {
        settings = {
            pyright = {
                python = {
                    analysis = {
                        autoImportCompletions = true,
                        autoSearchPaths = true,
                        diagnosticMode = "workspace",
                        useLibraryCodeForTypes = true,
                        diagnosticSeverityOverrides = load_config("pyrightconfig.json"),
                    },
                },
            },
        },
    },
    lua_ls = {
        settings = {
            Lua = {
                workspace = {
                    checkThirdParty = false,
                },
                completion = {
                    callSnippet = "Replace",
                },
            },
        },
    },
}

-- NOTE try to not overwrite on_attach
-- if you do, remember to enable fmt and set up keymaps if you want to use them!
--
---@type table<string, fun(server:string, opts:_.lspconfig.options):boolean?>
local SERVER_SETUPS = {
    -- tsserver = function(_, opts)
    --   require("typescript").setup({ server = opts })
    -- return true if you don't want this server to be setup with lspconfig
    --   return true
    -- end,
}

--- servers which formatting will be disabled
---@type string[]
local FORMATTING_DISABLED = {
    "lua_ls",
}

-----

local function rename()
    return ":IncRename " .. vim.fn.expand("<cword>")
end

local function code_action()
    vim.lsp.buf.code_action({ context = { only = { "source" }, diagnostics = {} } })
end

local KEYMAPS = {
    { "n", "go", vim.diagnostic.open_float, { desc = "Show Line Diagnostics" } },
    { "n", "<leader>cl", "<cmd>LspInfo<cr>", { desc = "Lsp Info" } },
    { "n", "gd", "<cmd>Telescope lsp_definitions<CR>", { desc = "Goto Definition" } },
    { "n", "gr", "<cmd>Telescope lsp_references<cr>", { desc = "References" } },
    { "n", "gD", vim.lsp.buf.declaration, { desc = "Goto Declaration" } },
    { "n", "gt", "<cmd>Telescope lsp_type_definitions<cr>", { desc = "Goto Type Definition" } },
    { "n", "K", vim.lsp.buf.hover, { desc = "Hover" } },
    { "n", "gn", rename, { desc = "Rename", expr = true } },
    { "n", "<leader>cA", code_action, { desc = "Source Action" } },
    { "n", "gj", FN.diag_go(true), { desc = "Jump to Next Diagnostic" } },
    { "n", "gk", FN.diag_go(false), { desc = "Jump to Prev Diagnostic" } },
    { "n", "]e", FN.diag_go(true, "ERROR"), { desc = "Next Error" } },
    { "n", "[e", FN.diag_go(false, "ERROR"), { desc = "Prev Error" } },
}

return {
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            { "folke/neoconf.nvim", cmd = "Neoconf", config = true },
            { "folke/neodev.nvim", opts = { experimental = { pathStrict = true } } },
            "williamboman/mason.nvim",
            "williamboman/mason-lspconfig.nvim",
            "hrsh7th/cmp-nvim-lsp",
        },
        ---@class PluginLSPOpts
        opts = {
            diagnostics = {
                underline = true,
                update_in_insert = false,
                virtual_text = {
                    format = FN.format_diagnostics,
                    prefix = "",
                    -- spacing = 4,
                },
                severity_sort = true,
            },
            ---@type lspconfig.options
            servers = SERVER_CONFIGS,
            ---@type table<string, fun(server:string, opts:_.lspconfig.options):boolean?>
            setup = SERVER_SETUPS,
        },
        ---@param opts PluginLSPOpts
        config = function(_, opts)
            FN.setup_signs()
            FN.setup_workspace_cmd()
            local setup_formatting = require("bartbie.plugins.lsp.format")
            setup_formatting(FORMATTING_DISABLED)

            -- load opts & servers config
            vim.diagnostic.config(opts.diagnostics)

            local DEFAULT_SERVER_CONFIG = {
                capabilities = vim.tbl_deep_extend(
                    "force",
                    require("lspconfig").util.default_config.capabilities,
                    require("cmp_nvim_lsp").default_capabilities()
                ),
                on_attach = function(client, bufnr)
                    FN.setup_keymaps(client, bufnr, KEYMAPS)
                end,
            }

            local custom_server_config = opts.servers or {}
            local custom_server_setup = opts.setup or {}
            --- run configs and setups
            require("mason-lspconfig").setup_handlers({
                ---@param server string
                function(server)
                    -- combine default config with custom if exists
                    ---@type _.lspconfig.options
                    local server_config =
                        vim.tbl_deep_extend("force", DEFAULT_SERVER_CONFIG, custom_server_config[server] or {})

                    -- check if custom setup exists and run it if yes
                    if custom_server_setup[server] then
                        if custom_server_setup[server](server, server_config) then
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
            ensure_installed = ENSURE_INSTALLED_SERVERS,
        },
    },
    {
        "jose-elias-alvarez/null-ls.nvim",
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
            "jose-elias-alvarez/null-ls.nvim",
        },
        opts = {
            ensure_installed = ENSURE_INSTALLED_TOOLS,
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
            end, UTILS.lib.cmp_icons),
        },
    },
    { -- rust
        {
            "simrat39/rust-tools.nvim",
            config = true,
        },
        {
            "saecki/crates.nvim",
            event = { "BufRead Cargo.toml" },
            dependencies = { "nvim-lua/plenary.nvim" },
            config = true,
        },
    },
}
