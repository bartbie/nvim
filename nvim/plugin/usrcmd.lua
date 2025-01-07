local usercmd = vim.api.nvim_create_user_command

usercmd("W", "w", {
    desc = "Command alias for saving the buffer.",
})

usercmd("LspWorkspaceAdd", function()
    vim.lsp.buf.add_workspace_folder()
end, { desc = "Add folder to workspace" })

usercmd("LspWorkspaceList", function()
    vim.notify(vim.inspect(vim.lsp.buf.list_workspace_folders()))
end, { desc = "List workspace folders" })

usercmd("LspWorkspaceRemove", function()
    vim.lsp.buf.remove_workspace_folder()
end, { desc = "Remove folder from workspace" })

do
    vim.g.disable_autoformat = false
    vim.b.disable_autoformat = false
    local function enable(args, glob, buf)
        if args.bang then
            vim.g.disable_autoformat = not glob
        else
            vim.b.disable_autoformat = not buf
        end
        -- TODO
        -- print("Setting autoformatting to: " .. tostring(format_is_enabled))
    end

    usercmd("FormatToggle", function(args)
        enable(args, vim.g.disable_autoformat, vim.b.disable_autoformat)
    end, {
        desc = "Toggle Autoformatting.",
        bang = true,
    })

    usercmd("FormatEnable", function(args)
        enable(args, true, true)
    end, {
        desc = "Turn On Autoformatting.",
        bang = true,
    })

    usercmd("FormatDisable", function(args)
        enable(args, false, false)
    end, {
        desc = "Turn Off Autoformatting.",
        bang = true,
    })

    usercmd("Format", function()
        local stat, conform = pcall(require, "conform")
        if stat then
            conform.format({
                timeout_ms = 500,
                lsp_format = "fallback",
            })
        else
            vim.lsp.buf.format({
                timeout_ms = 500,
            })
        end
    end, {
        desc = "Format buffer",
    })
end
