local M = {}
local allIdents = require("syntax-tree-surfer.global_node").idents

local function allMatches(text, pat)
    local offset = 0
    return function()
        local s, e = string.find(text, pat, offset)
        if s then
            offset = e + 1
            return s, e
        end
    end
end

function M.words(nodes, texts, startLine, endLine)
    local words = {}
    for _, ident in ipairs(nodes) do
        local rs, cs, re, ce = ident:range()
        if rs == re and rs+1 >= startLine and rs <= endLine then
            local theLine = texts[rs+1-startLine]
            if theLine then
                local word = theLine:sub(cs+1, ce)
                table.insert(words, {
                    word = word,
                    line = rs +1,
                    l = cs+1,
                    r = ce,
                })
            end
        end
    end
    return words
end

function M.bigrams(word)
    local i = 0
    return function()
        i = i + 1
        local bigram = word:sub(i, i + 1)
        if #bigram < 2 then
            return
        end
        return i, bigram
    end
end

function M.wordCounts(words)
    local counts = {}
    for _, word in ipairs(words) do
        if counts[word.word] then
            counts[word.word] = counts[word.word] + 1
        else
            counts[word.word] = 1
        end
    end
    return counts
end

function M.greedy(words)
    local mappings = {}
    for _, word in ipairs(words) do
        local found = false
        for pos, bi in M.bigrams(word.word) do
            if not mappings[bi] then
                mappings[bi] = true
                -- word.pos[2] = word.pos[2] + pos - 1
                table.insert(mappings, { pos = { word.line, word.l + pos - 1 } })
                found = true
                break
            end
        end
        -- if not found then
        --     mappings[grams[1]] = word
        -- end
    end
    return mappings
end

function M.targets()
    local info = vim.fn.winsaveview()
    local height = vim.fn.winheight(vim.fn.winnr())
    local startLine = info.topline-1
    local endLine = startLine + height-1
    local text = vim.api.nvim_buf_get_lines(0, startLine, endLine, false)
    local words = M.words(allIdents(), text, startLine, endLine)
    return M.greedy(words)
end
function M.leapGrams()
    M.clearHighlights()
    M.setHighlights(M.targets())
    -- require('leap').leap({
    --     targets = M.targets()
    -- })
end


M.ngramNamespace = vim.api.nvim_create_namespace("ngrams")
M.highlightGroup = "Ngrams"
vim.api.nvim_set_hl(M.ngramNamespace, M.highlightGroup, { sp = "#203020", underline=true, blend=10 })

function M.setHighlights(target)
    vim.api.nvim_set_hl_ns(M.ngramNamespace)
    for _, mapping in ipairs(target) do
        vim.api.nvim_buf_add_highlight(0, M.ngramNamespace, M.highlightGroup, mapping.pos[1]-1, mapping.pos[2]-1, mapping.pos[2] + 1)
    end
end
function M.clearHighlights()
    vim.api.nvim_buf_clear_namespace(0, M.ngramNamespace, 0, -1)
end


return M
