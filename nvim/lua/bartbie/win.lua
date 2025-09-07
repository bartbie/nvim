local M = {}

--[[
-- coords, mappings, conversions
--]]

---@alias bartbie.win.Direction "left" | "down" | "up" | "right"
---@alias bartbie.win.Dimension "width" | "height"
---@alias bartbie.win.Hjkl "h" | "j" | "k" | "l"

M.key_to_dirn = { h = "left", j = "down", k = "up", l = "right" }

M.dirn_to_key = { left = "h", down = "j", up = "k", right = "l" }

M.dirn_to_dim = { left = "width", down = "height", up = "height", right = "width" }

M.dirn_to_sign = { left = -1, down = 1, up = -1, right = 1 }

M.dim_to_nvim_set = { width = vim.api.nvim_win_set_width, height = vim.api.nvim_win_set_height }

M.dim_to_nvim_get = { width = vim.api.nvim_win_get_width, height = vim.api.nvim_win_get_height }

M.inverse_dirn = { left = "right", down = "up", up = "down", right = "left" }

M.dirn_is_anchor = { left = true, down = false, up = true, right = false }

M.dirn_to_se_coord = { left = "right", down = "down", up = "down", right = "right" }

M.dim_to_se_coord = { width = "right", height = "down" }

local mapping_metatable = {
    __index = function()
        error("no such value")
    end,
    __newindex = function()
        error("Don't change this table!")
    end,
}

setmetatable(M.key_to_dirn, mapping_metatable)
setmetatable(M.dirn_to_key, mapping_metatable)
setmetatable(M.dirn_to_dim, mapping_metatable)
setmetatable(M.dirn_to_sign, mapping_metatable)
setmetatable(M.dim_to_nvim_set, mapping_metatable)
setmetatable(M.dim_to_nvim_get, mapping_metatable)
setmetatable(M.inverse_dirn, mapping_metatable)
setmetatable(M.dirn_is_anchor, mapping_metatable)
setmetatable(M.dirn_to_se_coord, mapping_metatable)

---@param dirn bartbie.win.Direction
---@param amount integer
---@return bartbie.win.Direction, integer
function M.normalize_vec(dirn, amount)
    return M.dirn_to_se_coord[dirn], amount * M.dirn_to_sign[dirn]
end

---@param dirn bartbie.win.Direction
---@param amount integer
---@return bartbie.win.Direction, integer
function M.invert_vec(dirn, amount)
    return M.inverse_dirn[dirn], -amount
end

---@param dirn bartbie.win.Direction
---@param amount integer
---@return bartbie.win.Dimension, integer
function M.vec_to_dim_space(dirn, amount)
    return M.dirn_to_dim[dirn], amount * M.dirn_to_sign[dirn]
end

---@param dim bartbie.win.Dimension
---@param amount integer
---@return bartbie.win.Direction, integer
function M.dim_space_to_vec(dim, amount)
    if amount > 0 then
        return M.dim_space_to_vec_normalized(dim, amount)
    end
    return M.invert_vec(M.dim_space_to_vec_normalized(dim, amount))
end

---@param dim bartbie.win.Dimension
---@param amount integer
---@return bartbie.win.Direction, integer
function M.dim_space_to_vec_normalized(dim, amount)
    return M.dim_to_se_coord[dim], amount
end

--[[
-- winnr tracking
--]]

---@param win integer
---@return integer
function M.get_win(win)
    if win ~= 0 then
        return win
    end
    return vim.api.nvim_win_call(win, function()
        return vim.api.nvim_get_current_win()
    end)
end

---@param win integer
---@param dirn bartbie.win.Direction
---@return integer | nil nil if there is no neighbor
function M.get_neighbor(win, dirn)
    local neigh = M.get_neighbor_or_self(win, dirn)
    return neigh ~= M.get_win(win) and neigh or nil
end

---@param win integer
---@param dirn bartbie.win.Direction
---@return integer
function M.get_neighbor_or_self(win, dirn)
    return vim.api.nvim_win_call(win, function()
        vim.cmd.wincmd(M.dirn_to_key[dirn])
        return vim.api.nvim_get_current_win()
    end)
end

---@param win integer
---@param dirn bartbie.win.Direction
---@return boolean
function M.has_neighbor(win, dirn)
    return M.get_neighbor(win, dirn) and true or false
end

---@param win integer
---@return boolean
function M.is_floating(win)
    return vim.api.nvim_win_get_config(win).relative ~= ""
