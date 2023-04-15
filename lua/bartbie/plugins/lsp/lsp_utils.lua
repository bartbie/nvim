-- [[
-- Functions used in setting up the LSP config
-- ]]
--
local FN = {}

local UTILS = require("bartbie.utils")

--- set up diagnostic symbols used by nvim and plugins
function FN.setup_signs()
    --- Define signs
    ---@param name string
    ---@param symbol string
    ---@param use_space boolean | nil
    local function sign_define(name, symbol, use_space)
        use_space = use_space or false
        vim.fn.sign_define(name, { text = symbol .. (use_space and " " or ""), texthl = name })
    end
    local icons = UTILS.lib.diagnostics_symbols.core
    sign_define("DiagnosticSignError", icons.error)
    sign_define("DiagnosticSignWarn", icons.warn)
    sign_define("DiagnosticSignInfo", icons.info)
    sign_define("DiagnosticSignHint", icons.hint)
end

--- set up workspace commands
function FN.setup_workspace_cmd()
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
end

---format virtual text diagnostics
---@return string
function FN.format_diagnostics(diagnostic)
    local icons = UTILS.lib.diagnostics_symbols.core
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

---sests up keymaps for LSP server
---@param _ any client
---@param bufnr any
---@param keymaps table { string, string, string | function, table}[]
function FN.setup_keymaps(_, bufnr, keymaps)
    local function map(mode, lhs, rhs, opts)
        local defaults = { silent = true, buffer = bufnr }
        opts = vim.tbl_extend("force", defaults, opts or {})
        vim.keymap.set(mode, lhs, rhs, opts)
    end

    for _, v in ipairs(keymaps) do
        map(unpack(v))
    end
end

--- functions defined for shorter keymaps setup code

function FN.diag_go(next, severity)
    local fn = next and vim.diagnostic.goto_next or vim.diagnostic.goto_prev
    return function()
        fn({ severity = severity })
    end
end

function FN.source_code_action()
    vim.lsp.buf.code_action({ context = { only = { "source" }, diagnostics = {} } })
end

function FN.rename()
    return ":IncRename " .. vim.fn.expand("<cword>")
end

function FN.setup_cursor()
    -- Show diagnostic popup on cursor hover
    local diag_float_grp = vim.api.nvim_create_augroup("DiagnosticFloat", { clear = true })
    vim.api.nvim_create_autocmd("CursorHold", {
        callback = function()
            vim.diagnostic.open_float(nil, { focusable = false })
        end,
        group = diag_float_grp,
    })
    vim.o.updatetime = 100
end

return FN
