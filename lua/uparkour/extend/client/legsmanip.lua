--[[
	作者:白狼
	2025 1 1
--]]

-- ==============================================================
-- 定义骨骼映射
-- ==============================================================
g_ManipBoneMapping = {
	main = {
		['self'] = true,
		['ValveBiped.Bip01_Pelvis'] = true,
		['ValveBiped.Bip01_Spine'] = true,
		['ValveBiped.Bip01_Spine1'] = true,
		['ValveBiped.Bip01_Spine2'] = true,

		['ValveBiped.Bip01_L_Thigh'] = true,
		['ValveBiped.Bip01_L_Calf'] = true,
		['ValveBiped.Bip01_L_Foot'] = true,
		['ValveBiped.Bip01_L_Toe0'] = true,
		
		['ValveBiped.Bip01_R_Thigh'] = true,
		['ValveBiped.Bip01_R_Calf'] = true,
		['ValveBiped.Bip01_R_Foot'] = true,
		['ValveBiped.Bip01_R_Toe0'] = true
	},

	keySort = {
		'self',
		'ValveBiped.Bip01_Pelvis',
		'ValveBiped.Bip01_Spine',
		'ValveBiped.Bip01_Spine1',
		'ValveBiped.Bip01_Spine2',

		'ValveBiped.Bip01_L_Thigh',
		'ValveBiped.Bip01_L_Calf',
		'ValveBiped.Bip01_L_Foot',
		'ValveBiped.Bip01_L_Toe0',

		'ValveBiped.Bip01_R_Thigh',
		'ValveBiped.Bip01_R_Calf',
		'ValveBiped.Bip01_R_Foot',
		'ValveBiped.Bip01_R_Toe0'
	}
}

-- ==============================================================
-- 假的 GmodLegs3
-- ==============================================================
if g_FakeGmodLegs3 and isentity(g_FakeGmodLegs3.LegEnt) and IsValid(g_FakeGmodLegs3.LegEnt) then
	g_FakeGmodLegs3.LegEnt:Remove()
end


g_FakeGmodLegs3 = {}

setmetatable(g_FakeGmodLegs3, {
    __index = function(t, k)
        local val = rawget(t, k)
        if val ~= nil then
            return val
        end

        return g_Legs and g_Legs[k]
    end
})

g_FakeGmodLegs3.ForwardOffset = -22
g_FakeGmodLegs3.RenderOverride = function(ent, renderMode)
	-- 来自 [Gmod Legs 3]
	-- Sorry, 我实在没看懂

	if LocalPlayer():InVehicle() then
		return
	end

	local self = g_FakeGmodLegs3
	local ply = LocalPlayer()
	
	self.RenderPos = ply:Crouching() and ply:GetPos() or ply:GetPos() + Vector(0, 0, 5)
	self.BiaisAngles = sharpeye_focus && sharpeye_focus.GetBiaisViewAngles && sharpeye_focus:GetBiaisViewAngles() || LocalPlayer():EyeAngles()
	self.RenderAngle = Angle(0, self.BiaisAngles.y, 0)
	self.RadAngle = math.rad(self.BiaisAngles.y)
	self.RenderPos.x = self.RenderPos.x + math.cos(self.RadAngle) * self.ForwardOffset
	self.RenderPos.y = self.RenderPos.y + math.sin(self.RadAngle) * self.ForwardOffset

	if LocalPlayer():GetGroundEntity() == NULL then
		self.RenderPos.z = self.RenderPos.z + 8
		if LocalPlayer():KeyDown(IN_DUCK) then
			self.RenderPos.z = self.RenderPos.z - 28
		end
	end

	self.RenderColor = LocalPlayer():GetColor()

	local bEnabled = render.EnableClipping(true)
	render.PushCustomClipPlane(self.ClipVector, self.ClipVector:Dot(EyePos()))
	render.SetColorModulation(self.RenderColor.r / 255, self.RenderColor.g / 255, self.RenderColor.b / 255)
	render.SetBlend(self.RenderColor.a / 255)
		ent:SetPos(self.RenderPos)
		ent:SetAngles(self.RenderAngle)
		ent:SetupBones()
		ent:DrawModel()
		ent:SetRenderOrigin()
		ent:SetRenderAngles() 
	render.SetBlend(1)
	render.SetColorModulation(1, 1, 1)
	render.PopCustomClipPlane()
	render.EnableClipping(bEnabled)
  
	if not self.FirstRenderFinished then
		self.FirstRenderFinished = true
		if istable(self.TempData) then
			hook.Run('UPExtFakeLegsFirstRender', unpack(self.TempData))
		else
			hook.Run('UPExtFakeLegsFirstRender')
		end
		self.TempData = nil
	end
end

