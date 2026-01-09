--[[
	作者:白狼
	2025 12 27
]]--

-- ==================== 二段翻越 - 低 ===============
-- 为了加速检测, 这里需要复用攀爬的检测, 所以翻越是无法独立检测的
local VaultDetector = UPar.VaultDetector
local IsInSolid = UPar.IsInSolid
local unitzvec = UPar.unitzvec
local Hermite3 = UPar.Hermite3
local CallAct = UPar.CallAct

local upvaultdl = UPAction:Register('upvaultdl', {
	AAAACreat = '白狼',
	AAADesc = '#upvaultdl.desc',
	icon = 'upgui/uparkour.jpg',
	label = '#upvaultdl',
	defaultDisabled = false
})

upvaultdl:InitConVars({
	{
		name = 'upctrl_vt_evlen_f',
		default = '0.5',
		invisible = true
	},

	{
		name = 'upctrl_vtd_thr_f',
		default = '0.15',
		invisible = true
	},

	{label = '#upvaultdl.option.detector', widget = 'Label'},

	{
		name = 'upvtdl_ehlen_f',
		default = '1',
		widget = 'NumSlider',
		min = 0,
		max = 2,
		decimals = 2,
		help = true,
	},

	{label = '#upvaultdl.option.speed', widget = 'Label'},
	{label = '#upvaultdl.option.speed.help', color = Color(255, 170, 0), widget = 'Label'},

	{
		name = 'upvtdl_enable_start_refspeed',
		default = '1',
		widget = 'CheckBox'
	},

	{
		name = 'upvtdl_enable_end_refspeed',
		default = '1',
		widget = 'CheckBox'
	},

	{
		name = 'upvtdl_start_speed_f',
		default = '0.25 1 1',
		widget = 'UParVecEditor',
		min = 0, max = 2, decimals = 2, interval = 0.1,
		help = true
	},

	{
		name = 'upvtdl_end_speed_f',
		default = '0.25 1 1',
		widget = 'UParVecEditor',
		min = 0, max = 2, decimals = 2, interval = 0.1,
		help = true
	},

	{label = 'SpeedPredi', widget = 'Label'}
})

function upvaultdl:Detector(ply, obsTrace, climbTrace)
	local convars = self.ConVars

	local vaultTrace = VaultDetector(ply, obsTrace, climbTrace, 
		convars.upvtdl_ehlen_f:GetFloat(), 
		convars.upctrl_vt_evlen_f:GetFloat()
	)

	if istable(vaultTrace) and not IsInSolid(ply, vaultTrace.HitPos + unitzvec, false) then
		return vaultTrace
	end
end

function upvaultdl:GetVaultMoveData(ply, obsTrace, vaultTrace, refVel)
	refVel = isvector(refVel) and refVel or ply:GetVelocity()

	local convars = self.ConVars
	local startpos = obsTrace.StartPos
	local endpos = vaultTrace.HitPos + unitzvec
	local moveDir = (endpos - startpos):GetNormalized()
	local moveDis = (endpos - startpos):Dot(moveDir)

	local refSpeed = moveDir:Dot(refVel)
	local startspeedRef = convars.upvtdl_enable_start_refspeed:GetBool() and refSpeed or 0
	local endspeedRef = convars.upvtdl_enable_end_refspeed:GetBool() and refSpeed or 0

	local moveVec = ply:KeyDown(IN_SPEED)  
		and Vector(ply:GetJumpPower(), 0, ply:GetRunSpeed())
		or Vector(ply:GetJumpPower(), ply:GetWalkSpeed(), 0)

	local startspeed = math.max(startspeedRef, 10,
		math.abs(Vector(convars.upvtdl_start_speed_f:GetString()):Dot(moveVec)))

	local endspeed = math.max(endspeedRef, 10,
		math.abs(Vector(convars.upvtdl_end_speed_f:GetString()):Dot(moveVec)))

	local moveDuration = moveDis * 2 / (startspeed + endspeed)

	if moveDuration <= 0 then 
		print('[upvaultdl]: Warning: moveDuration <= 0')
		return
	end

	return {
		startpos = startpos,
		endpos = endpos,

		startspeed = startspeed,
		endspeed = endspeed,

		starttime = CurTime(),

		duration = moveDuration,
		endvel = obsTrace.Normal * endspeed,
	}
end

function upvaultdl:GetMoveData(ply, obsTrace, climbTrace, vaultTrace, refVel)
	local vaultMoveData = self:GetVaultMoveData(ply, obsTrace, vaultTrace, refVel)
	
	if not vaultMoveData then
		return
	end

	local threshold = obsTrace.plyh * self.ConVars.upctrl_vtd_thr_f:GetFloat()
	if vaultMoveData.endpos[3] - vaultMoveData.startpos[3] < threshold then
		return {{}, vaultMoveData, rhythm = 2}
	else
		-- 二段翻越
		local climbMoveData = CallAct('uplowclimb', 'GetMoveData', ply, obsTrace, climbTrace, refVel)
		climbMoveData.endpos[3] = vaultMoveData.endpos[3]
		climbMoveData.endspeed = climbMoveData.startspeed * 0.5
		climbMoveData.duration = (climbMoveData.startpos - climbMoveData.endpos):Length() * 2 / 
		(climbMoveData.startspeed + climbMoveData.endspeed)
		

		vaultMoveData.startpos = climbMoveData.endpos
		vaultMoveData.startspeed = climbMoveData.endspeed
		vaultMoveData.duration = (vaultMoveData.startpos - vaultMoveData.endpos):Length() * 2 / 
		(vaultMoveData.startspeed + vaultMoveData.endspeed)

		return {climbMoveData, vaultMoveData, rhythm = 1}
	end
