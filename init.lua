pcall(require, "impatient")

local modules = {
    "core.config",
    "plugins",
    "core.keymapping",
    "core.events",
}

for _, module in ipairs(modules) do
    local ok, err = pcall(require, module)
    if not ok then
        error("Error loading " .. module .. "\n\n" .. err)
    elseif module == "core.keymapping" then
        require("core.keymapping").setup()
    end
end
