--[[
	作者:白狼
	2025 1 1
--]]

-- ==============================================================
-- 假的 GmodLegs3 
-- 放弃将它作为工具的想法, 随便写吧...
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

ManipLegs.BoneMapping = {
	main = {
		['self'] = {},
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

local BoneSelf = ManipLegs.BoneMapping.main['self']
function BoneSelf:LerpLocalHandler(newAng, newPos, newScale, entOrSnapshot, boneName, tarEntOrSnapshot)
	local tarEnt = UPManip.GetEntFromSnapshot(tarEntOrSnapshot)
	print(tarEnt)
	return newAng, newPos, newScale
end


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
	}
}

ManipLegs.MagicOffset = Vector(0, 0, 5)
ManipLegs.MagicOffsetZ0 = 8
ManipLegs.MagicOffsetZ1 = -28
ManipLegs.LerpT = 0
ManipLegs.FadeInSpeed = 10
ManipLegs.FadeOutSpeed = 10
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

	local newPos = IsPlyCrouching and ply:GetPos() or ply:GetPos() + self.MagicOffset
	local newAngle = Angle(0, BiaisAngles.y, 0)
	
	newPos.x = newPos.x + math.cos(RadAngle) * self.ForwardOffset
	newPos.y = newPos.y + math.sin(RadAngle) * self.ForwardOffset
	if ply:GetGroundEntity() == NULL then
		newPos.z = newPos.z + self.MagicOffsetZ0
		if ply:KeyDown(IN_DUCK) then
			newPos.z = newPos.z + self.MagicOffsetZ1
		end
	end
	
	self.newPos = newPos
	self.newAngle = newAngle

	if IsValid(self.LegEnt) then
		newPos = zerovec
		self.LegEnt:SetPos(newPos)
		self.LegEnt:SetAngles(newAngle)
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
		self.Snapshot = UPManip.SnapshotLocal(self.LegEnt, self.BoneMapping)
	end

	if isentity(self.Target) and IsValid(self.Target) then
		self.LerpT = math.Clamp(self.LerpT + self.FadeInSpeed * dt, 0, 1)

		self.Target:SetupBones()
		self.LegEnt:SetupBones()

		UPManip.LerpBoneLocalByMapping(self.LerpT, 
			self.Snapshot, self.Target, 
			self.BoneMapping, false
		)
	else
		self.LerpT = math.Clamp(self.LerpT + self.FadeOutSpeed * dt, 0, 1)
		
		LocalPlayer():SetupBones()
		self.LegEnt:SetupBones()

		UPManip.LerpBoneLocalByMapping(self.LerpT, 
			self.Snapshot, LocalPlayer(), 
			self.BoneMapping, false
		)

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
	
	if not IsValid(LegEnt) then
		LegEnt = ClientsideModel(ply:GetLegModel(), RENDER_GROUP_OPAQUE_ENTITY)	
		self.LegEnt = LegEnt
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