--[[
	作者:白狼
	2025 11 5
--]]

UPar.ACT_EVENT_FLAG = {
	START_FLAG = 1,
	CLEAR_FLAG = 2,
	INTERRUPT_FLAG = 3,
	RHYTHM_FLAG = 4,
	END_FLAG = 5,
}

UPar.MAX_ACT_EVENT = 50

local SeqHookRun = UPar.SeqHookRun
local SeqHookRunAllSafe = UPar.SeqHookRunAllSafe
local emptyTable = UPar.emptyTable
local ActInstances = UPar.ActInstances
local EffInstances = UPar.EffInstances

local START_FLAG = UPar.ACT_EVENT_FLAG.START_FLAG
local CLEAR_FLAG = UPar.ACT_EVENT_FLAG.CLEAR_FLAG
local INTERRUPT_FLAG = UPar.ACT_EVENT_FLAG.INTERRUPT_FLAG
local RHYTHM_FLAG = UPar.ACT_EVENT_FLAG.RHYTHM_FLAG
local END_FLAG = UPar.ACT_EVENT_FLAG.END_FLAG




local function ActStart(ply, action, checkResult)
	action:Start(ply, checkResult)

	local effect = action:GetUsingEffect(ply)
	if effect then effect:Start(ply, checkResult) end
end

local function ActClear(ply, playing, playingData, mv, cmd, interruptSource)
	playing:Clear(ply, playingData, mv, cmd, interruptSource)

	local effect = playing:GetUsingEffect(ply)
	if effect then effect:Clear(ply, playingData, interruptSource) end
end

local function ActEffRhythmChange(ply, action, customData, silent)
	local actName = action.Name

	local rhythmEvent = {RHYTHM_FLAG, actName, customData}
	if SERVER then
		net.Start('UParCallClientAction')
			net.WriteTable(rhythmEvent)
			net.WriteTable({END_FLAG})
		net.Send(ply)
	end

	local effect = action:GetUsingEffect(ply)
	if effect then effect:Rhythm(ply, customData) end

	if not silent then
		SeqHookRunAllSafe('UParActEvent', ply, {rhythmEvent})
	end
end

UPar.ActStart = ActStart
UPar.ActClear = ActClear
UPar.ActEffRhythmChange = ActEffRhythmChange

UPar.CallAct = function(actName, methodName, ...)
    local action = ActInstances[actName]
    if not action then
		print(string.format('not found act named "%s"', actName))
		return
    end

    local method = action[methodName]
    if not isfunction(method) then
		print(string.format('not found method "%s" in act "%s"', methodName, actName))
		return
    end

	return method(action, ...)
end

UPar.GetActKV = function(actName, key)
    local action = ActInstances[actName]
    if not action then
		print(string.format('not found act named "%s"', actName))
		return
    end

	return action[key]
end

UPar.CallEff = function(actName, effName, methodName, ...)
    local effects = EffInstances[actName]
    if not effects then
		print(string.format('not found effs in act "%s"', actName))
		return
    end

    local effect = effects[effName]
    if not effect then
		print(string.format('not found eff "%s" in act "%s"', effName, actName))
		return
    end

    local method = effect[methodName]
    if not isfunction(method) then
		print(string.format('not found method "%s" in eff "%s" of act "%s"', methodName, effName, actName))
		return
    end

	return method(effect, ...)
end

UPar.GetEffKV = function(actName, effName, key)
    local effects = EffInstances[actName]
    if not effects then
		print(string.format('not found effs in act "%s"', actName))
		return
    end

    local effect = effects[effName]
    if not effect then
		print(string.format('not found eff "%s" in act "%s"', effName, actName))
		return
    end

	return effect[key]
end

