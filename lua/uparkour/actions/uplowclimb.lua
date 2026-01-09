--[[
	作者:白狼
	2025 12 20
]]--

-- ==================== 低爬 ===============
local XYNormal = UPar.XYNormal
local ObsDetector = UPar.ObsDetector
local ClimbDetector = UPar.ClimbDetector
local IsInSolid = UPar.IsInSolid
local unitzvec = UPar.unitzvec
local Hermite3 = UPar.Hermite3
local zerovec = UPar.zerovec

local uplowclimb = UPAction:Register('uplowclimb', {
	AAAACreat = '白狼',
	AAADesc = '#uplowclimb.desc',
	icon = 'upgui/uparkour.jpg',
	label = '#uplowclimb',
	defaultDisabled = false
})

uplowclimb:InitConVars({
	{
		name = 'upctrl_los_cos',
		default = '0.64',
		invisible = true
	},

	{label = '#uplowclimb.option.detector', widget = 'Label'},

	{
		name = 'uplc_ohlen_f',
		default = '0.67',
		widget = 'NumSlider',
		min = 0, max = 1, decimals = 2,
		help = true
	},

	{
		name = 'uplc_maxh_f',
		default = '0.85',
		widget = 'NumSlider',
		min = 0, max = 1, decimals = 2,
		help = true
	},

	{
		name = 'uplc_minh_f',
		default = '0.4',
		widget = 'NumSlider',
		min = 0, max = 1, decimals = 2
	},

	{label = '#uplowclimb.option.speed', widget = 'Label'},

	{
		name = 'uplc_refspeed_enable',
		default = '1',
		widget = 'CheckBox',
		help = true
	},

	{
		name = 'uplc_speed_f',
		default = '1 0.25 0.25',
		widget = 'UParVecEditor',
		min = 0, max = 2, decimals = 2, interval = 0.1,
		help = true
	}
})

function uplowclimb:Detector(ply, pos, dirNorm)
	pos = isvector(pos) and pos or ply:GetPos()
	dirNorm = isvector(dirNorm) and dirNorm or ply:EyeAngles():Forward()

	local convars = self.ConVars
	local obsTrace = ObsDetector(ply, pos, 
		dirNorm,
		convars.uplc_ohlen_f:GetFloat(), 
		convars.uplc_minh_f:GetFloat(),
		convars.uplc_maxh_f:GetFloat(),
		convars.upctrl_los_cos:GetFloat()
	)

	if not obsTrace then 
		return
	end

	local climbTrace = ClimbDetector(ply, obsTrace, 0.25)

    if not climbTrace then 
        return 
    end

	return obsTrace, climbTrace
end

function uplowclimb:GetMoveData(ply, obsTrace, climbTrace, refVel)
	if self.ConVars.uplc_refspeed_enable:GetBool() then 
		refVel = isvector(refVel) and refVel or ply:GetVelocity()
	else
		refVel = zerovec
	end

	local startpos = obsTrace.StartPos
	local endpos = climbTrace.HitPos + unitzvec
	local moveDir = (endpos - startpos):GetNormalized()
	local moveDis = (endpos - startpos):Dot(moveDir)

	local moveVec = ply:KeyDown(IN_SPEED)  
		and Vector(ply:GetJumpPower(), 0, ply:GetRunSpeed())
		or Vector(ply:GetJumpPower(), ply:GetWalkSpeed(), 0)

	local startspeed = math.max(
		math.abs(Vector(self.ConVars.uplc_speed_f:GetString()):Dot(moveVec)), 
		(moveDir):Dot(refVel),
		10
	)

	local moveDuration = moveDis * 2 / startspeed

	if moveDuration <= 0 then 
		print('[uplowclimb]: Warning: moveDuration <= 0')
		return
	end
	
	return {
		startpos = startpos,
		endpos = endpos,

		startspeed = startspeed,
		endspeed = 0,

		starttime = CurTime(),

		needduck = IsInSolid(ply, endpos, false),
		duration = moveDuration
	}
