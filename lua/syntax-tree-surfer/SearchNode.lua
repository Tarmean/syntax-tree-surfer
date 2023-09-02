

local TN = require "syntax-tree-surfer.TreeNodes"

local function matches(tree, pattern)
    local anyMatch = false
    local function go(node)
        if tree:getKey() and tree:getKey():match(pattern) then
            anyMatch = true
        end
        if TN.Str:is(tree) and tree.str:match(pattern) then
            anyMatch = true
        end
        node:visit1(go)
    end
    go(tree)
    return anyMatch
end

local function containsString(tree, pattern)
    local anyMatch = false
    local matchHere
    local function recurse(node)
        if not anyMatch and not node:isForkPoint() then
            node:visit1(matchHere())
        end
    end
    matchHere = function(node)
        if TN.Str:is(node) and node.str:match(pattern) then
            anyMatch = true
        end
        recurse(node)
    end
    matchHere(tree)
    return anyMatch
end

return {matches=matches, containsString=containsString}