UPar.CallPlyUsingEff = function(actName, methodName, ply, ...)
	local action = ActInstances[actName]
    if not action then
		print(string.format('not found act named "%s"', actName))
		return
    end

    local effect = action:GetUsingEffect(ply)
    if not effect then
		print(string.format('not found eff "USING" in act "%s" for ply "%s"', actName, ply))
		return
    end

    local method = effect[methodName]
    if not isfunction(method) then
		print(string.format('not found method "%s" in eff "USING" act "%s" for ply "%s"', methodName, actName, ply))
		return
    end

	return method(effect, ...)
end

UPar.GetPlyUsingEffKV = function(actName, key, ply)
	local action = ActInstances[actName]
    if not action then
		print(string.format('not found act named "%s"', actName))
		return
    end
	
    local effect = action:GetUsingEffect(ply)
    if not effect then
		print(string.format('not found eff "USING" in act "%s" for ply "%s"', actName, ply))
		return
    end

	return effect[key]
end


if SERVER then
    util.AddNetworkString('UParCallClientAction')
	util.AddNetworkString('UParStart')

	local function Trigger(ply, actName, checkResult, ...)
		-- 并不支持在 Start 或 Clear 中动态改变轨道, 因为他们在 net 上下文中
        if not IsValid(ply) or not ply:IsPlayer() then
			print(string.format('Invalid ply "%s"', ply))
			return
        end

		local action = ActInstances[actName]
		if not action then
			print(string.format('not found act named "%s"', actName))
			return
		end

		if action:GetDisabled() then
			return
		end

		local trackId = action.TrackId
		local playing, playingData, playingName = unpack(ply.uptracks[trackId] or emptyTable)
	
		if playing and not (SeqHookRun('UParActAllowInterrupt_' .. playingName, ply, playingData, actName)
			or SeqHookRun('UParActAllowInterrupt', playingName, ply, playingData, actName)) then
			return
		end

		checkResult = checkResult or action:Check(ply, ...)
		if not istable(checkResult) then
			return
		elseif SeqHookRun('UParActPreStartValidate_' .. actName, ply, checkResult) 
		or SeqHookRun('UParActPreStartValidate', actName, ply, checkResult) then
			return
		end

		local eventData = {}

		net.Start('UParCallClientAction')
		if playing then
			ply.uptracks[trackId] = nil

			local clearEvent = {CLEAR_FLAG, playing.Name, playingData, actName}
			net.WriteTable(clearEvent)
			table.insert(eventData, clearEvent)

			local succ, err = pcall(ActClear, ply, playing, playingData, nil, nil, actName)
			if not succ then ErrorNoHaltWithStack(err) end
		end

		local startEvent = {START_FLAG, actName, checkResult}
		net.WriteTable(startEvent)
		table.insert(eventData, startEvent)
		
		local succ, err = pcall(ActStart, ply, action, checkResult)
		if not succ then
			ErrorNoHaltWithStack(err)
			local clearEvent = {CLEAR_FLAG, actName, checkResult, true}
			net.WriteTable(clearEvent)
			table.insert(eventData, clearEvent)
		end

		net.WriteTable({END_FLAG})
        net.Send(ply)

		ply.uptracks[trackId] = {action, checkResult, actName}

		SeqHookRunAllSafe('UParActEvent', ply, eventData)

		return checkResult
	end

	local function RemoveTracks(ply, removeData, mv, cmd)
		if #removeData < 1 then
			return
		end

		if #removeData > UPar.MAX_ACT_EVENT then
			ErrorNoHaltWithStack(string.format('[UPar]: Warning: RemoveTracks: removeData count is %d, max is %d', #removeData, UPar.MAX_ACT_EVENT))
			return
		end

		for i = #removeData, 1, -1 do
			local trackId, trackContent, reason = unpack(removeData[i])
			if trackContent ~= ply.uptracks[trackId] then
				print(string.format('[UPar]: track "%s" content changed in other place', trackId))
				table.remove(removeData, i)
			else
				ply.uptracks[trackId] = nil
			end
		end

		for _, v in ipairs(removeData) do
			local trackId, trackContent, reason = unpack(v)

			if ply.uptracks[trackId] ~= nil then
				print(string.format('[UPar]: Warning: track "%s" content changed in other place', trackId))
				continue
			end

			local playing, playingData, _ = unpack(trackContent or emptyTable)

			if not playing then
				continue
			end

			local succ, err = pcall(ActClear, ply, playing, playingData or emptyTable, mv, cmd, reason or false)
			if not succ then ErrorNoHaltWithStack(err) end
		end

		local eventData = {}

		net.Start('UParCallClientAction')
		for _, v in ipairs(removeData) do
			local trackId, trackContent, reason = unpack(v)

			if ply.uptracks[trackId] ~= nil then
				print(string.format('[UPar]: Warning: track "%s" content changed in other place', trackId))
				continue
			end

			local _, playingData, playingName = unpack(trackContent or emptyTable)

			if not playingName then
				continue
			end
			local clearEvent = {CLEAR_FLAG, playingName, playingData or emptyTable, reason or false}
			net.WriteTable(clearEvent)
			table.insert(eventData, clearEvent)
		end
		net.WriteTable({END_FLAG})
		net.Send(ply)

		SeqHookRunAllSafe('UParActEvent', ply, eventData)
	end

	local function ForceEndTarget(ply, target)
		ply.uptracks = istable(ply.uptracks) and ply.uptracks or {}
		target = istable(target) and target or emptyTable
		local removeData = {}
		for _, trackId in pairs(target) do
			local trackContent = ply.uptracks[trackId]
			if not trackContent then continue end
			table.insert(removeData, {trackId, trackContent, true})
		end

		RemoveTracks(ply, removeData, nil, nil)
	end

	local function ForceEndAllExcept(ply, filter)
		ply.uptracks = istable(ply.uptracks) and ply.uptracks or {}
		filter = istable(filter) and filter or emptyTable
		local removeData = {}
		for trackId, trackContent in pairs(ply.uptracks) do
			if filter[trackId] then continue end
			table.insert(removeData, {trackId, trackContent, true})
		end

		RemoveTracks(ply, removeData, nil, nil)
	end

	UPar.ForceEndTarget = ForceEndTarget
	UPar.ForceEndAllExcept = ForceEndAllExcept
	UPar.RemoveTracks = RemoveTracks
	UPar.Trigger = Trigger

	net.Receive('UParStart', function(len, ply)
		local actName = net.ReadString()
		local checkResult = net.ReadTable()

		local action = ActInstances[actName]
		if not action then
			print(string.format('not found act named "%s"', actName))
			return
		end

		if not action:OnValCltPredRes(ply, checkResult) then
			print(string.format('act named "%s" OnValCltPredRes failed, %s', actName, ply))
			return
		end

		Trigger(ply, actName, checkResult)
	end)

	hook.Add('SetupMove', 'upar.think', function(ply, mv, cmd)
		local removeData = {}
		for trackId, trackContent in pairs(ply.uptracks or emptyTable) do
			local action, checkResult, actName = unpack(trackContent or emptyTable)

			if not action then
				continue
			end

			local succ, result = pcall(action.Think, action, ply, checkResult, mv, cmd)
			if not succ then
				ErrorNoHaltWithStack(result)
				table.insert(removeData, {trackId, trackContent, true})
				break
			elseif result then
				table.insert(removeData, {trackId, trackContent, false})
			end
		end

		RemoveTracks(ply, removeData, mv, cmd)
	end)

	hook.Add('PlayerInitialSpawn', 'upar.init.tracks', function(ply)
		ply.uptracks = {}
	end)

	hook.Add('PlayerSpawn', 'upar.clear', ForceEndAllExcept)
	hook.Add('PlayerDeath', 'upar.clear', ForceEndAllExcept)
	hook.Add('PlayerSilentDeath', 'upar.clear', ForceEndAllExcept)
elseif CLIENT then
	UPar.Trigger = function(ply, actName, checkResult, ...)
        if not IsValid(ply) or not ply:IsPlayer() then
			print(string.format('Invalid ply "%s"', ply))
			return
        end

		local action = ActInstances[actName]
		if not action then
			print(string.format('not found act named "%s"', actName))
			return
		end

		if action:GetDisabled() then
			return
		end
		
		checkResult = checkResult or action:Check(ply, ...)
		if not istable(checkResult) then
			return
		elseif SeqHookRun('UParActPreStartValidate_' .. actName, ply, checkResult) 
		or SeqHookRun('UParActPreStartValidate', actName, ply, checkResult) then
			return
		end

		net.Start('UParStart')
			net.WriteString(actName)
			net.WriteTable(checkResult)
		net.SendToServer()

		return checkResult
	end

	local MoveControl = {
		enable = false,
		ClearMovement = false,
		RemoveKeys = 0,
		AddKeys = 0,
	}
	
	hook.Add('CreateMove', 'upar.move.control', function(cmd)
		if not MoveControl.enable then 
			return 
		end

		if MoveControl.ClearMovement then
			cmd:ClearMovement()
		end

		local RemoveKeys = MoveControl.RemoveKeys
		if isnumber(RemoveKeys) and RemoveKeys ~= 0 then
			cmd:RemoveKey(RemoveKeys)
		end

		local AddKeys = MoveControl.AddKeys
		if isnumber(AddKeys) and AddKeys ~= 0 then
			cmd:AddKey(AddKeys)
		end
	end)

	local function SetMoveControl(enable, clearMovement, removeKeys, addKeys, timeout)
		MoveControl.enable = enable
		MoveControl.ClearMovement = clearMovement
		MoveControl.RemoveKeys = isnumber(removeKeys) and removeKeys or 0
		MoveControl.AddKeys = isnumber(addKeys) and addKeys or 0

		if enable then
			if isnumber(timeout) then
				timer.Create('UParMoveControl', math.abs(timeout), 1, function()
					print('MoveControl timeout')
					SetMoveControl(false, false, 0, 0)
				end)
			end
		else
			timer.Remove('UParMoveControl')
		end
	end

	UPar.MoveControl = MoveControl
	UPar.SetMoveControl = SetMoveControl

	local ACT_EVENT_FLAG_FLIP = table.Flip(UPar.ACT_EVENT_FLAG)

    net.Receive('UParCallClientAction', function()
		local ply = LocalPlayer()

		local eventData = {}

		for i = 1, UPar.MAX_ACT_EVENT do
			local batch = net.ReadTable()
			local eventFlag, actName, data, interruptSource = unpack(batch)
			if eventFlag == END_FLAG then
				print(string.format('[UPar]: cl_act: end flag %d', eventFlag))
				break
			end

			if not ACT_EVENT_FLAG_FLIP[eventFlag] then
				print(string.format('[UPar]: cl_act: unknown event flag %d', eventFlag))
				continue
			end

			table.insert(eventData, batch)

			local action = ActInstances[actName]

			if not action then
				print(string.format('[UPar]: cl_act: act named %s is not found', actName))
				continue
			end

			if eventFlag == START_FLAG then
				local succ, err = pcall(ActStart, ply, action, data)
				if not succ then
					ErrorNoHaltWithStack(err)
					succ, err = pcall(ActClear, ply, action, data, nil, nil, true)
					if not succ then ErrorNoHaltWithStack(err) end
				end
			elseif eventFlag == CLEAR_FLAG then
				local succ, err = pcall(ActClear, ply, action, data, nil, nil, interruptSource or false)
				if not succ then ErrorNoHaltWithStack(err) end
			elseif eventFlag == RHYTHM_FLAG then
				local succ, err = pcall(ActEffRhythmChange, ply, action, data, true)
				if not succ then ErrorNoHaltWithStack(err) end
			end
		end

		SeqHookRunAllSafe('UParActEvent', ply, eventData)
    end)
end