end


function upvaultdl:Check(ply, obsTrace, climbTrace, refVel)
	if not obsTrace or not climbTrace then
		return
	end

	if not isentity(ply) or not IsValid(ply) then
		print('[upvaultdl]: Warning: Invalid player')
		return
	end

	if ply:GetMoveType() ~= MOVETYPE_WALK or !ply:Alive() then 
		return
	end

	local vaultTrace = self:Detector(ply, obsTrace, climbTrace)
	if not vaultTrace then
		return
	end

	return self:GetMoveData(ply, obsTrace, climbTrace, vaultTrace, refVel)
end

function upvaultdl:Start(ply, data)
	if CLIENT then
		local timeout = ((isnumber(data[1].duration) and data[1].duration or 0) + 
			(isnumber(data[2].duration) and data[2].duration or 0)) + 0.5

		local needduck = false
		UPar.SetMoveControl(true, true, 
			needduck and IN_JUMP or bit.bor(IN_DUCK, IN_JUMP),
			needduck and IN_DUCK or 0, 
			timeout)
	end
	
	if ply:GetMoveType() ~= MOVETYPE_NOCLIP then 
		ply:SetMoveType(MOVETYPE_NOCLIP)
	end
end

function upvaultdl:Think(ply, data, mv, cmd)
	if data.rhythm == 1 then
		local isClimbEnd = CallAct('uplowclimb', 'Think', ply, data[1], mv, cmd)
		if isClimbEnd then 
			data.rhythm = 2
			data[2].starttime = CurTime()
			UPar.ActEffRhythmChange(ply, self, 2)
		end
	elseif data.rhythm == 2 then
		return CallAct('upvault', 'Think', ply, data[2], mv, cmd)
	end
end

function upvaultdl:Clear(ply, data, mv, cmd)
	if CLIENT then 
		UPar.SetMoveControl(false, false, 0, 0)
	elseif SERVER then
		if mv and istable(data) and istable(data[2]) and isvector(data[2].endvel) then
			mv:SetVelocity(data[2].endvel)
		end
    end

	if ply:GetMoveType() == MOVETYPE_NOCLIP then 
		ply:SetMoveType(MOVETYPE_WALK)
	end
end

if CLIENT then
	UPar.SeqHookAdd('UParActCVarWidget_upvaultdl', 'default', function(cvCfg, panel)
		local cvName = cvCfg.name
		local label = cvCfg.label
		if cvName == 'upvtdl_ehlen_f' 
		or label == 'SpeedPredi' then
			local created = UPar.SeqHookRun('UParActCVarWidget', 'upvaultdl', cvCfg, panel)
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
				if label == 'SpeedPredi' then
					local ply = LocalPlayer()
			
					local startspeedf = Vector(UPar.GetActKV('upvaultdl', 'ConVars')['upvtdl_start_speed_f']:GetString())
					local endspeedf = Vector(UPar.GetActKV('upvaultdl', 'ConVars')['upvtdl_end_speed_f']:GetString())
					local enableStartSpeedRef = UPar.GetActKV('upvaultdl', 'ConVars')['upvtdl_enable_start_refspeed']:GetBool()
					local enableEndSpeedRef = UPar.GetActKV('upvaultdl', 'ConVars')['upvtdl_enable_end_refspeed']:GetBool()
					
					local moveVec = Vector(ply:GetJumpPower(), ply:GetWalkSpeed(), 0)
					local moveVec2 = Vector(ply:GetJumpPower(), 0, ply:GetRunSpeed())

					local startspeed_walk = tostring(math.Round(startspeedf:Dot(moveVec), 2))
					local startspeed_run = tostring(math.Round(startspeedf:Dot(moveVec2), 2))
					if enableStartSpeedRef then
						startspeed_walk = 'max(' .. plyVelPhrase .. ', ' .. startspeed_walk .. ')'
						startspeed_run = 'max(' .. plyVelPhrase .. ', ' .. startspeed_run .. ')'
					end

					local endspeed_walk = tostring(math.Round(endspeedf:Dot(moveVec), 2))
					local endspeed_run = tostring(math.Round(endspeedf:Dot(moveVec2), 2))
					
					if enableEndSpeedRef then
						endspeed_walk = 'max(' .. plyVelPhrase .. ', ' .. endspeed_walk .. ')'
						endspeed_run = 'max(' .. plyVelPhrase .. ', ' .. endspeed_run .. ')'
					end

					value = string.format(
						'%s ~ %s,   %s ~ %s', 
						startspeed_walk,
						endspeed_walk,
						startspeed_run,
						endspeed_run
					)

				elseif cvName == 'upvtdl_ehlen_f'then
					local min, max = LocalPlayer():GetCollisionBounds()
					local plyHeight = max[3] - min[3]
					local cvar = UPar.GetActKV('upvaultdl', 'ConVars')[cvName]

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
