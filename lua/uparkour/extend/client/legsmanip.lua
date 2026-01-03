--[[
	作者:白狼
	2025 1 1
--]]

-- ==============================================================
-- 假的 GmodLegs3 
-- 放弃将它作为工具的想法, 已成屎山, 随便写吧...
-- ==============================================================
if g_ManipLegs and isentity(g_ManipLegs.LegEnt) and IsValid(g_ManipLegs.LegEnt) then
	g_ManipLegs.LegEnt:Remove()
	local succ, msg = pcall(g_ManipLegs.UnRegister, g_ManipLegs)
	if not succ then print('[UPExt]: LegsManip: UnRegister failed: ' .. msg) end
end

g_ManipLegs = {}

local zerovec = Vector(0, 0, 0)
local zeroang = Angle(0, 0, 0)
local diagonalvec = Vector(1, 1, 1)
local emptyTable = {}
local ManipLegs = g_ManipLegs

ManipLegs.ForwardOffset = -22

ManipLegs.BonesToRemove = {
	['ValveBiped.Bip01_Head1'] = true,
	['ValveBiped.Bip01_L_Hand'] = true,
	['ValveBiped.Bip01_L_Forearm'] = true,
	['ValveBiped.Bip01_L_Upperarm'] = true,
	['ValveBiped.Bip01_L_Clavicle'] = true,
	['ValveBiped.Bip01_R_Hand'] = true,
	['ValveBiped.Bip01_R_Forearm'] = true,
	['ValveBiped.Bip01_R_Upperarm'] = true,
	['ValveBiped.Bip01_R_Clavicle'] = true,
	['ValveBiped.Bip01_Spine4'] = true,
}

