local idx_lib = require("bartbie.fold.index")
local Index = idx_lib.Index

local M = {}

---@type table<integer, bartbie.fold.Index>
local _index_map = {}

---@param buf integer
---@param changed_ranges Range4[]?
local function rebuild_index(buf, changed_ranges)
    if changed_ranges and #changed_ranges ~= 0 then
        _index_map[buf]:rebuild(buf, changed_ranges)
    else
        _index_map[buf] = Index.build(buf)
    end
end

--- Wire up fold index for a buffer. Registers on_bytes (shift) and
--- on_changedtree (incremental rebuild) callbacks on the TS parser.
--- Returns a function to force full rebuild.
---@param buf integer
function M.attach(buf)
    local cleanup = function()
        _index_map[buf] = nil
    end

    local ok, parser = pcall(vim.treesitter.get_parser, buf)
    if ok and parser then
        parser:parse(nil, function()
            rebuild_index(buf)
        end)
        parser:register_cbs({
            on_bytes = function(
                _,
                buf,
                _tick,
                start_row,
                _start_col,
                _start_byte,
                old_end_row,
                _old_end_col,
                _old_end_byte,
                new_end_row,
                _new_end_col,
                _new_end_byte
            )
                local idx = _index_map[buf]
                if not idx then
                    return
                end
                idx:shift(start_row, old_end_row, new_end_row)
            end,
            on_changedtree = function(changed_ranges, _changed_tree)
                ---@cast changed_ranges Range4[]
                rebuild_index(buf, changed_ranges)
            end,
            on_detach = cleanup,
        })
    end
    -- clean up on detach
    vim.api.nvim_buf_attach(buf, false, {
        on_detach = cleanup,
    })
    return function()
        rebuild_index(buf)
    end
end

---@param lnum integer? 1-indexed (v:lnum)
---@return string
function M.foldexpr(lnum)
    lnum = lnum or vim.v.lnum
    local buf = vim.api.nvim_get_current_buf()
    local idx = _index_map[buf]
    if not idx then
        return "0"
    end
    return idx:foldexpr(lnum)
end

---------------------------------------------------------------------------
-- foldlevel operations
---------------------------------------------------------------------------

---@param min integer
---@param max integer
---@param v integer
---@return integer
local function math_bound_incl(min, max, v)
    return math.max(min, math.min(max, v))
end

---@param v integer
local function set_curr_foldlevel(v)
    vim.wo.foldlevel = math_bound_incl(0, 99, v)
end

---@param delta integer
local function change_curr_foldlevel(delta)
    set_curr_foldlevel(vim.wo.foldlevel + delta)
end

function M.close_all_folds()
    set_curr_foldlevel(2)
end

function M.open_all_folds()
    set_curr_foldlevel(99)
end

function M.open_more_folds()
    change_curr_foldlevel(1)
end

function M.close_more_folds()
    change_curr_foldlevel(-1)
end

return M
