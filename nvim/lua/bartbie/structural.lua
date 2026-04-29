local ts = vim.treesitter
local tslib = require("bartbie.treesitter")
local textlib = require("bartbie.text")
local lisplib = tslib.lisp

local M = {}

local _ok, _sel = pcall(require, "vim.treesitter._select")
if not _ok then
    vim.notify("vim.treesitter._select cant be imported", vim.log.levels.WARN)
end

--- setup function for operations
--- operand is either nearest named node or nearest expr/form for lisps
---@param operand? "expr" | "form" default: expr
---@param node TSNode?
---@return TSNode?, boolean, TSNode?
local function operand_and_ctx(operand, node)
    local this, parent
    if node then
        this = tslib.nearest_named(node)
    else
        this = vim.treesitter.get_node()
    end
    if not this then
        return nil, false, nil
    end
    local is_lisp = lisplib.is_lisp(0, this)
    if is_lisp then
        if operand == "form" then
            this = lisplib.nearest_form(this)
            if not this then
                return nil, true, nil
            end
        end
        this, parent = lisplib.expr_and_form(this)
    else
        parent = this:parent()
    end
    return this, is_lisp, parent
end

--- setup function for operations
---@param node TSNode
---@param is_lisp boolean
---@param direction "next" | "prev"
---@return TSNode?
local function get_sib(node, is_lisp, direction)
    if is_lisp then
        if direction == "next" then
            return lisplib.next_sibling_expr(node)
        end
        return lisplib.prev_sibling_expr(node)
    end
    if direction == "next" then
        return node:next_named_sibling()
    end
    return node:prev_named_sibling()
end

-- incremental selection

function M.select_current()
    if _ok then
        _sel.select_parent(1)
    end
end

function M.select_parent(count)
    if _ok then
        _sel.select_parent(count or 1)
    end
end

function M.select_child(count)
    if _ok then
        _sel.select_child(count or 1)
    end
end

function M.select_next(count)
    if _ok then
        _sel.select_next(count or 1)
    end
end

function M.select_prev(count)
    if _ok then
        _sel.select_prev(count or 1)
    end
end

function M.select_parent_vcount1()
    M.select_parent(vim.v.count1)
end

function M.select_child_vcount1()
    M.select_child(vim.v.count1)
end

function M.select_next_vcount1()
    M.select_next(vim.v.count1)
end

function M.select_prev_vcount1()
    M.select_prev(vim.v.count1)
end

-- movement
-- TODO:
-- lisp-proof it (dont act on multi-symbols parts)
-- reimpl move to be spatial-aware
-- (can leave old funcs, maybe useful in future)

---@param trgt TSNode?
local function move_to(trgt)
    if not trgt then
        return
    end
    tslib.move_cursor_to_node(0, trgt)
end

function M.move_next()
    local node = operand_and_ctx()
    if not node then
        return
    end
    move_to(node:next_named_sibling())
end

function M.move_prev()
    local node = operand_and_ctx()
    if not node then
        return
    end
    move_to(node:prev_named_sibling())
end

function M.move_parent()
    -- TODO: lisp
    local node, is_lisp, parent = operand_and_ctx()
    if not node then
        return
    end
    move_to(parent)
end

function M.move_child()
    -- TODO: lisp
    local node, is_lisp = operand_and_ctx()
    if not node then
        return
    end
    move_to(is_lisp and lisplib.get_head(node) or tslib.first_named_child(node))
end

-- edit

--- replace enclosing form with the expression under cursor.
function M.raise()
    local src, is_lisp, dst = operand_and_ctx()
    if not src or not dst then
        return
    end
    tslib.replace_node(0, src, dst)
end

function M.delete_node()
    local this = operand_and_ctx()
    if this then
        tslib.delete_node(0, this)
    end
end

---@param direction "next" | "prev"
function M.swap_siblings(direction)
    local this, is_lisp = operand_and_ctx()
    if not this then
        return
    end
    local other = get_sib(this, is_lisp, direction)
    if not other then
        return
    end
    tslib.apply_disjoint_node_edits(0, {
        tslib.edit.swap(this, other),
        tslib.edit.swap(other, this),
    })
end

function M.swap_siblings_next()
    M.swap_siblings("next")
end

function M.swap_siblings_prev()
    M.swap_siblings("prev")
end

-- lisp only ops

--- lisp only, remove enclosing delimiters
function M.splice()
    --- CORRECTNESS:
    --- if cursor on delimiter, target is current form
    --- this makes splice special
    local form, is_lisp = operand_and_ctx("form")
    if not is_lisp or not form then
        return
    end
    lisplib.delete_form_delims(0, form)
