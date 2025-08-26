local M = {}

-- TODO: add another function that shows how loaders search
function M.show_module_search(module_name, all, filter_list)
    all = all or false
    filter_list = filter_list or { "%.local" }
    if type(filter_list) == "string" then
        filter_list = { filter_list }
    end

    local module_path = module_name:gsub("%.", "/")

    print("Searching for module '" .. module_name .. "' in Neovim paths:")

    local function try(path)
        -- Normalize path for consistent display
        local display_path = vim.fn.fnamemodify(path, ":~")
        print("  Trying: " .. display_path)
        local file = io.open(path)
        if file then
            file:close()
            print("  --> Found at: " .. display_path)
            return true
        end
        return false
    end

    local found = false

    local iter = function(it)
        local function filter_out_list(s)
            return not vim.iter(filter_list):any(function(x)
                return s:match(x)
            end)
        end
        return vim.iter(it):filter(filter_out_list)
    end

    local rtp = iter(vim.opt.runtimepath:get())
        :map(function(rtp)
            return {
                rtp .. "/lua/" .. module_path .. ".lua",
                rtp .. "/lua/" .. module_path .. "/init.lua",
            }
        end)
        :flatten()

    for path in rtp do
        found = found or try(path)
        if all and found then
            return
        end
    end

    if not found then
        -- If not found in runtimepath, check package.path
        print("\nFalling back to Lua package.path:")
        for path in iter(package.path:gmatch("[^;]+")) do
            local filename = path:gsub("%?", module_path)
            local x = try(filename)
            if not found and x then
                print("package.path where found -> " .. path)
            end
            found = found or x
            if all and found then
                return
            end
        end
    end

    if not found then
        print("\nModule not found in any search path (excluding .local paths)")
    end
end

-- Generic function to show and filter path lists
local function show_path_list(path_list, list_name, filter_list)
    filter_list = filter_list or {}
    if type(filter_list) == "string" then
        filter_list = { filter_list }
    end

    print(list_name .. " entries:")

    local function should_filter_out(path)
        if #filter_list == 0 then
            return false -- No filters, show all
        end

        -- Each pattern must pass for the path to be kept
        for _, pattern in ipairs(filter_list) do
            if pattern:sub(1, 1) == "!" then
                -- Negative pattern: path must NOT match
                local negative_pattern = pattern:sub(2) -- Remove the "!"
                if path:match(negative_pattern) then
                    return true -- Filter out this path
                end
            else
                -- Positive pattern: path must match
                if not path:match(pattern) then
                    return true -- Filter out this path
                end
            end
        end

        return false -- All patterns passed, keep this path
    end

    local filtered_entries = vim.iter(path_list):filter(function(path)
        return not should_filter_out(path)
    end)

    local count = 0
    for path in filtered_entries do
        count = count + 1
        local display_path = path
        print(string.format("  [%d] %s", count, display_path))
    end

    local total_count = #path_list
    if #filter_list > 0 then
        local filtered_out_count = total_count - count
        print(
            string.format(
                "\nShowing %d/%d entries (filtered out %d entries matching: %s)",
                count,
                total_count,
                filtered_out_count,
                table.concat(filter_list, ", ")
            )
        )
    else
        print(string.format("\nTotal: %d entries", count))
    end
end

local rt = require("bartbie.runtime")

function M.show_runtimepath(filter_list)
    show_path_list(rt.runtime_path():get(), "Neovim runtimepath", filter_list)
end

function M.show_packpath(filter_list)
    show_path_list(rt.pack_path():get(), "Neovim packpath", filter_list)
end

function M.show_package_path(filter_list)
    show_path_list(rt.lua_path():get(), "Lua package.path", filter_list)
end

function M.show_fennel_path(filter_list)
    show_path_list(vim.split(fennel.path, ";"), "Fennel fennel.path", filter_list)
end

function M.show_data_dirs(filter_list)
    show_path_list(vim.fn.stdpath("data_dirs"), "Neovim data_dirs", filter_list)
end

function M.show_config_dirs(filter_list)
    show_path_list(vim.fn.stdpath("config_dirs"), "Neovim config_dirs", filter_list)
end

-- we will add some aliases since i mostly use this via command line
M.show = {
    rtp = M.show_runtimepath,
    -- it's really called that in docs, :help 'pp'
    pp = M.show_packpath,
    dat = M.show_data_dirs,
    cfg = M.show_config_dirs,
}

return M