function g_FakeGmodLegs3:Think(maxseqgroundspeed)
	-- 来自[Gmod Legs 3]
	if not IsValid(self.LegEnt) then 
		return
	end

	self.Velocity = LocalPlayer():GetVelocity():Length2D()

	self.PlaybackRate = 1

	if self.Velocity > 0.5 then
		if maxseqgroundspeed < 0.001 then
			self.PlaybackRate = 0.01
		else
			self.PlaybackRate = self.Velocity / maxseqgroundspeed
			self.PlaybackRate = math.Clamp(self.PlaybackRate, 0.01, 10)
		end
	end

	self.LegEnt:SetPlaybackRate(self.PlaybackRate)

	self.Sequence = LocalPlayer():GetSequence()

	if (self.LegEnt.Anim != self.Sequence) then
		self.LegEnt.Anim = self.Sequence
		self.LegEnt:ResetSequence(self.Sequence)
	end

	self.LegEnt:FrameAdvance(CurTime() - self.LegEnt.LastTick)
	self.LegEnt.LastTick = CurTime()

	self.BreathScale = sharpeye && sharpeye.GetStamina && math.Clamp(math.floor(sharpeye.GetStamina() * 5 * 10) / 10, 0.5, 5) || 0.5

	if self.NextBreath <= CurTime() then
		self.NextBreath = CurTime() + 1.95 / self.BreathScale
		self.LegEnt:SetPoseParameter("breathing", self.BreathScale)
	end

	self.LegEnt:SetPoseParameter("move_x", (LocalPlayer():GetPoseParameter("move_x") * 2) - 1) -- Translate the walk x direction
	self.LegEnt:SetPoseParameter("move_y", (LocalPlayer():GetPoseParameter("move_y") * 2) - 1) -- Translate the walk y direction
	self.LegEnt:SetPoseParameter("move_yaw", (LocalPlayer():GetPoseParameter("move_yaw") * 360) - 180) -- Translate the walk direction
	self.LegEnt:SetPoseParameter("body_yaw", (LocalPlayer():GetPoseParameter("body_yaw") * 180) - 90) -- Translate the body yaw
	self.LegEnt:SetPoseParameter("spine_yaw",(LocalPlayer():GetPoseParameter("spine_yaw") * 180) - 90) -- Translate the spine yaw

	if LocalPlayer():InVehicle() then
		self.LegEnt:SetPoseParameter("vehicle_steer", (LocalPlayer():GetVehicle():GetPoseParameter("vehicle_steer") * 2) - 1) -- Translate the vehicle steering
	end
end

hook.Add('UpdateAnimation', 'UPExtLegsManip', function(ply, velocity, maxseqgroundspeed)
	if ply == LocalPlayer() then
		local self = g_FakeGmodLegs3

		if IsValid(self.LegEnt) and self.LegEnt:GetNoDraw() then
			return
		end

		if IsValid(self.LegEnt) then
			self:Think(maxseqgroundspeed)
			if (string.lower(LocalPlayer():GetLegModel()) != string.lower(self.LegEnt:GetModel())) then
				self:SetUp()
			end
		else
			self:SetUp()
		end
	end
end)


function g_FakeGmodLegs3:Init()
	if self.LegEnt == g_Legs.LegEnt then
		self.LegEnt = NULL
	end
	self:SetUp()

	local succ = IsValid(self.LegEnt)

	if not succ then 
		return false 
	end


	for i = 0, self.LegEnt:GetBoneCount() - 1 do
		local boneName = self.LegEnt:GetBoneName(i)
		if g_ManipBoneMapping.main[boneName] then
			self.LegEnt:ManipulateBonePosition(i, Vector(0, 0, 0))
			self.LegEnt:ManipulateBoneAngles(i, Angle(0, 0, 0))
			self.LegEnt:ManipulateBoneScale(i, Vector(1, 1, 1))
		else
			self.LegEnt:ManipulateBonePosition(i, Vector(0, 0, 0))
			self.LegEnt:ManipulateBoneAngles(i, Angle(0, 0, 0))
			self.LegEnt:ManipulateBoneScale(i, Vector(0, 0, 0))
		end
	end

	if not self.LegEnt.RenderOverride then
		self.LegEnt.RenderOverride = self.RenderOverride
	end

	return true
end

function g_FakeGmodLegs3:Wake(...)
	local succ = self:Init()
	if not succ then return false end

	
	self.FirstRenderFinished = false
	self.LegEnt:SetNoDraw(false)

	hook.Run('UPExtFakeLegsWake', ...)
	self.TempData = {...}

	return true
end

function g_FakeGmodLegs3:Sleep(...)
	local succ = self:Init()
	if not succ then return false end

	self.LegEnt:SetNoDraw(true)
	self.FirstRenderFinished = false

	hook.Run('UPExtFakeLegsSleep', ...)

	return true
