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
