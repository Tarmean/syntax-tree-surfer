


local utils = require'syntax-tree-surfer.utils'
local fix = require'syntax-tree-surfer.fixpoint'


---@class Obj Obj
---@field key string|nil
---@field meta {}
local Obj = {}
function Obj:__tostring()
    if self.children then
        local children = {}
        for _, child in ipairs(self.children) do
            table.insert(children, child:__tostring())
        end
        return self.tag .. "(" .. table.concat(children, ", ") .. ")"
    elseif self.child then
        return self.tag .. "(" .. self.child:__tostring() .. ")"
    elseif self.tag == 'pat' then
        return "/" .. self.str .. "/"
    elseif self.tag == 'str' then
        return "'" .. self.str .. "'"
    elseif self.name then
        return self.tag .. "(" .. self.name .. ")"
    else
        return self.tag
    end
end
function Obj:is(obj)
    return getmetatable(obj) == self
end
function Obj:isForkPoint()
    return self.meta.forkPoint or false
end
function Obj:isMatchPoint()
    return self.meta.match or false
end

function Obj:new(super)
    local o = super or {}
    setmetatable(o, self)
    self.__index = self
    return o
end
function Obj:sub(tag)
    if not tag then
        error("tag is nil")
    end
    local o = {}
    setmetatable(o, self)
    self.__index = self
    o.__tostring = self.__tostring
    o.tag = tag
    o._parent = self
    return o
end
function Obj:super()
    return self._parent.new(self)
end
---@alias Field string

---@param env any
---@return Field[]
function Obj:getCost()
    return 1
end
function Obj:getKey()
    return self.key
end

---@class Prec : Obj
---@field child Obj
---@field precedences number
---@field dir string|nil
local Prec = Obj:sub("prec")
function Prec:new(child, precedences, dir, key)
    local o = self:super()
    o.child = child
    o.key = key
    o.precedences = precedences
    o.dir = dir
    return o
end
function Prec:visit1(visitor)
    visitor(self.child)
end


---@class Collection : Obj
---@field children Obj[]
local Collection = Obj:sub("coll")
function Collection:new(children, key)
    local o = Obj.new(self)
    o.children = children
    o.key = key
    return o
end
function Collection:visit1(visitor)
    for _,c in ipairs(self.children) do
        visitor(c)
    end
end

---@class Seq : Collection
local Seq = Collection:sub("seq")

---@class Seq : Collection
local Alt = Collection:sub("alt")

---@class Blank : Obj
local Blank = Obj:sub("blank")
function Blank:visit1(_visitor)
end
function Blank:minimal()
    return ""
end

---@class Repeat : Obj
---@field child Obj
local Repeat = Obj:sub("rep")
function Repeat:new(child, key)
    local o = Repeat:super()
    o.child = child
    o.key = key
    return o
end
function Repeat:visit1(visitor)
    visitor(self.child)
end
function Repeat:__tostring()
    return '(' .. tostring(self.child) .. ")*"
end

---@class Repeat1 : Repeat
local Repeat1 = Repeat:sub("rep1")
function Repeat1:__tostring()
    return '(' .. tostring(self.child) .. ")+"
end

---@class Str : Obj
local Str = Obj:sub("str")
function Str:new(str, key)
    local o = self:super()
    o.str = str
    o.key = key
    return o
end
function Str:visit1(visitor)
end

---@class Pat : Obj
local Pat = Obj:sub("pat")
function Pat:new(regex, key)
    local o = self:super()
    o.str = regex
    o.key = key
    return o
end
function Pat:visit1(visitor)
end


local Alias = Obj:sub("alias")
function Alias:new(name, named, child, key)
    local o = self:super()
    o.name = name
    o.child = child
    o.named = named
    o.key = key
    return o
end
function Alias:visit1(visitor)
    visitor(self.child)
end
function Alias:__tostring()
    return self.name .. "@" .. tostring(self.child)
end

local Field = Obj:sub("field")
function Field:new(field, child, key)
    local o = self:super()
    o.field = field
    o.child = child
    o.key = key
    return o
end
function Field:__tostring()
    return self.field .. ":" .. tostring(self.child)
end
function Field:visit1(visitor)
    visitor(self.child)
end


local Ref = Obj:sub("ref")
function Ref:new(name, key)
    local o = self:super()
    o.name = name
    o.key = key
    return o
end
function Ref:__tostring()
    return '&'..self.name
end
function Ref:visit1(visitor)
end



local parse_array
local function parse(meta, json, key)
    local res
    if json.type == "SEQ" then
        res = Seq:new(parse_array(meta, json.members), key)
    elseif json.type == "CHOICE" then
        res = Alt:new(parse_array(meta, json.members), key)
    elseif json.type == "BLANK" then
        res = Blank:new()
    elseif json.type == "REPEAT" then
        res = Repeat:new(parse(meta, json.content), key)
    elseif json.type == "REPEAT1" then
        res = Repeat1:new(parse(meta, json.content), key)
    elseif json.type == "STRING" then
        res = Str:new(json.value, key)
    elseif json.type == "PATTERN" then
        res = Pat:new(json.value, key)
    elseif json.type == "ALIAS" then
        res = Alias:new(json.value, json.named, parse(meta, json.content), key)
    elseif json.type == "FIELD" then
        res = Field:new(json.name, parse(meta, json.content), key)
    elseif json.type == "SYMBOL" then
        res = Ref:new(json.name, key)
    elseif json.type == "PREC" then
        res = Prec:new(parse(meta, json.content), json.value, nil, key)
    elseif json.type == "PREC_LEFT" then
        res = Prec:new(parse(meta, json.content), json.value, 'left', key)
    elseif json.type == "PREC_RIGHT" then
        res = Prec:new(parse(meta, json.content), json.value, 'right', key)
    -- TODO: This means no whitespace before token
    elseif json.type == "IMMEDIATE_TOKEN" then
        res = parse(meta, json.content, key)
    -- TODO: This means treat the 'content' as a singlet token
    elseif json.type == "TOKEN" then
        res = parse(meta, json.content, key)
    else
        error("unknown type: " .. vim.inspect(json))
    end
    res.key = key
    res.meta = meta[key] or {}

    return res
end
parse_array = function(meta, json)
    local result = {}
    for _, v in ipairs(json) do
        table.insert(result, parse(meta, v))
    end
    return result
end

local function script_path()
    local str = debug.getinfo(2, "S").source:sub(2)
    return str:match("(.*/)")
end
local ParseInfo = {
    lua= {
        statement= { forkPoint= true },
        expression= { forkPoint= true },
        identifier= { match= true },
    }
  }
local Parsed = {}
local function parseFile(lang, useCache)
    if useCache and Parsed[lang] then
        return Parsed[lang]
    end
    local file = io.open(script_path() .. '../../grammars/' .. lang .. '/grammar.json', "r")
    if not file then
        error("file not found: " .. lang)
    end
    local content = file:read("*a")
    file:close()
    local out = {}
    local meta = ParseInfo[lang] or {}
    for key, value in pairs(vim.json.decode(content).rules) do
        out[key] = parse(meta, value, key)
    end
    Parsed[lang] = out
    return out
end


return {
    parse = parseFile,
    Seq = Seq,
    Alt = Alt,
    Blank = Blank,
    Repeat = Repeat,
    Repeat1 = Repeat1,
    Str = Str,
    Pat = Pat,
    Prec = Prec,
    Alias = Alias,
    Field = Field,
    Ref = Ref,
    Obj = Obj,
    ParseInfo = ParseInfo
}
