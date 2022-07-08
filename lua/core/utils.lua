local utils = {}

-- The file system path separator for the current platform.
utils.path_separator = "/"
utils.is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win32unix") == 1
if utils.is_windows == true then
    utils.path_separator = "\\"
end

-- path to bin folder
utils.bin_path = vim.fn.stdpath("config") .. utils.path_separator .. "bin"

-- Joins arbitrary number of paths together.
-- @param ... string The paths to join.
-- @return string
utils.join_paths = function(...)
    local args = { ... }
    if #args == 0 then
        return ""
    end

    local all_parts = {}
    if type(args[1]) == "string" and args[1]:sub(1, 1) == utils.path_separator then
        all_parts[1] = ""
    end

    for _, arg in ipairs(args) do
        local arg_parts = utils.split(arg, utils.path_separator)
        vim.list_extend(all_parts, arg_parts)
    end
    return table.concat(all_parts, utils.path_separator)
end

-- see if the file exists
-- @param path string path to file
-- @return boolean
utils.file_exists = vim.fn.filereadable

-- get all lines from a file
-- @param path string path to file
-- @return table if the file exists, empty table else
utils.read_lines = function(path)
    if not utils.file_exists(path) then
        return {}
    end
    local lines = {}
    for line in io.lines(path) do
        lines[#lines + 1] = line
    end
    return lines
end

-- get file's content as string
-- @param path string path to file
-- @return string if the file exists, nil else
utils.read_file = function(path)
    local file = io.open(path, "rb") -- r read mode and b binary mode
    if not file then
        return nil
    end
    local content = file:read("*a") -- *a or *all reads the whole file
    file:close()
    return content
end

return utils
