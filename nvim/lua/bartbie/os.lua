local uname = vim.uv.os_uname()

local M = {}
M.uname = uname
M.is_linux = uname.sysname == "Linux"
M.is_darwin = uname.sysname == "Darwin"
M.is_macos = M.is_darwin
M.is_windows = uname.sysname:find("Windows") and true or false
M.is_wsl = M.is_linux and uname.release:find("Microsoft") and true or false
M.is_bsd = uname.sysname:find("BSD") and true or false

return M