end

--- lisp only, move delimiter before/after sibling in direction to slurp it
---@param direction "left"|"right"
function M.slurp(direction)
    local form, is_lisp, parent_form = operand_and_ctx("form")
    if not form or not is_lisp then
        return
    end
    local sib
    if direction == "right" then
        if parent_form then
            sib = lisplib.next_sibling_expr(form)
        else
            sib = form:next_named_sibling()
        end
    else
        if parent_form then
            sib = lisplib.prev_sibling_expr(form)
        else
            sib = form:prev_named_sibling()
        end
    end
    if not sib then
        return
    end
    lisplib.move_delim(0, form, direction, sib)
end

--- lisp only, move right delimiter after next sibling of form to slurp it
function M.slurp_right()
    M.slurp("right")
end

--- lisp only, move right delimiter before prev sibling of form to slurp it
function M.slurp_left()
    M.slurp("left")
end

--- lisp only, move delimiter before/after head/foot to barf it
---@param direction "left"|"right"
function M.barf(direction)
    local form, is_lisp = operand_and_ctx("form")
    if not form or not is_lisp then
        return
    end
    -- 0 (a 1 b) 2
    -- 0 (a 1) b 2
    -- 0 (a 1 b) 2
    -- 0 a (1 b) 2
    local new_tip
    if direction == "right" then
        new_tip = lisplib.get_foot(form)
        new_tip = new_tip and lisplib.prev_sibling_expr(new_tip) or nil
    else
        new_tip = lisplib.get_head(form)
        new_tip = new_tip and lisplib.next_sibling_expr(new_tip) or nil
    end
    if not new_tip then
        return
    end
    lisplib.move_delim(0, form, direction, new_tip)
end

--- lisp only, move right delimiter before foot to barf it
function M.barf_right()
    M.barf("right")
end

--- lisp only, move right delimiter after head to barf it
function M.barf_left()
    M.barf("left")
end

-- hydra

local ESC = vim.keycode("<Esc>")

local function open_hint()
    local lines = { " n/N expand/shrink  j/k next/prev  r raise  d delete  <Esc> quit " }
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    local width = #lines[1]
    local win = vim.api.nvim_open_win(buf, false, {
        relative = "editor",
        row = vim.o.lines - 3,
        col = math.floor((vim.o.columns - width) / 2),
        width = width,
        height = 1,
        style = "minimal",
        border = "rounded",
        focusable = false,
    })
    vim.api.nvim_set_option_value("winhl", "Normal:ModeMsg", { win = win })
    return win
end

function M.node_mode()
    M.select_parent(1)
    local hint = open_hint()
    vim.cmd("redraw")
    local ok, err = pcall(function()
        local count = 0
        while true do
            local ok2, key = pcall(vim.fn.getcharstr)
            if not ok2 or key == ESC then
                break
            end
            if key:match("^%d$") then
                count = count * 10 + tonumber(key)
            else
                local c = math.max(count, 1)
                if key == "n" then
                    M.select_parent(c)
                elseif key == "N" then
                    M.select_child(c)
                elseif key == "j" then
                    M.select_next(c)
                elseif key == "k" then
                    M.select_prev(c)
                elseif key == "r" then
                    M.raise()
                elseif key == "d" then
                    M.delete_node()
                end
                count = 0
                vim.cmd("redraw")
            end
        end
    end)
    if vim.api.nvim_win_is_valid(hint) then
        vim.api.nvim_win_close(hint, true)
    end
    if not ok then
        vim.notify(err, vim.log.levels.ERROR)
    end
end

-- textobjects

function M.node_textobject(ai_type)
    local node = ts.get_node()
    if not node then
        return nil
    end
    if ai_type == "i" and node:named_child_count() > 0 then
        local first = node:named_child(0)
        ---@cast first -?
        local last = node:named_child(node:named_child_count() - 1)
        ---@cast last -?
        local sr, sc = first:range()
        local _, _, er, ec = last:range()
        return { from = { line = sr + 1, col = sc + 1 }, to = { line = er + 1, col = ec } }
    end
    local sr, sc, er, ec = node:range()
    return { from = { line = sr + 1, col = sc + 1 }, to = { line = er + 1, col = ec } }
end

function M.buffer_textobject()
    local from = { line = 1, col = 1 }
    local to = {
        line = vim.fn.line("$"),
        col = math.max(vim.fn.getline("$"):len(), 1),
    }
    return { from = from, to = to }
end

return M
