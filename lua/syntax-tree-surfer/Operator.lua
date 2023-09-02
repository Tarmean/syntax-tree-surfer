

local M = {}

local util = require('syntax-tree-surfer.utils')
local Node = require('syntax-tree-surfer.node')
function M.up(node, typs)
    local parent = node
    while parent do
        local ptyp = parent:type()
        for _, value in ipairs(typs) do
            if ptyp == value then
                return parent
            end
        end
        parent = parent:parent()
    end
    print("no parent")
end

function M.operator(typs, multi)
    require("leap").leap{ target_windows={vim.fn.win_getid()}, action=function(n)
        -- vim.print(n)
        local node = util.get_node_at_cursor({n.pos[1]-1, n.pos[2]-1, n.pos[1]-1, n.pos[2]})
        node = M.up(node, typs)
        if node then
            Node:new(node):visual_select()
        end
    end, multiselect=multi}
end

M.Scopes = {lua = {
    in_scope = {"block"},
    around_scope =
    {
        "do_statement",
        "while_statement",
        "repeat_statement",
        "if_statement",
        "for_statement",
        "function_declaration",
        "function_definition"
    },
    func = {
        "function_declaration",
        "function_definition",
    },
    statement = {"statement"}, -- app
    expr = {"expression"},
    call = {"function_call"},
    string = {"string"},
    -- arg = {"appendable"}
    -- arguments.children*
    -- table_constructor.children*(name,value)
    comment = {"comment"}
}}


return M
