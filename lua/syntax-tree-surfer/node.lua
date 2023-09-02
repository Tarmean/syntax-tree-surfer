require ('syntax-tree-surfer.reload')()
local utils = require('syntax-tree-surfer.utils')
local ts_utils = require("nvim-treesitter.ts_utils")

--- @class Node
local Node = {node=nil}
---Wrapper around tree-sitter nodes
---@param param {node: any}
---@return any
function Node:new(param)
	-- wrap raw nodes in an object
	if type(param) == "userdata" then
		param = {node = param}
	end
	if (param == nil) or (param.node == nil) then
		return nil
	end
	local o = param or {}
	setmetatable(o, self)
	self.__index = self
	return o
end


---@param range Range
function Node:is_contained_by(range)
	return utils.contains(utils.normalize_range(range), utils.normalize_range({self.node:range()}))
end
---@param range Range
function Node:contains(range)
	return utils.contains({self.node:range()}, range)
end

function Node:visual_select()
	utils.visual_select(0, self.node)
end
function Node:parent()
	local parentNode = self.node:parent()
	return Node:new(parentNode)
end
function Node:fieldName(name, count)
	local subs = self.node:field(name)
	return Node:new(subs[count or 1])
end
function Node:named_child(idx)
	local subs = self.node:named_child(idx)
	if subs == nil then
		return nil
	end
	return Node:new(subs)
end
function Node:child(idx)
	local subs = self.node:child(idx)
	if subs == nil then
		return nil
	end
	return Node:new(subs)
end

local function last_child(n)
	local parent = n:parent()
	if parent then
		local count = parent:child_count()
		return parent:child(count - 1)
	end
end
local function first_child(n)
	local parent = n:parent()
	if parent then
		return parent:child(0)
	end
end
function Node:next()
	return Node:new(ts_utils.get_next_node(self.node, true, true))
end
function Node:prev()
	return Node:new(ts_utils.get_previous_node(self.node, true, true))
end


return Node
