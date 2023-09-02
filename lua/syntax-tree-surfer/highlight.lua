

local M = {}

M.namespace = vim.api.nvim_create_namespace('syntax-tree-surfer')

M.highlights = {'DiffAdd', 'DiffChange', 'DiffText'}
M.labs = {'f', 'd', 's', 'a'}

function M.makeHighlight(range, text, hl_group, id)
    vim.api.nvim_buf_set_extmark(0, M.namespace, range[1], range[2], {
        virt_text = {{text, hl_group}},
        end_row = range[3],
        end_col = range[4],
        virt_text_pos = 'overlay',
        hl_mode = 'combine',
        id = id,
    })
end

function M.clear()
    vim.api.nvim_buf_clear_namespace(0, M.namespace, 0, -1)
end
function M.setHighlights(ranges)
    M.clear()
    for i, range in ipairs(ranges) do
        local hl_group = M.highlights[i] or 'DiffDelete'
        local lab = M.labs[i] or '?'
        M.makeHighlight(range, lab, hl_group, i)
    end
end
return M
