
local M = {}
local utils = require'syntax-tree-surfer.utils'
local function gen_labels_work(node)
    local named_children = node:named_child_count()
    local out = {}
    for i = 0,named_children-1 do
        local cur = node:named_child(i)
        if not cur then
            error("gen_labels_work: named_children returned nil")
        end
        table.insert(out, cur)
    end
    -- if #out == 1 and utils.equals(out[1]:range(),node:range()) then
    --     return gen_labels_work(out[1])
    -- end
    return out
end
function M.gen_labels(node)
    if node:child_count() == 0 and node:parent() ~= nil then
        return gen_labels_work(node:parent())
    end
    return gen_labels_work(node)
end
return M
