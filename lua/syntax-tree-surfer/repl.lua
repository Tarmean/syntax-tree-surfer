require('syntax-tree-surfer.reload')(true)
local gram = require('syntax-tree-surfer.TreeNodes').parse("lua")
local comp = require('syntax-tree-surfer.CodeGen')
local matches = require('syntax-tree-surfer.SearchNode').matches
-- for k,r in pairs(gram) do
--     if matches(
--         r,
--         ".*"
--     ) then
--         print(k,': ', r)
--     end
-- end
-- vim.print(gatherFreeVars(gram["while_statement"]))
-- vim.print(gatherFreeVars(gram["while_statement"]))
-- for _,k in ipairs(comp.initial(gram, {}) )do
--     print(k.body.key, k.body)
-- end
