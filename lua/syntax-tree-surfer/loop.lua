local actions = require('syntax-tree-surfer.actions')
local gen_labels = require('syntax-tree-surfer.gen_labels')
local highlight = require('syntax-tree-surfer.highlight')
local global_node = require('syntax-tree-surfer.global_node')


local M = {}

local function to_ranges(nodes)
    local ranges = {}
    for _, node in ipairs(nodes) do
        table.insert(ranges, {node:range()})
    end
    return ranges
end
function M.loop(l)
    if l ~= '' then
        vim.cmd("norm! gv")
    end
    local node = global_node.get()
    local groups = gen_labels.gen_labels(node.node)
    highlight.setHighlights(to_ranges(groups))
    vim.cmd('redraw!')
    local char = vim.fn.nr2char(vim.fn.getchar())
    if char == 'k' then
        actions.up()
    elseif char == 'j' then
        actions.down(0)
    elseif char == 'h' then
        actions.prev()
    elseif char == 'l' then
        actions.next()
    elseif char == 'f' then
        local res = vim.fn.input({prompt = 'Rule: '})
        actions.findTyp(res)
    elseif char == '/' then
        local res = vim.fn.input({prompt = 'Find: '})
        actions.findPat(res)
    elseif char == 'd' then
        actions.down(0)
    elseif char == 's' then
        actions.down(1)
    elseif char == 'a' then
        actions.down(2)
    else
        highlight.clear()
        return
    end
    vim.fn.feedkeys(':Zoom\n')
end

vim.cmd("command! -range=0 Zoom lua require('syntax-tree-surfer.loop').loop('<range>')")

return M
