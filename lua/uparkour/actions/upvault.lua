--[[
	作者:白狼
	2025 12 20
]]--

-- ==================== 翻越 ===============
-- 实际上这个动作并不会被控制器触发, 它的作用仅仅是特效容器以及实现移动计算

local unitzvec = UPar.unitzvec
local Hermite3 = UPar.Hermite3

local upvault = UPAction:Register('upvault', {
	AAAACreat = '白狼',
	AAADesc = '#upvault.desc',
	icon = 'upgui/uparkour.jpg',
	label = '#upvault'
})

upvault.Check = UPar.emptyfunc

function upvault:Think(ply, data, mv, cmd)
	local startpos = data.startpos
	local endpos = data.endpos
	local startspeed = data.startspeed
	local endspeed = data.endspeed
	local duration = data.duration
	local starttime = data.starttime

	local speed_max = math.abs(math.max(startspeed, endspeed, 0.001))
	local dt = CurTime() - starttime
	local result = Hermite3(dt / duration, startspeed / speed_max, endspeed / speed_max)
	local endflag = dt > duration or result >= 1

	local curpos = endflag and endpos or LerpVector(result, startpos, endpos) + (-100 / duration * dt * dt + 100 * dt) * unitzvec

	mv:SetOrigin(curpos)

	return endflag
end