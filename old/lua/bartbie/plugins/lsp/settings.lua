local FN = require("bartbie.plugins.lsp.utils")

local M = {}

M.KEYMAPS = {
    { "n", "ga", vim.lsp.buf.code_action, { desc = "Code Action" } },
    { "n", "go", vim.diagnostic.open_float, { desc = "Show Line Diagnostics" } },
    { "n", "<leader>cl", "<cmd>LspInfo<cr>", { desc = "Lsp Info" } },
    { "n", "gd", "<cmd>Telescope lsp_definitions<CR>", { desc = "Goto Definition" } },
    { "n", "gr", "<cmd>Telescope lsp_references<cr>", { desc = "References" } },
    { "n", "gD", vim.lsp.buf.declaration, { desc = "Goto Declaration" } },
    { "n", "gt", "<cmd>Telescope lsp_type_definitions<cr>", { desc = "Goto Type Definition" } },
    { "n", "K", vim.lsp.buf.hover, { desc = "Hover" } },
    { "n", "gn", FN.rename, { desc = "Rename", expr = true } },
    { "n", "<leader>cA", FN.source_code_action, { desc = "Source Action" } },
    { "n", "gj", FN.diag_go(true), { desc = "Jump to Next Diagnostic" } },
    { "n", "gk", FN.diag_go(false), { desc = "Jump to Prev Diagnostic" } },
    { "n", "]e", FN.diag_go(true, "ERROR"), { desc = "Next Error" } },
    { "n", "[e", FN.diag_go(false, "ERROR"), { desc = "Prev Error" } },
}

M.ENSURE_INSTALLED_SERVERS = {
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
    "nil_ls",
}

-- INFO:
-- instead of writing custom setup for each server inside config function
-- add it via opts inside config table
-- if more control is needed, you can use the SERVER_SETUPS table
--
---@type lspconfig.options
M.SERVER_CONFIGS = {
    pyright = {
        settings = {
            pyright = {
                python = {
                    analysis = {
                        autoImportCompletions = true,
                        autoSearchPaths = true,
                        diagnosticMode = "workspace",
                        useLibraryCodeForTypes = true,
                        diagnosticSeverityOverrides = FN.load_config("pyrightconfig.json"),
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
    nil_ls = {
        settings = {
            ["nil"] = {
                formatting = { command = { "nixpkgs-fmt" } },
            },
        },
    },
}

-- NOTE try to not overwrite on_attach
-- if you do, remember to enable fmt and set up keymaps if you want to use them!
--
---@type table<string, fun(server:string, opts:_.lspconfig.options):boolean?>
M.SERVER_SETUPS = {
    -- tsserver = function(_, opts)
    --   require("typescript").setup({ server = opts })
    -- return true if you don't want this server to be setup with lspconfig
    --   return true
    -- end,
}

M.ENSURE_INSTALLED_TOOLS = {
    "stylua",
    "shfmt,",
    "black",
    "isort",
    "prettierd",
}

--- servers which formatting will be disabled
---@type string[]
M.FORMATTING_DISABLED = {
    "lua_ls",
}

return M
