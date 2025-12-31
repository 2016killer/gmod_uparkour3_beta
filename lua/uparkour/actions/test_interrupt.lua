--[[
	作者:白狼
	2025 12 18
]]--

-- ==================== 测试其他面板 ===============
if not GetConVar('developer') or not GetConVar('developer'):GetBool() then return end

local action = UPAction:Register('test_interrupt', {invisible = true})
action.Check = function() return {} end
action.Start = UPar.emptyfunc
action.Think = function() return true end
action.Clear = UPar.emptyfunc

if SERVER then 
	UPar.SeqHookAdd('UParActAllowInterrupt_test_lifecycle', 'example.interrupt', function(ply, playingData, interruptSource)
		if interruptSource == 'test_interrupt' then
			return true
		end
	end)

	// UPar.SeqHookAdd('UParActAllowInterrupt', 'example.interrupt', function(playingName, ply, playingData, interruptSource)
	// 	if playingName == 'test_lifecycle' and interruptSource == 'test_interrupt' then
	// 		return true
	// 	end
	// end)

	-- 随机停止
	// UPar.SeqHookAdd('UParActPreStartValidate_test_lifecycle', 'example.prestart.validate', function(...)
	// 	return math.random() > 0.5
	// end)

	-- 随机停止所有
	// UPar.SeqHookAdd('UParActPreStartValidate', 'example.prestart.validate', function(...)
	// 	return math.random() > 0.5
	// end)
end

// UPar.SeqHookAdd('UParActEvent', 'network.debug', function(ply, event)
// 	local curtime = CurTime()
// 	print(string.format('-------------------%s----------------', curtime))
// 	PrintTable(event)
// 	print(string.format('-------------------%s----------------', curtime))
// end)