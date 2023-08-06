require ('syntax-tree-surfer.reload')()

local Node = require('syntax-tree-surfer.node')
local utils = require("syntax-tree-surfer.utils")
local M = {}


---@return Node
function M.get()
	local usernode = utils.get_node_at_cursor(utils.getRange(), 0, false)
	return Node:new(usernode)
end

return M