end

function uplowclimb:Check(ply, pos, dirNorm, refVel)
	if not isentity(ply) or not IsValid(ply) then
		print('[uplowclimb]: Warning: Invalid player')
		return
	end

	if ply:GetMoveType() ~= MOVETYPE_WALK or !ply:Alive() then 
		return
	end

	local obsTrace, climbTrace = self:Detector(ply, pos, dirNorm)
	if not obsTrace or not climbTrace then 
		return
	end

	return self:GetMoveData(ply, obsTrace, climbTrace, refVel)
end

function uplowclimb:Start(ply, data)
	if CLIENT then 
		local timeout = isnumber(data.duration) and data.duration * 2 or 0.5
		local needduck = data.needduck
		UPar.SetMoveControl(true, true, 
			needduck and IN_JUMP or bit.bor(IN_DUCK, IN_JUMP),
			needduck and IN_DUCK or 0, 
			timeout)
	end
	
	if ply:GetMoveType() ~= MOVETYPE_NOCLIP then 
		ply:SetMoveType(MOVETYPE_NOCLIP)
	end
end

uplowclimb.Think = UPar.UniformAccelMoveThink

function uplowclimb:Clear(ply, data, mv, cmd)
	if CLIENT then 
		UPar.SetMoveControl(false, false, 0, 0)
    end

	if ply:GetMoveType() == MOVETYPE_NOCLIP then 
		ply:SetMoveType(MOVETYPE_WALK)
	end
end

if CLIENT then
	UPar.SeqHookAdd('UParActCVarWidget_uplowclimb', 'default', function(cvCfg, panel)
		local cvName = cvCfg.name

		if cvName == 'uplc_ohlen_f' 
		or cvName == 'uplc_speed_f' 
		or cvName == 'uplc_minh_f' 
		or cvName == 'uplc_maxh_f' then
			local created = UPar.SeqHookRun('UParActCVarWidget', 'uplowclimb', cvCfg, panel)
			if not created then
				return
			end

			local predi = panel:ControlHelp('')
			local plyVelPhrase = language.GetPhrase('#upgui.PlyVel')
			predi.NEXT = 0
			predi.Think = function(self)
				if CurTime() < self.NEXT then return end

				self.NEXT = CurTime() + 0.5

				local value = nil
				local cvar = UPar.GetActKV('uplowclimb', 'ConVars')[cvName]
				if cvName == 'uplc_speed_f' then
					local ply = LocalPlayer()
					local cvarVal = Vector(cvar:GetString())
					local moveVec = Vector(ply:GetJumpPower(), ply:GetWalkSpeed(), 0)
					local moveVec2 = Vector(ply:GetJumpPower(), 0, ply:GetRunSpeed())
					local enableRefSpeed = UPar.GetActKV('uplowclimb', 'ConVars').uplc_refspeed_enable:GetBool()

					if enableRefSpeed then
						value = string.format('max(%s, %s) ~ 0,    max(%s, %s) ~ 0', 
							plyVelPhrase,
							math.Round(cvarVal:Dot(moveVec), 2),
							plyVelPhrase,
							math.Round(cvarVal:Dot(moveVec2), 2)
						)
					else
						value = string.format('%s ~ 0,    %s ~ 0', 
							math.Round(cvarVal:Dot(moveVec), 2),
							math.Round(cvarVal:Dot(moveVec2), 2)
						)
					end
				elseif cvName == 'uplc_minh_f' or cvName == 'uplc_maxh_f' or cvName == 'uplc_ohlen_f' then
					local min, max = LocalPlayer():GetCollisionBounds()
					local plyHeight = max[3] - min[3]
					value = math.Round(plyHeight * cvar:GetFloat(), 2)
				end

				self:SetText(string.format('%s: %s', 
					language.GetPhrase('#upgui.predi'), 
					value
				))
			end

			predi.OnRemove = function(self) self.NEXT = nil end

			return true
		end
	end, 1)
end
