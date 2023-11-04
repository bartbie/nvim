-- [[
-- Formatting turned out to be so annoying that i just yanked it from Kickstart.nvim
-- ]]

local format_is_enabled = true

---@param client any
---@param formatting_disabled string[]
local can_fmt = function(client, formatting_disabled)
    local supports_fmt = client.server_capabilities.documentFormattingProvider
    local enabled = not vim.tbl_contains(formatting_disabled, client.name)
    return supports_fmt and enabled
end

---@param formatting_disabled string[]
local any_active_can_fmt = function(formatting_disabled)
    for _, client in ipairs(vim.lsp.get_active_clients()) do
        if can_fmt(client, formatting_disabled) then
            return true
        end
    end
    return false
end

--- setups

---@param formatting_disabled string[]
local setup_commands = function(formatting_disabled)
    local announce = function()
        print("Setting autoformatting to: " .. tostring(format_is_enabled))
    end

    vim.api.nvim_create_user_command("FormatToggle", function()
        format_is_enabled = not format_is_enabled
        announce()
    end, {
        desc = "Toggle Autoformatting.",
    })

    vim.api.nvim_create_user_command("FormatEnable", function()
        format_is_enabled = true
        announce()
    end, {
        desc = "Turn On Autoformatting.",
    })

    vim.api.nvim_create_user_command("FormatDisable", function()
        format_is_enabled = false
        announce()
    end, {
        desc = "Turn Off Autoformatting.",
    })

    -- Formatting function
    vim.api.nvim_create_user_command("Format", function()
        if not any_active_can_fmt(formatting_disabled) then
            vim.notify("No possible servers for formatting!", vim.log.levels.WARN)
            return
        end
        return vim.lsp.buf.format()
    end, { desc = "Format buffer" })
end

local setup_keymaps = function()
    vim.keymap.set("n", "<leader>cf", "<CMD>Format<CR>", { desc = "Format buffer" })
end

---@param formatting_disabled string[]
local setup_attaching = function(formatting_disabled)
    -- Create an augroup that is used for managing our formatting autocmds.
    --      We need one augroup per client to make sure that multiple clients
    --      can attach to the same buffer without interfering with each other.
    local _augroups = {}

    local get_augroup = function(client)
        if not _augroups[client.id] then
            local group_name = "user-lsp-format-" .. client.name
            local id = vim.api.nvim_create_augroup(group_name, { clear = true })
            _augroups[client.id] = id
        end

        return _augroups[client.id]
    end

    local add_autoformat = function(args)
        local client_id = args.data.client_id
        local client = vim.lsp.get_client_by_id(client_id)
        local bufnr = args.buf

        if not can_fmt(client, formatting_disabled) then
            return
        end

        -- Create an autocmd that will run *before* we save the buffer.
        --  Run the formatting command for the LSP that has just attached.
        vim.api.nvim_create_autocmd("BufWritePre", {
            group = get_augroup(client),
            buffer = bufnr,
            callback = function()
                if not format_is_enabled then
                    return
                end

                vim.lsp.buf.format({
                    async = false,
                    filter = function(c)
                        return c.id == client.id
                    end,
                })
            end,
        })
    end

    -- Whenever an LSP attaches to a buffer, we will run this function.
    -- See `:help LspAttach` for more information about this autocmd event.
    vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("user-lsp-attach-format", { clear = true }),
        -- This is where we attach the autoformatting for reasonable clients
        callback = add_autoformat,
    })
end

return {
    ---@param formatting_disabled string[]
    setup = function(formatting_disabled)
        setup_commands(formatting_disabled)
        setup_attaching(formatting_disabled)
        setup_keymaps()
    end,
}
