--[[
	作者:白狼
	2025 12 20
	豆包改造:支持自定义帧循环钩子，默认Think，兼容原有逻辑
	调整说明：保留固定钩子标识、break逻辑、原有removeCurrentHookFlag逻辑
--]]
UPar.FrameLoop = UPar.FrameLoop or {}
local FrameLoop = UPar.FrameLoop

-- 存储每个钩子的运行状态：hookStatus[hookName] = { startTime = number }
local hookStatus = {}

local FRAME_HOOK_IDENTITY = 'upar.frameLoop' -- 固定标识，支持不同event批量删除
local DEFAULT_HOOK_NAME = 'Think' -- 默认帧循环钩子
local POP_HOOK = 'UParPopFrameLoop'
local PUSH_HOOK = 'UParPushFrameLoop'
local PAUSE_HOOK = 'UParPauseFrameLoop'
local END_TIME_CHANGED_HOOK = 'UParFrameLoopEndTimeChanged'
local RESUME_HOOK = 'UParResumeFrameLoop'

-- 【保留你的设计】：钩子回调函数，使用 break 避免帧循环重写导致校验失效
local function FrameCall(hookName)
	local hookState = hookStatus[hookName]
	if not hookState then 
		print(string.format('[UPar.FrameLoop]: warning: hookState "%s" not found', hookName))
		hook.Remove(hookName, FRAME_HOOK_IDENTITY)
		return 
	end

	local removeCurrentHookFlag = true
	local curTime = CurTime()

	local dt = curTime - hookState.startTime
	hookState.startTime = curTime
	
	local removeIdentities = {}
	
	for identity, data in pairs(FrameLoop) do
		if data.hn ~= hookName or data.pt then 
			continue
		end

		removeCurrentHookFlag = false

		local iterator, edtime, add = data.f, data.et, data.add
		local succ, result = pcall(iterator, dt, curTime, add)
		
		if not succ then
			ErrorNoHaltWithStack(result)
			table.insert(removeIdentities, {identity, data, 'ERROR'})
			break -- 保留break：防止错误扩散及帧循环重写问题
		elseif result then
			table.insert(removeIdentities, {identity, data, nil})
		elseif curTime > edtime then
			table.insert(removeIdentities, {identity, data, 'TIMEOUT'})
		end
	end

	-- 多次遍历防止交叉感染，先校验帧循环数据是否未被篡改
	for i = #removeIdentities, 1, -1 do
		local identity, data, reason = unpack(removeIdentities[i])
		if FrameLoop[identity] ~= data then
			print(string.format('[UPar.FrameLoop]: warning: iterator "%s" changed in other', identity))
			table.remove(removeIdentities, i)
			removeCurrentHookFlag = false
		else
			FrameLoop[identity] = nil
		end
	end

	for _, v in ipairs(removeIdentities) do
		local identity, data, reason = unpack(v)

		if FrameLoop[identity] ~= nil then
			print(string.format('[UPar.FrameLoop]: warning: iterator "%s" changed in other', identity))
			removeCurrentHookFlag = false
			continue
		end

		if isfunction(data.clear) then
			local succ, result = pcall(data.clear, identity, curTime, data.add, reason)
			if not succ then ErrorNoHaltWithStack(result) end
		end
	end

	for _, v in ipairs(removeIdentities) do
		local identity, data, reason = unpack(v)

		if FrameLoop[identity] ~= nil then
			print(string.format('[UPar.FrameLoop]: warning: iterator "%s" changed in other', identity))
			removeCurrentHookFlag = false
			continue
		end

		local succ, result = pcall(hook.Run, POP_HOOK, identity, curTime, data.add, reason) 
		if not succ then ErrorNoHaltWithStack(result) end
		data.add = nil
	end

	if removeCurrentHookFlag then
		hook.Remove(hookName, FRAME_HOOK_IDENTITY)
		hookStatus[hookName] = nil
	end
end

local function __Internal_StartFrameLoop(hookName)
	local hookState = hookStatus[hookName]
	if not hookState then
		hookState = {startTime = CurTime()}
		hookStatus[hookName] = hookState
	end
	hook.Add(hookName, FRAME_HOOK_IDENTITY, function() FrameCall(hookName) end)
end

