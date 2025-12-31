--[[
	作者:白狼
	2025 12 13
]]--

if not GetConVar('developer') or not GetConVar('developer'):GetBool() then return end
-- ==================== 生命周期测试 ===============

local action = UPAction:Register('test_lifecycle', {
	AAAACreat = '白狼', 
	AAADesc = '#upgui.dev.test.desc'
})

function action:Check(ply, ...)
	print(string.format('====== Check, TrackId: %s ======', self.TrackId))
	print('data:', ...)
	return {arg1 = 1}
end

function action:Start(ply, checkResult)
	print(string.format('====== Start, TrackId: %s ======', self.TrackId))
	print('checkResult:', checkResult)
	PrintTable(checkResult)
	checkResult.endtime = CurTime() + 2
	checkResult.rhythm = 0
end

function action:Think(ply, checkResult, mv, cmd)
	local curtime = CurTime()

	if curtime > checkResult.endtime - 0.5 and checkResult.rhythm == 0 then
		checkResult.rhythm = 1
		UPar.ActEffRhythmChange(ply, self, 1)
	elseif curtime > checkResult.endtime then
		print(string.format('====== Think Out, TrackId: %s ======', self.TrackId))
		print('checkResult:', checkResult)
		PrintTable(checkResult)
		return true
	end

	return false
end

function action:Clear(ply, checkResult, mv, cmd, interruptSource)
	print(string.format('====== Clear, TrackId: %s ======', self.TrackId))
	print('checkResult:', checkResult)
	PrintTable(checkResult)
	print('mv:', mv)
	print('cmd:', cmd)
	print('interruptSource:', interruptSource)
end

local action_t1 = UPAction:Register('test_lifecycle_t1', action, true)
action_t1.TrackId = 1