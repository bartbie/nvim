local conform = require("conform")

---@param rest string[]
---@return fun(bufnr: integer): string[]
local function w_treefmt(rest)
    return function(bufnr)
        if conform.get_formatter_info("treefmt", bufnr).available then
            return { "treefmt" }
        end
        for _, formatter in ipairs(rest) do
            if conform.get_formatter_info(formatter, bufnr).available then
                return { formatter }
            end
        end
        return {}
    end
end

conform.setup({
    formatters_by_ft = {
        -- Use the "*" filetype to run formatters on all filetypes.
        lua = w_treefmt({ "stylua" }),
        -- Conform will run multiple formatters sequentially
        python = w_treefmt({ "isort", "black" }),
        -- You can customize some of the format options for the filetype (:help conform.format)
        rust = w_treefmt({ "rustfmt" }),
        -- Conform will run the first available formatter
        javascript = w_treefmt({ "prettierd", "prettier", stop_after_first = true }),
        typescript = w_treefmt({ "prettierd", "prettier", stop_after_first = true }),
        nix = w_treefmt({ "alejandra" }),
        ["_"] = w_treefmt({ "trim_whitespace" }),
    },
    format_on_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
            return
        end
        return {
            -- These options will be passed to conform.format()
            timeout_ms = 500,
            lsp_format = "fallback",
        }
    end,
})

vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
