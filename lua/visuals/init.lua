local modules = {
    'theme',
}

for _, module in ipairs(modules) do
    local ok, err = pcall(require, 'visuals.'..module)
    if not ok then
        error("Error loading " .. module .. "\n\n" .. err)
    end
end
