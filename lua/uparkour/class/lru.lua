--[[
	作者:豆小姐
	2025 12 09
]]--


local LRUCache = {}
local LRUOrder = {}
local LRUCapacity = 30

local function _lruTouch(key)
    for i = #LRUOrder, 1, -1 do
        if LRUOrder[i] == key then
            table.remove(LRUOrder, i)
            break
        end
    end
    table.insert(LRUOrder, 1, key)
end

function UPar.LRUInit(capacity)
    LRUCache = {}
    LRUOrder = {}
    if capacity then
        LRUCapacity = math.max(tonumber(capacity) or 30, 1)
    end
end

function UPar.LRUSetCapacity(capacity)
    LRUCapacity = math.max(tonumber(capacity) or LRUCapacity, 1)
    local excess = #LRUOrder - LRUCapacity
    if excess > 0 then
        for i = 1, excess do
            LRUCache[table.remove(LRUOrder)] = nil
        end
    end
end

local function LRUSet(key, value)
    if not key then error("LRUSet: key cannot be nil") end
    if LRUCache[key] then
        LRUCache[key] = value
        _lruTouch(key)
        return
    end
    if #LRUOrder >= LRUCapacity then
        LRUCache[table.remove(LRUOrder)] = nil
    end
    LRUCache[key] = value
    table.insert(LRUOrder, 1, key)
end

local function LRUGet(key)
    local val = LRUCache[key]
    if val then _lruTouch(key) end
    return val
end

UPar.LRUSet = LRUSet
UPar.LRUGet = LRUGet

function UPar.LRUGetOrSet(key, default)
    if not key then error("LRUGetOrSet: key cannot be nil") end

    local val = LRUGet(key)
    if val ~= nil then
        return val
    end

    LRUSet(key, default)
    return default
end

function UPar.LRUDelete(key)
    if not LRUCache[key] then return false end
    LRUCache[key] = nil
    for i = #LRUOrder, 1, -1 do
        if LRUOrder[i] == key then
            table.remove(LRUOrder, i)
            break
        end
    end
    return true
end

function UPar.LRUClear()
    LRUCache = {}
    LRUOrder = {}
end

function UPar.LRUGetSize()
    return #LRUOrder
end

function UPar.LRUGetCapacity()
    return LRUCapacity
end