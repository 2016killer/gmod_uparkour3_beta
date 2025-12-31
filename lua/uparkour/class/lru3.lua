--[[
	作者:豆小姐
	2025 12 10
]]--


local LRU3Cache = {}
local LRU3Order = {}
local LRU3Capacity = 30

local function _lru3Touch(key)
    for i = #LRU3Order, 1, -1 do
        if LRU3Order[i] == key then
            table.remove(LRU3Order, i)
            break
        end
    end
    table.insert(LRU3Order, 1, key)
end

function UPar.LRU3Init(capacity)
    LRU3Cache = {}
    LRU3Order = {}
    if capacity then
        LRU3Capacity = math.max(tonumber(capacity) or 30, 1)
    end
end

function UPar.LRU3SetCapacity(capacity)
    LRU3Capacity = math.max(tonumber(capacity) or LRU3Capacity, 1)
    local excess = #LRU3Order - LRU3Capacity
    if excess > 0 then
        for i = 1, excess do
            LRU3Cache[table.remove(LRU3Order)] = nil
        end
    end
end

local function LRU3Set(key, value)
    if not key then error("LRU3Set: key cannot be nil") end
    if LRU3Cache[key] then
        LRU3Cache[key] = value
        _lru3Touch(key)
        return
    end
    if #LRU3Order >= LRU3Capacity then
        LRU3Cache[table.remove(LRU3Order)] = nil
    end
    LRU3Cache[key] = value
    table.insert(LRU3Order, 1, key)
end

local function LRU3Get(key)
    local val = LRU3Cache[key]
    if val then _lru3Touch(key) end
    return val
end

UPar.LRU3Set = LRU3Set
UPar.LRU3Get = LRU3Get

function UPar.LRU3GetOrSet(key, default)
    if not key then error("LRU3GetOrSet: key cannot be nil") end

    local val = LRU3Get(key)
    if val ~= nil then
        return val
    end

    LRU3Set(key, default)
    return default
end

function UPar.LRU3Delete(key)
    if not LRU3Cache[key] then return false end
    LRU3Cache[key] = nil
    for i = #LRU3Order, 1, -1 do
        if LRU3Order[i] == key then
            table.remove(LRU3Order, i)
            break
        end
    end
    return true
end

function UPar.LRU3Clear()
    LRU3Cache = {}
    LRU3Order = {}
end

function UPar.LRU3GetSize()
    return #LRU3Order
end

function UPar.LRU3GetCapacity()
    return LRU3Capacity
end