end

--[[
-- border changing
--]]

--- move down and right borders (i.e. south and east, edges) when possible
--- this function uses default vim.api behavior:
--- if there is no edge border to expand it uses inverse border and negative amount

--- simple thin wrapper around vim.api setters
---@param win integer
---@param dim bartbie.win.Dimension
---@param amount integer
function M.add_by_dim(win, dim, amount)
    local current = M.dim_to_nvim_get[dim](win)
    M.dim_to_nvim_set[dim](win, current + amount)
end

--- move win's border specified by direction
--- sign of amount determines whether the border will move to/away from the center
--- positive will push away
--- negative will pull to
--- examples:
---   move up border up by 10 -> "up" 10
---   move up border down by 10 -> "up" -10
---   move down border up by 10 -> "down" -10
---   move down border down by 10 -> "down" 10
---   move left border left by 10 -> "left" 10
---   move right border left by 10 -> "right" -10
---@param win integer
---@param dirn bartbie.win.Direction
---@param amount integer
function M.move_border(win, dirn, amount)
    local is_anchor = M.dirn_is_anchor[dirn]
    local neigh = M.get_neighbor(win, dirn)
    -- we are on the edge of vim, nothing to be moved
    if not neigh then
        return
    end
    --- INVARIANT:
    --- if we use the neighbor, the flip will change our border (good)
    --- otherwise, we know we are not a border so flip will not happen
    win = is_anchor and neigh or win
    amount = is_anchor and -amount or amount
    M.add_by_dim(win, M.dirn_to_dim[dirn], amount)
end

--- resize acts only on active edges (east and south)
--- if on the east or south edge of vim ui,
--- the corresponding edge will not move
---@param win integer
---@param dirn bartbie.win.Direction
---@param amount integer
function M.resize_edges(win, dirn, amount)
    -- CORRECTNESS:
    -- 1. make sure we use down|right edges
    -- 2. check if there is anything to move
    dirn, amount = M.normalize_vec(dirn, amount)
    if not M.has_neighbor(win, dirn) then
        return
    end
    M.move_border(win, dirn, amount)
end

--- resize acts only on active edges (east and south)
--- if on the east or south edge of vim ui,
--- the corresponding edge will not move
--- same as resize_edges(), but takes dimension instead
---@param win integer
---@param dim bartbie.win.Dimension
---@param amount integer
function M.resize_edges_by_dim(win, dim, amount)
    -- CORRECTNESS:
    -- we would have to re-do the checks resize_edges() does
    -- so we will just reuse it
    local dirn
    dirn, amount = M.dim_space_to_vec(dim, amount)
    M.resize_edges(win, dirn, amount)
end

--- resize acts only on active edges (east and south)
---@param win integer
---@param dirn bartbie.win.Direction
---@param amount integer
function M.resize_float(win, dirn, amount)
    -- CORRECTNESS:
    -- make sure we use down|right edges
    M.add_by_dim(win, M.vec_to_dim_space(dirn, amount))
end

--- like resize_edges(), but when win's on edge of vim ui,
--- move the opposite border instead, WITHOUT negating the amount
---@param win integer
---@param dirn bartbie.win.Direction
---@param amount integer
function M.resize_adaptive(win, dirn, amount)
    -- CORRECTNESS:
    -- 1. make sure we normalize values first
    -- 2. if on vim edge, move opposite border instead
    dirn, amount = M.normalize_vec(dirn, amount)
    if not M.has_neighbor(win, dirn) then
        amount = -amount
    end
    M.add_by_dim(0, M.dirn_to_dim[dirn], amount)
end

---@overload fun(win, dirn: bartbie.win.Direction, amount, opts: {adaptive: boolean, ignore_float: boolean, use_dim?: false})
---@overload fun(win, dim: bartbie.win.Dimension, amount, opts: {adaptive: boolean, ignore_float: boolean, use_dim: true})
function M.resize(win, dirn, amount, opts)
    local adaptive = opts.adaptive == nil and true or opts.adaptive
    if opts.use_dim then
        dirn = M.dim_space_to_vec(dirn --[[@as bartbie.win.Dimension]], amount)
        ---@cast dirn -bartbie.win.Dimension
    end
    if M.is_floating(win) then
        if opts.ignore_float then
            return
        end
        M.resize_float(win, dirn, amount)
    else
        (adaptive and M.resize_adaptive or M.resize_edges)(win, dirn, amount)
    end
end

return M
