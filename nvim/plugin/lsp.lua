local augroup = require("bartbie.augroup")
local servers = {
    "lua_ls",
    "ts_ls",
    "nil_ls",
    "rust_analyzer",
    "gopls",
    "htmx",
    "jqls",
    "zls",
    "fish_lsp",
    "gleam",
    "cssls",
    "jsonls",
    "yamlls",
    "csharp_ls",
    "clojure_lsp",
    "scheme_langserver",
    "nu",
}

for _, name in ipairs(servers) do
    vim.lsp.enable(name)
end

vim.cmd.highlight("default link LspInlayHint Comment")
vim.api.nvim_create_autocmd("LspAttach", {
    group = augroup("lsp_enable_inlay_hints"),
    callback = function(args)
        local clients = vim.lsp.get_clients({
            bufnr = args.buf,
            method = "textDocument/inlayHint",
        })
        if #clients then
            vim.lsp.inlay_hint.enable(true, {
                bufnr = args.buf,
            })
        end
    end,
})
