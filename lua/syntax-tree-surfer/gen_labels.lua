
local M = {}
local utils = require'syntax-tree-surfer.utils'
local function is_interesting(node)
    return node:named() or node:child_count() > 0
end
local function gen_labels_work(node)
    local children = node:child_count()
    local named_children = node:named_child_count()
    local out = {}
    for i = 0,children-1 do
        local cur = node:child(i)
        if named_children == 0 or is_interesting(cur) then
            table.insert(out, cur)
        end
    end
    if #out == 1 and utils.equals(out[1]:range(),node:range()) then
        return gen_labels_work(out[1])
    end
    return out
end
function M.gen_labels(node)
    if node:child_count() == 0 and node:parent() ~= nil then
        return gen_labels_work(node:parent())
    end
    return gen_labels_work(node)
end
return M
