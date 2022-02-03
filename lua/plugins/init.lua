local modules = {
	'filetree',
	'treesitter',
	'autocompletion',
	'lsp',
    'org',
    'telescope',
}

for _, module in ipairs(modules) do
    local ok, err = pcall(require, 'plugins.'..module)
    if not ok then
        error("Error loading " .. module .. "\n\n" .. err)
    end
end
