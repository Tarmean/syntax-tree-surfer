local TreeNodes = require "syntax-tree-surfer.TreeNodes"

function gatherFreeVars(node0)
    local freeVars = {}
    function visit(node)
        if getmetatable(node) == TreeNodes.Ref then
            table.insert(freeVars, node.name)
        else
            node:visit1(visit)
        end
    end
    visit(node0)
    return freeVars
end


return {
    freeVars = gatherFreeVars,
}





