--- TS node type -> fold level (1-indexed, 0 = no fold).
--- Higher level = folded first (3 before 2 before 1).
--- Override per filetype via M.ft_levels[ft] = { [level] = { node_type = true, ... } }
---@type table<string, boolean>[]
local default_levels = {
    [3] = {
        -- functions / methods
        function_definition = true,
        function_declaration = true,
        method_definition = true,
        method_declaration = true,
        function_item = true, -- rust
        impl_item = true, -- rust
        arrow_function = true,
        function_expression = true, -- nix
    },
    [2] = {
        -- data structures
        object = true,
        table_constructor = true,
        struct_item = true,
        enum_item = true, -- rust
        type_alias_declaration = true,
        array = true,
        attrset_expression = true, -- nix
        let_expression = true, -- nix
        list_expression = true, -- nix
    },
    [1] = {
        -- control flow - foldable but deep
        if_statement = true,
        if_expression = true,
        for_statement = true,
        for_expression = true,
        while_statement = true,
        while_expression = true,
        match_expression = true,
        switch_statement = true,
    },
}

local M = {}

M.ft_levels = {}

function M.curr_buf_levels()
    return vim.tbl_deep_extend("force", default_levels, M.ft_levels[vim.bo.filetype] or {})
end

return M
