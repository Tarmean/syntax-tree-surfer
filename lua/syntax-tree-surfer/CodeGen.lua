local gatherFreeVars = require('syntax-tree-surfer.Visitor').freeVars
local function backmap(rules)
    local back = {}
    for k, rule in pairs(rules) do
        for _, field in ipairs(gatherFreeVars(rule)) do
            back[field] = back[field] or {}
            table.insert(back[field], k)
        end
    end
    return back
end

local function sumCost(list)
    local sum = 0
    for _, v in ipairs(list) do
        sum = sum + v.cost
    end
    return sum
end

---@class Derivation
---@field substitutions Derivation[]
---@field body Obj
---@field uniqueKeys string[]
local Derivation = {}
--- A derivation is a rule application.
--- We track which rule was appied, which substitutions were made.
--- If some values should occur at most once in the derivation, we track
--- which values were used.
---@param rule any
---@param substitutions any
---@param uniqueKeys any
---@return Derivation
function Derivation:new(rule, substitutions, uniqueKeys)
    local o = {}
    setmetatable(o, self)
    o.body = rule
    o.substitutions = substitutions
    o.uniqueKeys = uniqueKeys
    o.cost = (#substitutions == 0 and 5 or 0) +  sumCost(substitutions) + o.body:getCost()
    return o
end

function Derivation:key()
    return self.body:getKey()
end

local function plusUsed(new, used)
    local out = {}
    for _, v in ipairs(new.uniqueKeys) do
        if used[v] then
            return false
        end
        out[v] = true
    end
    for _, v in ipairs(used) do
        out[v] = true
    end
    return out
end
local function prepend(elem, table)
    local out = { elem }
    for _, v in ipairs(table) do
        table.insert(out, v)
    end
    return out
end

local M = {}

local function stepSubs(src, wasNew, env, idx, req, new, used)
        for _, v in ipairs(src) do
            local newUsed = plusUsed(v, used)
            if newUsed then
                for u, r in M.subs(wasNew, env, idx + 1, req, new, newUsed) do
                    coroutine.yield(u, prepend(v, r))
                end
            end
        end
end
M.subs = function(containsNew, env, idx, req, new, used)
    return coroutine.wrap(function()
        if idx > #req then
            if containsNew then
                coroutine.yield(used, {})
            end
            return
        end
        local cur = req[idx]
        stepSubs(new[cur] or {}, true, env, idx, req, new, used)
        stepSubs(env[cur] or {}, containsNew, env, idx, req, new, used)
    end)
end

local function substitutions(rule, env, new)
    return M.subs(false, env, 1, gatherFreeVars(rule), { [new:getKey()] = new }, {})
end
local function allSubstitutions(rule, env)
    return M.subs(true, env, 1, gatherFreeVars(rule), {}, {})
end

local function extend(env, derivations, new)
    for rule in pairs(env[new.rulekey]) do
        for uniq, subst in substitutions(rule, env, new) do
            local newderiv = Derivation:new(rule, subst, uniq)
            table.insert(derivations, newderiv)
        end
    end
end
---@return Derivation[]
local function initial(rules, env)
    local derivations = {}
    for _, rule in pairs(rules) do
        for uniq, subst in allSubstitutions(rule, env) do
            local newderiv = Derivation:new(rule, subst, uniq)
            table.insert(derivations, newderiv)
        end
    end
    return derivations
end

return {
    Derivation = Derivation,
    extend = extend,
    initial = initial
}
