--[[
	作者:豆小姐
	2025 12 10
]]--



local LRU2Cache = {}
local LRU2Order = {}
local LRU2Capacity = 30

local function _lru2Touch(key)
    for i = #LRU2Order, 1, -1 do
        if LRU2Order[i] == key then
            table.remove(LRU2Order, i)
            break
        end
    end
    table.insert(LRU2Order, 1, key)
end

function UPar.LRU2Init(capacity)
    LRU2Cache = {}
    LRU2Order = {}
    if capacity then
        LRU2Capacity = math.max(tonumber(capacity) or 30, 1)
    end
end

function UPar.LRU2SetCapacity(capacity)
    LRU2Capacity = math.max(tonumber(capacity) or LRU2Capacity, 1)
    local excess = #LRU2Order - LRU2Capacity
    if excess > 0 then
        for i = 1, excess do
            LRU2Cache[table.remove(LRU2Order)] = nil
        end
    end
end

local function LRU2Set(key, value)
    if not key then error("LRU2Set: key cannot be nil") end
    if LRU2Cache[key] then
        LRU2Cache[key] = value
        _lru2Touch(key)
        return
    end
    if #LRU2Order >= LRU2Capacity then
        LRU2Cache[table.remove(LRU2Order)] = nil
    end
    LRU2Cache[key] = value
    table.insert(LRU2Order, 1, key)
end

local function LRU2Get(key)
    local val = LRU2Cache[key]
    if val then _lru2Touch(key) end
    return val
end

UPar.LRU2Set = LRU2Set
UPar.LRU2Get = LRU2Get

function UPar.LRU2GetOrSet(key, default)
    if not key then error("LRU2GetOrSet: key cannot be nil") end

    local val = LRU2Get(key)
    if val ~= nil then
        return val
    end

    LRU2Set(key, default)
    return default
end

function UPar.LRU2Delete(key)
    if not LRU2Cache[key] then return false end
    LRU2Cache[key] = nil
    for i = #LRU2Order, 1, -1 do
        if LRU2Order[i] == key then
            table.remove(LRU2Order, i)
            break
        end
    end
    return true
end

function UPar.LRU2Clear()
    LRU2Cache = {}
    LRU2Order = {}
end

function UPar.LRU2GetSize()
    return #LRU2Order
end

function UPar.LRU2GetCapacity()
    return LRU2Capacity
end