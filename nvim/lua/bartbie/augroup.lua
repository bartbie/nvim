---create custom augroup for this config
---@param name string
---@return integer
local function augroup(name)
    return vim.api.nvim_create_augroup("bartbie_" .. name, { clear = true })
end

return augroup
