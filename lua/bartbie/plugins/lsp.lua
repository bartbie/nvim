local utils = require("bartbie.utils")
local cmp_icons = utils.lib.cmp_icons
local icons = utils.lib.diagnostics_symbols

--- Define LSP symbols used nvim and plugins
---@param name string
---@param symbol string
---@param use_space boolean | nil
local function sign_define(name, symbol, use_space)
    use_space = use_space or false
    vim.fn.sign_define(name, { text = symbol .. (use_space and " " or ""), texthl = name })
end

local function has_words_before()
    -- unpack = unpack or table.unpack
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
end

---format virtual text diagnostics
---@return string
local function format_diagnostics(diagnostic)
    local s = vim.diagnostic.severity
    local severity = function(level)
        return level == diagnostic.severity
    end

    -- stylua: ignore start
    local icon = icons.error
    if severity(s.WARN) then icon = icons.warn
    elseif severity(s.INFO) then icon = icons.info
    elseif severity(s.HINT) then icon = icons.hint
    end
    -- stylua: ignore end

    return string.format("%s %s", icon, diagnostic.message)
end

-- keymaps
vim.api.nvim_create_autocmd("LspAttach", {
    desc = "LSP actions",
    group = vim.api.nvim_create_augroup("UserLspConfig", {}),
    callback = function(event)
        local map = function(mode, lhs, rhs, opts)
            local defaults = { silent = true, buffer = event.buf }
            opts = vim.tbl_extend("force", defaults, opts or {})
            vim.keymap.set(mode, lhs, rhs, opts)
        end

        map("n", "go", vim.diagnostic.open_float, { desc = "Show Line Diagnostics" })
        map("n", "<leader>cl", "<cmd>LspInfo<cr>", { desc = "Lsp Info" })
        map("n", "gd", "<cmd>Telescope lsp_definitions<CR>", { desc = "Goto Definition" })
        map("n", "gr", "<cmd>Telescope lsp_references<cr>", { desc = "References" })
        map("n", "gD", vim.lsp.buf.declaration, { desc = "Goto Declaration" })
        map("n", "gt", "<cmd>Telescope lsp_type_definitions<cr>", { desc = "Goto Type Definition" })
        map("n", "K", vim.lsp.buf.hover, { desc = "Hover" })
        map("n", "gn", function()
            return ":IncRename " .. vim.fn.expand("<cword>")
        end, { expr = true, desc = "Rename" })

        map("n", "<leader>cA", function()
            vim.lsp.buf.code_action({ context = { only = { "source" }, diagnostics = {} } })
        end, { desc = "Source Action" })

        local function diag_go(next, severity)
            return function()
                if next then
                    vim.diagnostic.goto_next({ severity = severity })
                else
                    vim.diagnostic.goto_prev({ severity = severity })
                end
            end
        end

        map("n", "gj", diag_go(true), { desc = "Jump to Next Diagnostic" })
        map("n", "gk", diag_go(false), { desc = "Jump to Prev Diagnostic" })
        map("n", "]e", diag_go(true, "ERROR"), { desc = "Next Error" })
        map("n", "[e", diag_go(false, "ERROR"), { desc = "Prev Error" })
    end,
})

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
        -- INFO:
        -- instead of writing custom setup for each server inside config function
        -- add it via opts inside config table
        -- if more control is needed, you can use opts.setup table

        ---@class PluginLSPOpts
        opts = {
            diagnostics = {
                underline = true,
                update_in_insert = false,
                virtual_text = {
                    format = format_diagnostics,
                    prefix = "",
                    -- spacing = 4,
                },
                severity_sort = true,
            },
            -- LSP Server Settings
            ---@type lspconfig.options
            servers = {
                jsonls = {},
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
            },
            -- return true if you don't want this server to be setup with lspconfig
            ---@type table<string, fun(server:string, opts:_.lspconfig.options):boolean?>
            setup = {
                -- tsserver = function(_, opts)
                --   require("typescript").setup({ server = opts })
                --   return true
                -- end,
            },
        },
        ---@param opts PluginLSPOpts
        config = function(_, opts)
            -- set up signs
            sign_define("DiagnosticSignError", icons.error)
            sign_define("DiagnosticSignWarn", icons.warn)
            sign_define("DiagnosticSignInfo", icons.info)
            sign_define("DiagnosticSignHint", icons.hint)

            -- set up workspace commands
            local command = vim.api.nvim_create_user_command
            command("LspWorkspaceAdd", function()
                vim.lsp.buf.add_workspace_folder()
            end, { desc = "Add folder to workspace" })

            command("LspWorkspaceList", function()
                vim.notify(vim.inspect(vim.lsp.buf.list_workspace_folders()))
            end, { desc = "List workspace folders" })

            command("LspWorkspaceRemove", function()
                vim.lsp.buf.remove_workspace_folder()
            end, { desc = "Remove folder from workspace" })

            -- load opts & servers config
            vim.diagnostic.config(opts.diagnostics)
            local lspconfig = require("lspconfig")

            local default_server_config = {
                capabilities = vim.tbl_deep_extend(
                    "force",
                    lspconfig.util.default_config.capabilities,
                    require("cmp_nvim_lsp").default_capabilities()
                ),
                on_attach = function(client, bufnr)
                    local buf_command = vim.api.nvim_buf_create_user_command
                    buf_command(bufnr, "LspFormat", function()
                        return vim.lsp.buf.format()
                    end, { desc = "Format buffer with language server" })
                end,
            }

            local custom_settings = opts.servers or {}
            local custom_setup_fns = opts.setup or {}

            --- run configs and setups
            ---@param server string
            local function setup(server)
                -- combine default config with custom if exists
                local server_opts = vim.tbl_deep_extend("force", default_server_config, custom_settings[server] or {})

                -- check if custom setup exists and run it if yes
                if custom_setup_fns[server] then
                    if custom_setup_fns[server](server, server_opts) then
                        return
                    end
                end
                lspconfig[server].setup(server_opts)
            end

            require("mason-lspconfig").setup_handlers({ setup })
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
            ensure_installed = {
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
            },
        },
    },
    {
        "L3MON4D3/LuaSnip",
        build = (not jit.os:find("Windows"))
                and "echo -e 'NOTE: jsregexp is optional, so not a big deal if it fails to build\n'; make install_jsregexp"
            or nil,
        dependencies = {
            "rafamadriz/friendly-snippets",
            config = function()
                require("luasnip.loaders.from_vscode").lazy_load()
            end,
        },
        opts = {
            history = true,
            delete_check_events = "TextChanged",
        },
    },
    {
        "hrsh7th/nvim-cmp",
        dependencies = {
            { "hrsh7th/cmp-nvim-lsp" },
            { "hrsh7th/cmp-buffer" },
            { "hrsh7th/cmp-path" },
            { "saadparwaiz1/cmp_luasnip" },
            { "hrsh7th/cmp-nvim-lua" },
            { "hrsh7th/cmp-nvim-lsp-signature-help" },
            { "L3MON4D3/LuaSnip" },
        },
        opts = function()
            local cmp = require("cmp")
            local luasnip = require("luasnip")

            return {
                preselect = cmp.PreselectMode.None,
                completion = {
                    completeopt = "noselect",
                },
                snippet = {
                    expand = function(args)
                        require("luasnip").lsp_expand(args.body)
                    end,
                },
                mapping = cmp.mapping.preset.insert({
                    -- confirm selection
                    ["<CR>"] = cmp.mapping.confirm({ select = true }),
                    ["<S-CR>"] = cmp.mapping.confirm({
                        behavior = cmp.ConfirmBehavior.Replace,
                        select = true,
                    }),

                    -- navigation
                    -- ["<C-n>"] = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Insert }),
                    -- ["<C-p>"] = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Insert }),
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_next_item()
                            -- You could replace the expand_or_jumpable() calls with expand_or_locally_jumpable()
                            -- they way you will only jump inside the snippet region
                        elseif luasnip.expand_or_jumpable() then
                            luasnip.expand_or_jump()
                        elseif has_words_before() then
                            cmp.complete()
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then
                            cmp.select_prev_item()
                        elseif luasnip.jumpable(-1) then
                            luasnip.jump(-1)
                        else
                            fallback()
                        end
                    end, { "i", "s" }),
                    -- docs scroll
                    ["<C-b>"] = cmp.mapping.scroll_docs(-4),
                    ["<C-f>"] = cmp.mapping.scroll_docs(4),

                    ["<C-Space>"] = cmp.mapping.complete(),
                    ["<C-e>"] = cmp.mapping.abort(),
                }),
                sources = cmp.config.sources({
                    { name = "nvim_lsp" },
                    { name = "luasnip" },
                    { name = "buffer" },
                    { name = "path" },
                    { name = "crates" },
                }),
                formatting = {
                    format = function(entry, item)
                        local short_name = {
                            nvim_lsp = "LSP",
                            nvim_lua = "nvim",
                            buffer = "buf",
                            luasnip = "snip",
                            gh_issues = "issues",
                        }
                        local menu_name = short_name[entry.source.name] or entry.source.name
                        item.menu = string.format("[%s]", menu_name)
                        if cmp_icons[item.kind] then
                            item.kind = cmp_icons[item.kind] .. item.kind
                        end
                        return item
                    end,
                },
                experimental = {
                    ghost_text = {
                        hl_group = "LspCodeLens",
                    },
                },
            }
        end,
    },
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
    {
        "smjonas/inc-rename.nvim",
        config = true,
    },
}
