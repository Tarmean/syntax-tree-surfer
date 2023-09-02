require ('syntax-tree-surfer.reload')()

local Node = require('syntax-tree-surfer.node')
local utils = require("syntax-tree-surfer.utils")
local M = {}


local function allNodes(transRelevant, directRelevant)
	local root = utils.get_root_at_cursor(0,false)
	local out = {}
	local function recurse(n)
		local relevant = false
		for i = 0, n:named_child_count()-1 do
			local c = n:named_child(i)
			relevant = recurse(c) or relevant
		end
		if transRelevant and transRelevant(n) then
			relevant = true
		end
		if (not transRelevant or relevant) and (not directRelevant or directRelevant(n)) then
			table.insert(out, n)
		end
		return relevant
	end
	recurse(root)
	return out
end
local ts_utils = require("nvim-treesitter.ts_utils")
local function get_node_text(node, buf)
	local sr, sc, er, ec = node:range()
	if sr ~= er then return nil end
	return string.sub(vim.api.nvim_buf_get_lines(buf, sr, er+1, false)[1] or "", sc+1, ec)
	-- return vim.api.nvim_buf_get_lines(buf, sr, er, false)
end
local function match_ident_pred(ident)
	if not ident then return nil end
	return function(node)
		if node:type() ~= "identifier" then
			return false
		end
		local text = get_node_text(node, 0)
		if text and text:match(ident) then
			return true
		end
	end
end
local function match_node_typ(typ)
	if not typ then return nil end
	return function(node)
		return node:type() == typ
	end
end


--- @class BufFilter
--- @field contains  string
--- @field typ string
local BufFilter = {}
function BufFilter:new(typ, filter)
	local o = { typ = typ, contains = filter }
	setmetatable(o, self)
	self.__index = self
	return o
end
function BufFilter:set_contains(contains)
	self.contains = contains
end
function BufFilter:set_typ(typ)
	self.typ = typ
end
function BufFilter:all()
	return allNodes(match_ident_pred(self.contains), match_node_typ(self.typ))
end
local function having(list, pred)
	local out = {}
	for _, v in ipairs(list) do
		if pred(v) then
			table.insert(out, v)
		end
	end
	return out
end

local function col_past(nodes, pos)
	local out = having(nodes, function(n)
		local _, sc, er, ec = n:range()
		return er == pos[3] and (ec > pos[4] or sc > pos[2])
	end)
	table.sort(out, function(a, b)
		local _, sc, _, ec = a:range()
		local _, sc2, _, ec2 = b:range()
		return ec < ec2 or ec == ec2 and sc < sc2
	end)
	return out
end
local function col_pre(nodes, pos)
	local out = having(nodes, function(n)
		local sr, sc, _, ec = n:range()
		return sr == pos[1] and (sc < pos[2] or ec < pos[4])
	end)
	table.sort(out, function(a, b)
		local _, sc, _, ec = a:range()
		local _, sc2, _, ec2 = b:range()
		return sc > sc2 or sc == sc2 and ec < ec2
	end)
	return out
end
local function line_past(nodes, pos)
	local out = having(nodes, function(n)
		local sr, sc, er, ec = n:range()
		return er > pos[3]
	end)
	table.sort(out, function(a, b)
		local _, _, er, _ = a:range()
		local _, _, er2, _ = b:range()
		return er < er2
	end)
	return out
end
local function line_before(nodes, pos)
	local out = having(nodes, function(n)
		local sr, sc, er, ec = n:range()
		return sr < pos[1]
	end)
	table.sort(out, function(a, b)
		local sr, _, _, _ = a:range()
		local sr2, _, _, _ = b:range()
		return sr > sr2
	end)
	return out
end

function BufFilter:left(node)
	return col_pre(self:all(), {node:range()})[1]
end
function BufFilter:right(node)
	return col_past(self:all(), {node:range()})[1]
end
function BufFilter:up(node)
	return line_before(self:all(), {node:range()})[1]
end
function BufFilter:down(node)
	return line_past(self:all(), {node:range()})[1]
end
function BufFilter:seekNext(node)
	return self:right(node) or self:down(node) or self:left(node) or self:up(node)
end
function BufFilter:seekPrev(node)
	return BufFilter:left(node) or BufFilter:up(node) or BufFilter:right(node) or BufFilter:down(node)
end

M.BufFilter = BufFilter

---@return Node
function M.get()
	local usernode = utils.get_node_at_cursor(utils.getRange(), 0, false)
	return Node:new(usernode)
end

function M.idents()

	return allNodes(nil, function (n) return n:named() and n:child_count() == 0 end)

end


return M
