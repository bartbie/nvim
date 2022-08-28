local u = require("core.utils")

local function prepare_servers()
    local api = vim.api
    local json = vim.json

    -- Make runtime files discoverable to the server
    local runtime_path = vim.split(package.path, ";")
    table.insert(runtime_path, "lua/?.lua")
    table.insert(runtime_path, "lua/?/init.lua")

    -- Path to json folder with server settings
    local configs_path = u.bin_path .. "/lsp_servers_configs/"

    -- function to read and decode json server settings
    local function read(filename)
        return json.decode(u.read_file(configs_path .. filename .. ".json"))
    end

    -- Servers with default setups
    local default = { "pylsp", "emmet_ls", "html", "jsonls", "vimls", "zk", "grammarly", "sqlls" }

    -- Rest of servers
    local servers = {

        pyright = read("pyrightconfig"),

        rust_analyzer = {},

        sumneko_lua = {
            Lua = {
                runtime = {
                    version = "LuaJIT",
                    path = runtime_path,
                },
                format = {
                    enable = false,
                },
                diagnostics = {
                    globals = { "vim" },
                },
                workspace = {
                    -- Make the server aware of Neovim runtime files
                    library = api.nvim_get_runtime_file("", true),
                },
                -- Do not send telemetry data containing a randomized but unique identifier
                telemetry = {
                    enable = false,
                },
            },
        },
    }
    -- Combine them for uniform interface
    for _, v in ipairs(default) do
        servers[v] = {}
    end

    return servers
end

M = {
    servers = prepare_servers(),
    default_opts = {}, -- empty for now
}

-- Installer setup
function M.mason_setup(self)
    require("mason").setup()
    local mason_lsp = require("mason-lspconfig")
    mason_lsp.setup({
        ensure_installed = vim.tbl_keys(self.servers),
    })
    -- local installed = mason_lsp.get_installed_servers()
    -- vim.tbl_extend("keep", self.servers, u.to_dict(installed, {}))
end

-- LSP setup
function M.lsp_setup(self)
    local lsp = require("lspconfig")
    local coq = require("coq")
    local wk = require("which-key")
    local km = require("core.keymapping")
    local keymaps = km.lsp_keymaps
    local keymap_opts = km.opts
    local mason_lsp = require("mason-lspconfig")

    -- Default on_attach settings
    local function on_attach(client, buffer)
        wk.register(keymaps, vim.tbl_extend("force", keymap_opts, { buffer = buffer }))
    end

    -- setup handlers
    local handlers = {
        -- default one used e.g. when server is installed from Mason menu
        function(server)
            lsp[server].setup(coq.lsp_ensure_capabilities({
                on_attach = on_attach,
                settings = self.default_opts,
            }))
        end,
    }

    -- setting up the handlers for ensure_installed servers
    for server, opts in pairs(self.servers) do
        handlers[server] = function()
            lsp[server].setup(coq.lsp_ensure_capabilities({
                on_attach = on_attach,
                settings = opts,
            }))
        end
    end

    mason_lsp.setup_handlers(handlers)
end

function M.setup()
    M:mason_setup()
    M:lsp_setup()
end

return M