UPar.PushFrameLoop = function(identity, iterator, addition, timeout, clear, hookName)
	assert(isfunction(iterator), 'iterator must be a function.')
	assert(identity ~= nil, 'identity must be a valid value.')
	assert(isnumber(timeout), 'timeout must be a number.')
	assert(isstring(hookName) or hookName == nil, 'hookName must be a string or nil.')
	assert(isfunction(clear) or clear == nil, 'clear must be a function or nil.')

	-- 默认 Think 帧循环
	hookName = hookName or DEFAULT_HOOK_NAME
	if timeout <= 0 then 
		print(string.format('[UPar.PushFrameLoop]: warning: iterator "%s" timeout <= 0!', identity))
		return false
	end

	local old = FrameLoop[identity]
	if old then hook.Run(POP_HOOK, identity, CurTime(), old.add, 'OVERRIDE') end

	local endtime = timeout + CurTime()
	addition = istable(addition) and addition or {}
	hook.Run(PUSH_HOOK, identity, endtime, addition)

	FrameLoop[identity] = {
		f = iterator, 
		et = endtime, 
		add = addition, 
		clear = clear,
		hn = hookName
	}
	
	__Internal_StartFrameLoop(hookName)
	
	return true
end

UPar.PopFrameLoop = function(identity, silent)
	assert(identity ~= nil, 'identity must be a valid value.')

	local frameData = FrameLoop[identity]
	FrameLoop[identity] = nil

	if not frameData then
		return false
	end

	if isfunction(frameData.clear) then
		local succ, result = pcall(frameData.clear, identity, CurTime(), frameData.add, 'MANUAL')
		if not succ then ErrorNoHaltWithStack(result) end
	end

	if not silent then
		hook.Run(POP_HOOK, identity, CurTime(), frameData.add, 'MANUAL')
	end

	frameData.add = nil
	
	return true
end

UPar.GetFrameLoop = function(identity)
	assert(identity ~= nil, 'identity must be a valid value.')
	return FrameLoop[identity]
end

UPar.IsFrameLoopExist = function(identity)
	assert(identity ~= nil, 'identity must be a valid value.')
	return FrameLoop[identity] ~= nil
end

UPar.PauseFrameLoop = function(identity, silent)
	assert(identity ~= nil, 'identity must be a valid value.')
	local frameData = FrameLoop[identity]
	if not frameData then
		return false
	end
	
	local pauseTime = CurTime()
	frameData.pt = pauseTime

	if not silent then
		hook.Run(PAUSE_HOOK, identity, pauseTime, frameData.add)
	end
	
	return true
end

UPar.ResumeFrameLoop = function(identity, silent)
	assert(identity ~= nil, 'identity must be a valid value.')
	local frameData = FrameLoop[identity]
	if not frameData then
		return false
	end

	if not frameData.pt then
		return false
	else
		local resumeTime = CurTime()
		local pauseTime = frameData.pt
		frameData.pt = nil
		
		-- 更新超时时间：补偿暂停时长
		frameData.et = resumeTime + (frameData.et - pauseTime)
		
		if not silent then
			hook.Run(RESUME_HOOK, identity, resumeTime, frameData.add)
		end

		local hookName = frameData.hn
		__Internal_StartFrameLoop(hookName)
		
		return true
	end
end

UPar.SetFrameLoopAddiKV = function(identity, ...)
	assert(identity ~= nil, 'identity must be a valid value.')
	local frameData = FrameLoop[identity]
	if not frameData then
		return false
	end

	local target = frameData.add

	local total = select('#', ...)
	assert(total >= 2, 'at least 2 arguments required')

	local keyValue = {...}
	
	for i = 1, total - 2 do
		target = target[keyValue[i]]
		if not istable(target) then return false end
	end

	target[keyValue[total - 1]] = keyValue[total]
	return true
end

UPar.GetFrameLoopAddiKV = function(identity, ...)
	assert(identity ~= nil, 'identity must be a valid value.')
	local frameData = FrameLoop[identity]
	if not frameData then
		return nil
	end

	local target = frameData.add

	local total = select('#', ...)
	assert(total >= 2, 'at least 2 arguments required')

	local keyValue = {...}
	
	for i = 1, total - 2 do
		target = target[keyValue[i]]
		if not istable(target) then return nil end
	end

	return target[keyValue[total - 1]]
end

UPar.SetFrameLoopEndTime = function(identity, endTime, silent)
	assert(identity ~= nil, 'identity must be a valid value.')
	local frameData = FrameLoop[identity]
	if not frameData then
		return false
	end

	frameData.et = endTime
		
	if not silent then
		hook.Run(END_TIME_CHANGED_HOOK, identity, endTime, frameData.add)
	end

	return true
end

UPar.MergeFrameLoopAddiKV = function(identity, data)
	assert(identity ~= nil, 'identity must be a valid value.')
	assert(istable(data), 'data must be a table.')

	local frameData = FrameLoop[identity]
	if not frameData then
		return false
	end

	table.Merge(frameData.add, data)
	
	return true
end