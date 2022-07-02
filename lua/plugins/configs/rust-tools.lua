local utils = require("core.utils")

local extension_path = vim.env.HOME .. "/.vscode/extensions/vadimcn.vscode-lldb-1.6.7/"
local codelldb_path = extension_path .. "adapter/codelldb"
local liblldb_path = extension_path .. "lldb/lib/liblldb.so"

local dap = nil
if utils.file_exists(extension_path) then
    dap = {
        adapter = require("rust-tools.dap").get_codelldb_adapter(codelldb_path, liblldb_path),
    }
end

local opts = {
    -- ... other configs
    dap = dap,
}

-- Normal setup
require("rust-tools").setup(opts)
