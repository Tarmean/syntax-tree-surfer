
require('syntax-tree-surfer.reload')()

local gl = require('syntax-tree-surfer.global_node')
local Node = require('syntax-tree-surfer.node')
local U = require('syntax-tree-surfer.utils')
local labels = require('syntax-tree-surfer.gen_labels')
local M = {}

---@param lam fun(node: Node): Node|nil
local function trans(lam)
    local node = gl.get()
    if not node then
        return node
    end
    local next = lam(node)
    if next then
        next:visual_select()
        return
    end
end
---@param lam fun(node:Node):Node|nil
---@return fun(node:Node):Node|nil
local function upwards(lam)
    return function(node)
        local start_l, _, start_r, _ = node.node:range()
        while node ~= nil do
            local next = lam(node)
            if next then
                return next
            end
            local up = node:parent()
            local cur_l, _, cur_r, _ = up.node:range()
            if cur_l ~= start_l or cur_r ~= start_r then
                return
            end
            node = up
        end
    end
end
---@param lam fun(node:Node):Node|nil
---@return fun(node:Node):Node|nil
local function until_change(lam)
    return function(node)
        if node == nil then return nil end
        local range = U.normalize_range({node.node:range()})
        local last = node
        node = lam(node)
        while node ~= nil do
            local up_range = U.normalize_range({node.node:range()})
            if not U.equals(range, up_range, true) then
                return node
            end
            last = node
            node = lam(node)
        end
        return last
    end
end

---@type BufFilter|nil
M.filter = nil

function M.findPat(string)
    vim.cmd("norm! gv")
    M.filter = M.filter or gl.BufFilter:new()
    M.filter:set_contains(string)
    trans(function (n)
        return Node:new(M.filter:seekNext(n.node))
    end)
end
function M.findTyp(string)
    vim.cmd("norm! gv")
    M.filter = M.filter or gl.BufFilter:new()
    M.filter:set_typ(string)
    trans(function (n)
        return Node:new(M.filter:seekNext(n.node))
    end)
end
function M.clearFilter()
    vim.cmd("norm! gv")
    M.filter = nil
    M.current()
end
function M.seekForward(idx)
    vim.cmd("norm! gv")
    trans(function(node)
        if M.filter then
            return Node:new(M.filter:seekNext(node.node))
        end
    end)
end
function M.down(idx)
    vim.cmd("norm! gv")
    trans(function(node)
        if M.filter then
            return Node:new(M.filter:down(node.node))
        end
        local labs = labels.gen_labels(node.node)
        return Node:new((labs or {})[idx+1])
    end)
end

function M.prev()
    trans(function(node)
        if M.filter then
            return Node:new(M.filter:left(node.node))
        end
        return node:prev()
    end)
end
function M.next()
    trans(function(node)
        if M.filter then
            return Node:new(M.filter:right(node.node))
        end
        return node:next()
    end)
end
function M.up()
    trans(until_change(function(node)
        if M.filter then
            return Node:new(M.filter:up(node.node))
        end
        return node:parent()
    end))
end

function M.field(name, idx)
    trans(upwards(function(node)
        return node:fieldName(name, idx)
    end))
end
function M.current()
    gl.get():visual_select()
end
function M.outwardsV()
    vim.cmd("norm! gv")
    local current = gl.get()
    local old = U.getRange()
    if current:is_contained_by(old) then
        current = until_change(function(node)
            return node:parent()
        end)(current) or current
    end
    current:visual_select()
end


vim.cmd(
"command! -nargs=1 -complete=customlist,ts_utils#list_definitions GoToNode lua require('syntax-tree-surfer.actions').down(<f-args>)")
vim.cmd(
"command! -nargs=1 -complete=customlist,ts_utils#list_definitions GoToField lua require('syntax-tree-surfer.actions').field(<f-args>)")
vim.cmd("command! GoToParent lua require('syntax-tree-surfer.actions').up()")
vim.cmd("command! GoToHere lua require('syntax-tree-surfer.actions').current()")
vim.cmd("command! GoToOutV lua require('syntax-tree-surfer.actions').outwardsV()")

return M
