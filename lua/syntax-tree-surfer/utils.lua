require ('syntax-tree-surfer.reload')()

local ts_utils = require('nvim-treesitter.ts_utils')
local ts = require('vim.treesitter')
local parsers = require('nvim-treesitter.parsers')
local M = {}

--- @alias Range number[]

---@param o1 Range
---@param o2 Range
function M.contains(o1, o2)
    return (o1[1] < o2[1] or (o1[1] == o2[1] and o1[2] <= o2[2]))
        and (o1[3] < o2[3] or (o1[3] == o2[3] and o1[4] <= o2[4]))
end


M.visual_select = function(buf, node)
	local start_row, start_col, end_row, end_col = ts_utils.get_vim_range({ vim.treesitter.get_node_range(node) }, buf)
	vim.fn.setpos("'<", { buf, start_row, start_col, 0 })
	vim.fn.setpos("'>", { buf, end_row, end_col, 0 })

	vim.cmd("normal! Vgv")
end

---@param o1 any|table First object to compare
---@param o2 any|table Second object to compare
---@param ignore_mt boolean True to ignore metatables (a recursive function to tests tables inside tables)
function M.equals(o1, o2, ignore_mt)
    if o1 == o2 then return true end
    local o1Type = type(o1)
    local o2Type = type(o2)
    if o1Type ~= o2Type then return false end
    if o1Type ~= 'table' then return false end

    if not ignore_mt then
        local mt1 = getmetatable(o1)
        if mt1 and mt1.__eq then
            --compare using built in method
            return o1 == o2
        end
    end

    local keySet = {}

    for key1, value1 in pairs(o1) do
        local value2 = o2[key1]
        if value2 == nil or M.equals(value1, value2, ignore_mt) == false then
            return false
        end
        keySet[key1] = true
    end

    for key2, _ in pairs(o2) do
        if not keySet[key2] then return false end
    end
    return true
end

function M.get_root_at_cursor(winnr, ignore_injected_langs)
  winnr = winnr or 0
  local cursor = vim.api.nvim_win_get_cursor(winnr)
  local cursor_range = { cursor[1] - 1, cursor[2] }

  local buf = vim.api.nvim_win_get_buf(winnr)
  local root_lang_tree = parsers.get_parser(buf)
  if not root_lang_tree then
    return
  end

  local root --  ---@type TSNode|nil
  if ignore_injected_langs then
    for _, tree in ipairs(root_lang_tree:trees()) do
      local tree_root = tree:root()
      if tree_root and ts.is_in_node_range(tree_root, cursor_range[1], cursor_range[2]) then
        root = tree_root
        break
      end
    end
  else
    root = ts_utils.get_root_for_position(cursor_range[1], cursor_range[2], root_lang_tree)
  end

  return root
end
-- @param range Range
function M.get_node_at_cursor(range, winnr, ignore_injected_langs)
  local root = M.get_root_at_cursor(winnr, ignore_injected_langs)
  if not root then
      return nil
  end
  return root:named_descendant_for_range(range[1], range[2], range[3], range[4])
end
---@param range Range
---@return Range
function M.normalize_range(range, buf)
    local out = {range[1], range[2], range[3], range[4]}
    if out[4] == 0 then
        if not buf or buf == 0 then
          out[4] = vim.fn.col { out[3], "$" } - 1
        else
          out[4] = #vim.api.nvim_buf_get_lines(buf, out[3], out[3]+1, false)[1]
        end
        out[4] = math.max(out[4], 0)
        out[3] = out[3] - 1
    end
    return out
end


local function isVisual(mode)
	return mode == 'v' or mode == 'V' or mode == 'CTRL-V'
end
-- vim range: 1-indexed and end col is one past the ending
-- tree-sitter: 0-index and end col is ending-exclusive

---@return Range
function M.getRange()
	local mode = vim.fn.mode()
	if isVisual(mode) then
		local _,lr, lc, _ = unpack(vim.fn.getpos("'<"))
		local _, rr, rc,_ = unpack(vim.fn.getpos("'>"))
		return {lr-1, lc-1, rr-1,rc}
	else
		local _, lr, lc, _ = unpack(vim.fn.getpos('.'))
		return {lr-1, lc-1, lr-1, lc}
	end
end

return M
