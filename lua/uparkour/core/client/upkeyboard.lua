--[[
	作者:白狼
	2025 12 22
--]]

UPKeyboard = UPKeyboard or {}
UPKeyboard.KEY_EVENT_FLAGS = {
    UNHANDLED = 0,
    HANDLED = 1,
    SKIPPED = 2
}

UPKeyboard.KeyState = UPKeyboard.KeyState or {}
UPKeyboard.KeySet = UPKeyboard.KeySet or {}

local FLAGS_UNHANDLED = UPKeyboard.KEY_EVENT_FLAGS.UNHANDLED
local FLAGS_HANDLED = UPKeyboard.KEY_EVENT_FLAGS.HANDLED
local FLAGS_SKIPPED = UPKeyboard.KEY_EVENT_FLAGS.SKIPPED

local KeyState = UPKeyboard.KeyState
local KeySet = UPKeyboard.KeySet
local SeqHookRunAllSafe = UPar.SeqHookRunAllSafe

local upkeycheck_interval = CreateClientConVar('upkeycheck_interval', '0.03', true, false, '')
local nextThinkTime = 0
local interval = upkeycheck_interval:GetFloat()
local ThinkLock = false
local THINK_HOOK_IDENTITY = 'upkeyboard.check'
local KEY_PRESS_HOOK_IDENTITY = 'upkeyboard.check'
local KEY_RELEASE_HOOK_IDENTITY = 'upkeyboard.check'

cvars.AddChangeCallback('upkeycheck_interval', function(name, old, new)
    local newVal = tonumber(new)
    if not newVal then return end
    interval = newVal
    nextThinkTime = RealTime()
end, 'default')

UPKeyboard.Register = function(flag, default, label)
    assert(isstring(flag), string.format('Invalid flag "%s" (not a string)', flag))
    assert(not string.find(flag, '[\\/:*?"<>|]'), string.format('Invalid flag "%s" (contains invalid filename characters)', flag))

    local cvName = 'upkey_' .. string.gsub(flag, '[\\/:*?"<>|]', '_')
    local cvar = CreateClientConVar(cvName, default, true, false, '')
    cvars.AddChangeCallback(cvName, function(name, old, new)
        if KeyState[flag] then
            SeqHookRunAllSafe('UParKeyRelease', {flag = FLAGS_UNHANDLED})     
        end
        KeyState[flag] = false
    end, 'default')


    KeySet[flag] = {
        label = isstring(label) and label or flag,
        cvar = cvar
    }

    hook.Run('UParRegisterKey', flag, label, default)
end

local function Check()
    local curTime = RealTime()
    if curTime < nextThinkTime then
        return
    end
    nextThinkTime = curTime + interval

    if vgui.GetKeyboardFocus() then 
        return 
    end

    local PressedSet = {}
    local ReleasedSet = {}
    for flag, data in pairs(KeySet) do
        local keys = util.JSONToTable(data.cvar:GetString())

        if istable(keys) then
            local pressAll = #keys > 0

            // local temp = {flag}
            for _, keycode in ipairs(keys) do
                if not isnumber(keycode) then continue end
                pressAll = pressAll and (input.IsKeyDown(keycode) or input.IsMouseDown(keycode))
         
                // table.insert(temp, input.GetKeyName(keycode))
                // table.insert(temp, tostring(input.IsKeyDown(keycode) or input.IsMouseDown(keycode)))
            end

            // print(table.concat(temp, ' '))

            if pressAll and not KeyState[flag] then
                PressedSet[flag] = FLAGS_UNHANDLED
            elseif not pressAll and KeyState[flag] then
                ReleasedSet[flag] = FLAGS_UNHANDLED
            end

            KeyState[flag] = pressAll
        end
    end

    if not table.IsEmpty(PressedSet) then
        SeqHookRunAllSafe('UParKeyPress', PressedSet)
    end

    if not table.IsEmpty(ReleasedSet) then
        SeqHookRunAllSafe('UParKeyRelease', ReleasedSet)
    end
end

hook.Add('Think', THINK_HOOK_IDENTITY, function()
    if ThinkLock then return end
    Check()
end)

hook.Add('KeyPress', KEY_PRESS_HOOK_IDENTITY, function(ply, key)
    if not game.SinglePlayer() and not IsFirstTimePredicted() then 
        return 
    end

    ThinkLock = true
    local succ, err = pcall(Check)
    if not succ then ErrorNoHaltWithStack(err) end
    ThinkLock = false
end)

hook.Add('KeyRelease', KEY_RELEASE_HOOK_IDENTITY, function(ply, key)
    if not game.SinglePlayer() and not IsFirstTimePredicted() then 
        return 
    end

    ThinkLock = true
    local succ, err = pcall(Check)
    if not succ then ErrorNoHaltWithStack(err) end
    ThinkLock = false
end)

UPKeyboard.ClearKeyState = function()
    KeyState = {}
    UPKeyboard.KeyState = KeyState
end