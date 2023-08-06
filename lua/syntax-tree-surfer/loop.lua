local actions = require('syntax-tree-surfer.actions')


local M = {}

function M.loop()
    vim.cmd("norm! gv")
    vim.cmd("redraw!")
    local char = vim.fn.nr2char(vim.fn.getchar())
    if char == ' ' then
        actions.up()
    elseif char == 'j' then
        actions.down(1)
    elseif char == 'k' then
        actions.down(2)
    elseif char == 'l' then
        actions.down(3)
    else
        return
    end
end

vim.cmd("command! Zoom lua require('syntax-tree-surfer.loop').loop()")

return M
