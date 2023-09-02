





---@generic K,T
---@param funcs table<K,T>
---@param step fun(func:T, result:table<K,T>, k:K):T
---@param is_changed nil|fun(a:T, b:T):boolean
---@return table<K,T>
return function(funcs, step, is_changed)
    local result = {}
    is_changed = is_changed or function(a,b) return a ~= b end
    while true do
        local changed = false
        local next = {}
        for k,v in pairs(funcs) do
            local new = step(v, result, k)
            if is_changed(result[k], new) then
                changed = true
            end
            next[k] = new
        end
        if not changed then
            break
        end
        result = next
    end
    return result
end