end

-- ==============================================================
--[[
	由于 UPManip 对实体位置有非常严格的要求, 再者 Gmod Legs 3 的源代码无法满足低入侵修改, 于是有了此。
	这里实在容易让人感到困惑、混乱。
	由于是懒加载, 所以在启动 UPManip 时必须完成位姿更新。
]]--
-- 放弃将它作为工具的想法, 随便写吧...
-- ==============================================================

local function FadeInIterator(dt, curtime, data)
	local t = data.t
	local speed = data.speed
	local fadeInSpeed = data.fadeInSpeed
	local fadeOutSpeed = data.fadeOutSpeed
	local target = data.target
	local fadeInTarget = data.fadeInTarget
	local fadeOutTarget = data.fadeOutTarget
	local ent = data.ent
	local boneMapping = data.boneMapping

	t = math.Clamp(t + speed * dt, 0, 1)
	data.t = t

	if not isentity(ent) or not IsValid(ent) then
		print('[FrameLoop]: LegsManipEnt is invalid!')
		return true
	end

	if isentity(target) and IsValid(target) then
		target:SetupBones()
		ent:SetupBones()
		UPManip.LerpBoneWorld(t, ent, target, boneMapping, true)
	elseif isentity(fadeOutTarget) and IsValid(fadeOutTarget) then
		data.target = fadeOutTarget
		data.t = 0
		data.speed = data.fadeOutSpeed
		ent:SetParent(fadeOutTarget)
		return
	else
		print('[FrameLoop]: fadeOutTarget is invalid!')
		return true
	end

	local popFlag = target == fadeOutTarget and t >= 1

	if popFlag and data.removeFlag then
		ent:Remove()
	end

	return popFlag
end

hook.Add('UParPopFrameLoop', 'dube', function(...)
	print(...)
end)

hook.Add('UPExtFakeLegsFirstRender', 'StartLegsManip', function(anim, LegsManipEnt)
	if not IsValid(VMLegs.LegModel) or not IsValid(VMLegs.LegParent) then
		print('[UPExt]: LegsManip: VMLegs has not been started yet!')
		return
	end

	if not isentity(LegsManipEnt) or not IsValid(LegsManipEnt) then
		print('[UPExt]: LegsManipEnt is invalid!')
		return
	end

	VMLegs.LegModel:SetNoDraw(true)

	LegsManipEnt:SetPos(g_FakeGmodLegs3.LegEnt:GetPos())
	LegsManipEnt:SetAngles(g_FakeGmodLegs3.LegEnt:GetAngles())
	LegsManipEnt:SetParent(g_FakeGmodLegs3.LegEnt)

	local animData = VMLegs:GetAnim(anim)
	local fadeInSpeed = istable(animData) and animData.lerp_speed_in
	fadeInSpeed = math.max(isnumber(fadeInSpeed) and fadeInSpeed or 0.5, 0.5)

	local fadeOutSpeed = istable(animData) and animData.lerp_speed_out
	fadeOutSpeed = math.max(isnumber(fadeOutSpeed) and fadeOutSpeed or 0.5, 0.5)

	local fadeInTarget = VMLegs.LegParent
	local fadeOutTarget = g_FakeGmodLegs3.LegEnt

	UPar.PushFrameLoop('LegsManipFrameLoop', FadeInIterator, {
		t = 0,
		speed = fadeInSpeed,
		fadeInSpeed = fadeInSpeed,
		fadeOutSpeed = fadeOutSpeed,
		target = fadeInTarget,
		fadeInTarget = fadeInTarget,
		fadeOutTarget = fadeOutTarget,
		ent = LegsManipEnt,
		boneMapping = g_ManipBoneMapping,
		removeFlag = true
	}, 10)
end)


hook.Add('VMLegsPostPlayAnim', 'StartLegsManip', function(anim)
	local fkingLegs = ClientsideModel(LocalPlayer():GetModel(), RENDERGROUP_OTHER)

	local succ = g_FakeGmodLegs3:Wake(anim, fkingLegs)
	if not succ then
		print('[UPExt]: LegsManip start faild!')
	end
end)
-- ==============================================================
-- 菜单
-- ==============================================================

UPar.SeqHookAdd('UParExtendMenu', 'LegsManip', function(panel)
	panel:Help('·························· 腿部控制器 ··························')
	panel:CheckBox('#upext.legsmanip', 'upext_legsmanip')
	panel:ControlHelp('#upext.legsmanip.help')
	local help2 = panel:ControlHelp('#upext.legsmanip.help2')
	help2:SetTextColor(Color(255, 170, 0))

end, 1)