local M = {}

-- TODO: add another function that shows how loaders search
function M.show_module_search(module_name, all, filter_list)
    all = all or false
    filter_list = filter_list or { "%.local" }
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

return M
