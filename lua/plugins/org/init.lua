local modules = {
    'nvim-orgmode',
}

for _, module in ipairs(modules) do
    local ok, err = pcall(require, 'plugins.org.'.. module)
    if not ok then
        error("Error loading " .. module .. "\n\n" .. err)
    end
end