local temp = {
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
ManipLegs.BoneIterator = {}
for i, v in ipairs(temp) do 
	ManipLegs.BoneIterator[i] = {bone = v, lerpMethod = UPManip.LERP_METHOD.LOCAL} 
end
UPManip.InitBoneIterator(ManipLegs.BoneIterator)
temp = nil

ManipLegs.FRAME_LOOP_HOOK = {
	{
		EVENT_NAME = 'Think',
		IDENTITY = 'UPExtLegsManip',
		CALL = function()
			if not IsValid(LocalPlayer()) then
				return
			end

			local self = ManipLegs
			self:UpdatePosition()
			self:UpdateAnimation(FrameTime())
		end
	},

	{
		EVENT_NAME = 'ShouldDisableLegs',
		IDENTITY = 'UPExtLegsManip',
		CALL = function()
			return true
		end
	}
}

ManipLegs.MagicOffset = Vector(0, 0, 5)
ManipLegs.MagicOffsetZ0 = 8
ManipLegs.MagicOffsetZ1 = -28
ManipLegs.LerpT = 0
ManipLegs.FadeInSpeed = 10
ManipLegs.FadeOutSpeed = 3
ManipLegs.PelvisFadeInRate = 5
ManipLegs.Speed = 0

function ManipLegs:UpdatePosition()
	-- 来自 [Gmod Legs 3]
	if not IsValid(LocalPlayer()) then
		return
	end

	local ply = LocalPlayer()
	local IsPlyCrouching = ply:Crouching()
	local BiaisAngles = sharpeye_focus && sharpeye_focus.GetBiaisViewAngles && sharpeye_focus:GetBiaisViewAngles() || LocalPlayer():EyeAngles()
	local RadAngle = math.rad(BiaisAngles.y)

	local NewPos = IsPlyCrouching and ply:GetPos() or ply:GetPos() + self.MagicOffset
	local NewAngle = Angle(0, BiaisAngles.y, 0)
	
	NewPos.x = NewPos.x + math.cos(RadAngle) * self.ForwardOffset
	NewPos.y = NewPos.y + math.sin(RadAngle) * self.ForwardOffset
	if ply:GetGroundEntity() == NULL then
		NewPos.z = NewPos.z + self.MagicOffsetZ0
		if ply:KeyDown(IN_DUCK) then
			NewPos.z = NewPos.z + self.MagicOffsetZ1
		end
	end
	
	self.NewPos = NewPos
	self.NewAngle = NewAngle

	if IsValid(self.LegEnt) then
		// NewPos = zerovec
		self.LegEnt:SetPos(NewPos)
		self.LegEnt:SetAngles(NewAngle)
		self.LegEnt:SetupBones()
	end

end

function ManipLegs:UpdateAnimation(dt)
	if not IsValid(self.LegEnt) or not IsValid(LocalPlayer()) then
		return
	end

	if not isentity(self.Target) or not IsValid(self.Target) then
		self.Target = nil
	end

	if self.LastTarget ~= self.Target then
		self.LerpT = 0
		self.Snapshot = nil
		hook.Run('UPExtLegsManipTargetChanged', self.LastTarget, self.Target)
	end

	if not self.Snapshot then
		local snapshot, runtimeflags = self.LegEnt:UPMaSnapshot(self.BoneIterator)
		self.LegEnt:UPMaPrintErr(runtimeflags)
		self.Snapshot = snapshot

		// for _, v in pairs(self.Snapshot) do
		// 	debugoverlay.Box(
		// 		v:GetTranslation(), 
		// 		Vector(-1, -1, -1), 
		// 		Vector(1, 1, 1), 
		// 		10, 
		// 		Color(255, 0, 0)
		// 	)
		// end
	end

	if isentity(self.Target) and IsValid(self.Target) then
		self.LerpT = math.Clamp(self.LerpT + self.FadeInSpeed * dt, 0, 1)

		self.Target:SetupBones()
		self.LegEnt:SetupBones()

		local lerpSnapshot, runtimeflags = self.LegEnt:UPMaLerpBoneBatch(self.LerpT, 
			self.Snapshot, 
			self.Target, 
			self.BoneIterator)
		self.LegEnt:UPMaPrintErr(runtimeflags)

		local runtimeflag = self.LegEnt:UPManipBoneBatch(lerpSnapshot, 
			self.BoneIterator, UPManip.MANIP_FLAG.MANIP_POSITION)
		self.LegEnt:UPMaPrintErr(runtimeflag)
	else
		self.LerpT = math.Clamp(self.LerpT + self.FadeOutSpeed * dt, 0, 1)
		
		LocalPlayer():SetupBones()
		self.LegEnt:SetupBones()

		local lerpSnapshot, runtimeflags = self.LegEnt:UPMaLerpBoneBatch(self.LerpT, 
			self.Snapshot, 
			LocalPlayer(), 
			self.BoneIterator)
		self.LegEnt:UPMaPrintErr(runtimeflags)


		local Bip01_Pelvis_snapshot = self.Snapshot and self.Snapshot['ValveBiped.Bip01_Pelvis']
		local Bip01_Pelvis_lerpSnapshot = lerpSnapshot['ValveBiped.Bip01_Pelvis']
		local Bip01_Pelvis_boneId = LocalPlayer():LookupBone('ValveBiped.Bip01_Pelvis')
		if Bip01_Pelvis_snapshot and Bip01_Pelvis_lerpSnapshot and Bip01_Pelvis_boneId then
			local Bip01_Pelvis_ply = LocalPlayer():GetBoneMatrix(Bip01_Pelvis_boneId)
			if Bip01_Pelvis_ply then
				local Bip01_Pelvis_posl = WorldToLocal(
					Bip01_Pelvis_ply:GetTranslation(), 
					Bip01_Pelvis_ply:GetAngles(), 
					LocalPlayer():GetPos(), 
					self.NewAngle
				)
				Bip01_Pelvis_lerpSnapshot:SetTranslation(
					LerpVector(
						math.Clamp(self.LerpT * self.PelvisFadeInRate, 0, 1),
						Bip01_Pelvis_snapshot:GetTranslation(), 
						self.LegEnt:LocalToWorld(Bip01_Pelvis_posl)
					)	
				) 
			end
		end
		
		local runtimeflag = self.LegEnt:UPManipBoneBatch(lerpSnapshot, 
			self.BoneIterator, UPManip.MANIP_FLAG.MANIP_POSITION)
		self.LegEnt:UPMaPrintErr(runtimeflag)

		// if self.LerpT >= 1 then
		// 	self:Sleep()
		// end
	end

	self.LastTarget = self.Target
end

function ManipLegs:PushFrameLoop()
	for _, v in ipairs(self.FRAME_LOOP_HOOK) do
		hook.Add(v.EVENT_NAME, v.IDENTITY, v.CALL)
	end
	
	return true
end

function ManipLegs:PopFrameLoop()
	for _, v in ipairs(self.FRAME_LOOP_HOOK) do
		hook.Remove(v.EVENT_NAME, v.IDENTITY)
	end

	return true
end

function ManipLegs:Init()
	-- 来自 [Gmod Legs 3]

	if not IsValid(LocalPlayer()) then
		return false
	end

	local ply = LocalPlayer()
	local LegEnt = self.LegEnt
	local created = false

	if not IsValid(LegEnt) then
		LegEnt = ClientsideModel(ply:GetLegModel(), RENDER_GROUP_OPAQUE_ENTITY)	
		self.LegEnt = LegEnt
		created = true
	else
		LegEnt:SetModel(ply:GetLegModel())
	end

	LegEnt:SetNoDraw(false)

	for k, v in pairs(ply:GetBodyGroups()) do
		local current = ply:GetBodygroup(v.id)
		LegEnt:SetBodygroup(v.id,  current)
	end

	for k, v in ipairs(LocalPlayer():GetMaterials()) do
		LegEnt:SetSubMaterial(k - 1, LocalPlayer():GetSubMaterial(k - 1))
	end

	LegEnt:SetSkin(LocalPlayer():GetSkin())
	LegEnt:SetMaterial(LocalPlayer():GetMaterial())
	LegEnt:SetColor(LocalPlayer():GetColor())
	LegEnt.GetPlayerColor = function()
		return LocalPlayer():GetPlayerColor()
	end

	for i = 0, LegEnt:GetBoneCount() do
		LegEnt:ManipulateBoneAngles(i, zeroang)
		LegEnt:ManipulateBonePosition(i, zerovec)
		LegEnt:ManipulateBoneScale(i, diagonalvec)
	end

	if created then
		print('created')
		for boneName, v in pairs(self.BonesToRemove) do
			local boneId = LegEnt:LookupBone(boneName)
			if not boneId then 
				continue 
			end
			
			local manipVec, manipAng, manipScale = unpack(istable(v) and v or emptyTable)
			manipVec = isvector(manipVec) and manipVec or zerovec
			manipAng = isangle(manipAng) and manipAng or zeroang
			manipScale = isvector(manipScale) and manipScale or zerovec

			
			LegEnt:ManipulateBonePosition(boneId, manipVec)
			LegEnt:ManipulateBoneAngles(boneId, manipAng)
			LegEnt:ManipulateBoneScale(boneId, manipScale)
		end
	end

	return true
end

function ManipLegs:Wake()
	local succ = self:Init()
	succ = succ and self:PushFrameLoop()

	if not succ then
		return false
	end

	self.LegEnt:SetParent(ply)
	self.LegEnt:SetNoDraw(false)
	self.IsWake = true

	hook.Run('UPExtLegsManipWake', self.LegEnt)

	return true
end

function ManipLegs:Sleep()
	local succ = self:Init()
	succ = succ and self:PopFrameLoop()

	if not succ then
		return false
	end

	self.LegEnt:SetParent(nil)
	self.LegEnt:SetNoDraw(false)
	self.IsWake = false

	hook.Run('UPExtLegsManipSleep', self.LegEnt)

	return true
end

ManipLegs.MAIN_EVENT = {
	{
		IDENTITY = 'UPExtLegsManip',
		EVENT_NAME = 'VMLegsPostPlayAnim',
		CALL = function(anim)
			if not IsValid(VMLegs.LegModel) or not IsValid(VMLegs.LegParent) then
				print('[UPExt]: LegsManip: VMLegs has not been started yet!')
				return
			end

			VMLegs.LegModel:SetNoDraw(true)

			local self = ManipLegs
			self.LerpT = 0
			self.Target = VMLegs.LegParent
			self:Wake()
		end
	}
}

function ManipLegs:Register()
	print('[UPExt]: LegsManip: Register')
	for _, v in ipairs(self.MAIN_EVENT) do
		hook.Add(v.EVENT_NAME, v.IDENTITY, v.CALL)
	end
end

function ManipLegs:UnRegister()
	print('[UPExt]: LegsManip: UnRegister')
	for _, v in ipairs(self.MAIN_EVENT) do
		hook.Remove(v.EVENT_NAME, v.IDENTITY)
	end

	for _, v in ipairs(self.FRAME_LOOP_HOOK) do
		hook.Remove(v.EVENT_NAME, v.IDENTITY)
	end
end


g_ManipLegs:Init()
g_ManipLegs:Register()

concommand.Add('upext_legsmanip_debug', function()
	print('[UPExt]: LegsManip: Debug')

	if IsValid(g_ManipLegs.LegEnt) then
		g_ManipLegs.LegEnt:SetupBones()
		for i = 0, g_ManipLegs.LegEnt:GetBoneCount() - 1 do
			local boneName = g_ManipLegs.LegEnt:GetBoneName(i)
			local manipPos = g_ManipLegs.LegEnt:GetManipulateBonePosition(i)
			local manipAng = g_ManipLegs.LegEnt:GetManipulateBoneAngles(i)
			local manipScale = g_ManipLegs.LegEnt:GetManipulateBoneScale(i)
			print(string.format('============%s===========', boneName))
			print(string.format('ManipPos: %s', manipPos))
			print(string.format('ManipAng: %s', manipAng))
			print(string.format('ManipScale: %s', manipScale))
			print(string.format('============%s===========\n', boneName))
		end
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