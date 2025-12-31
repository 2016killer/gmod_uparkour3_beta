--[[
	作者:白狼
	2025 12 27
]]--

-- ====================  二段翻越-低 特效 ===============
local effect = UPEffect:Register('upvaultdl', 'default', {
	AAAACreat = '白狼',
	AAADesc = '#upvaultdl.defaulteff.desc',
})

function effect:Start(ply, data)
	local rhythm = istable(data) and data.rhythm or 1
	local actName = rhythm == 1 and 'uplowclimb' or 'upvault'
	return UPar.CallPlyUsingEff(actName, 'Start', ply, ply, data)
end

function effect:Rhythm(ply, _)
	return UPar.CallPlyUsingEff('upvault', 'Start', ply, ply, data)
end

effect.Clear = UPar.GenEffClear
