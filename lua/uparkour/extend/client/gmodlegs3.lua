--[[
	作者:白狼
	2025 12 29
--]]

local upext_gmodlegs3_compat = CreateClientConVar('upext_gmodlegs3_compat', '1', true, false, '')

-- ==============================================================
-- 兼容 GmodLegs3 (启动 VMLegs 时 禁用 GmodLegs3)
-- ==============================================================
local function temp_upext_gmodlegs3_compat_changecall(name, old, new)
	local HOOK_IDENTITY_COMPAT = 'upar.gmodleg3.compat'

	local function ShouldDisableLegs()
		return true
		// return VMLegs and VMLegs:IsActive()
	end

	if new == '1' then
		print('[UPExt]: GmodLegs3Compat enabled')
		hook.Add('ShouldDisableLegs', HOOK_IDENTITY_COMPAT, ShouldDisableLegs)
	else
		print('[UPExt]: GmodLegs3Compat disabled')
		hook.Remove('ShouldDisableLegs', HOOK_IDENTITY_COMPAT)
	end
end
cvars.AddChangeCallback('upext_gmodlegs3_compat', temp_upext_gmodlegs3_compat_changecall, 'default')
temp_upext_gmodlegs3_compat_changecall(nil, nil, upext_gmodlegs3_compat:GetBool() and '1' or '0')
temp_upext_gmodlegs3_compat_changecall = nil

-- ==============================================================
-- 在 UPManip 中注册骨骼映射数据
-- BoneKeys 必须按照骨骼父级等级排序, 
-- 可以用 UPManip:GetBoneMappingKeysSorted(ent, boneMapping, useLRU2) 来获取 BoneKeys
-- 或者调用后手动编码
-- ==============================================================

UPManip.BoneMappingCollect['VMLegs'] = {
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
}

UPManip.BoneKeysCollect['VMLegs'] = {
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

-- ==============================================================
-- UPManip 控制 Gmod Legs 3 (仿真的)
-- 由于 UPManip 对实体位置有非常严格的要求, 再者 Gmod Legs 3 的源代码无法满足低入侵修改, 于是有了此
-- 由于这个实在容易让人感到混乱, 所以我特意多写一些注释
-- ==============================================================
g_GmodLeg3Faker = {}

local zerovec = Vector(0, 0, 0)
local zeroang = Angle(0, 0, 0)
local diagonalvec = Vector(1, 1, 1)

local GmodLeg3Faker = g_GmodLeg3Faker

GmodLeg3Faker.BoneMapping = 'VMLegs'
GmodLeg3Faker.BoneKeys = 'VMLegs'

GmodLeg3Faker.FRAME_LOOP_HOOK_IDENTITY = 'UPExtGmodLegs3Manip'
GmodLeg3Faker.TIMER_IDENTITY = 'UPExtGmodLegs3Manip'

GmodLeg3Faker.BonesToRemoveNormal = {
	"ValveBiped.Bip01_Head1",
	"ValveBiped.Bip01_L_Hand",
	"ValveBiped.Bip01_L_Forearm",
	"ValveBiped.Bip01_L_Upperarm",
	"ValveBiped.Bip01_L_Clavicle",
	"ValveBiped.Bip01_R_Hand",
	"ValveBiped.Bip01_R_Forearm",
	"ValveBiped.Bip01_R_Upperarm",
	"ValveBiped.Bip01_R_Clavicle",
	"ValveBiped.Bip01_L_Finger4",
	"ValveBiped.Bip01_L_Finger41",
	"ValveBiped.Bip01_L_Finger42",
	"ValveBiped.Bip01_L_Finger3",
	"ValveBiped.Bip01_L_Finger31",
	"ValveBiped.Bip01_L_Finger32",
	"ValveBiped.Bip01_L_Finger2",
	"ValveBiped.Bip01_L_Finger21",
	"ValveBiped.Bip01_L_Finger22",
	"ValveBiped.Bip01_L_Finger1",
	"ValveBiped.Bip01_L_Finger11",
	"ValveBiped.Bip01_L_Finger12",
	"ValveBiped.Bip01_L_Finger0",
	"ValveBiped.Bip01_L_Finger01",
	"ValveBiped.Bip01_L_Finger02",
	"ValveBiped.Bip01_R_Finger4",
	"ValveBiped.Bip01_R_Finger41",
	"ValveBiped.Bip01_R_Finger42",
	"ValveBiped.Bip01_R_Finger3",
	"ValveBiped.Bip01_R_Finger31",
	"ValveBiped.Bip01_R_Finger32",
	"ValveBiped.Bip01_R_Finger2",
	"ValveBiped.Bip01_R_Finger21",
	"ValveBiped.Bip01_R_Finger22",
	"ValveBiped.Bip01_R_Finger1",
	"ValveBiped.Bip01_R_Finger11",
	"ValveBiped.Bip01_R_Finger12",
	"ValveBiped.Bip01_R_Finger0",
	"ValveBiped.Bip01_R_Finger01",
	"ValveBiped.Bip01_R_Finger02",
	"ValveBiped.Bip01_Spine4"
}

GmodLeg3Faker.BonesToRemoveVehicle = {
	"ValveBiped.Bip01_Head1",
}

-- 原版 Gmod Legs 3 需要3个帧循环来完成视觉效果处理, 尊重原作, 这里也使用3个 
GmodLeg3Faker.FRAME_LOOP_HOOK_UpdateAnimation = function(ply, velocity, maxseqgroundspeed)
	-- 来自 GmodLegs3
	if ply == LocalPlayer() then
		local self = GmodLeg3Faker
		if IsValid(self.LegEnt) then
			if self.LerpT then
				self:ManipThink()
			else
				self:Think(maxseqgroundspeed)
			end
			
			if (string.lower(LocalPlayer():GetLegModel()) != string.lower(self.LegEnt:GetModel())) then
				self:SetUp()
			end
		else
			self:SetUp()
		end
	end
end

GmodLeg3Faker.FRAME_LOOP_HOOK_PostDrawTranslucentRenderables = function()
	if (LocalPlayer() && !LocalPlayer():InVehicle()) then
		local self = GmodLeg3Faker
		self:DoFinalRender()
	end
end

GmodLeg3Faker.FRAME_LOOP_HOOK_RenderScreenspaceEffects = function()
	if (LocalPlayer():InVehicle()) then
		local self = GmodLeg3Faker
		self:DoFinalRender()
	end
end

-- 由于不想造成额外的性能开销, 这里使用懒加载策略, 所以需要一些函数来管理
function GmodLeg3Faker:PushFrameLoopHook(timeout)
	if not self:Init() then
		return false
	end

	local identity = self.FRAME_LOOP_HOOK_IDENTITY
    hook.Add('UpdateAnimation', identity, self.FRAME_LOOP_HOOK_UpdateAnimation)
	hook.Add('PostDrawTranslucentRenderables', identity, self.FRAME_LOOP_HOOK_PostDrawTranslucentRenderables)
	hook.Add('RenderScreenspaceEffects', identity, self.FRAME_LOOP_HOOK_RenderScreenspaceEffects)
	timeout = isnumber(timeout) and timeout or 5
	timer.Create(self.TIMER_IDENTITY, timeout, 1, function()
		self:PopFrameLoopHook()
	end)

	return true
end

function GmodLeg3Faker:PopFrameLoopHook()
	local identity = self.FRAME_LOOP_HOOK_IDENTITY
    hook.Remove('UpdateAnimation', identity)
	hook.Remove('PostDrawTranslucentRenderables', identity)
	hook.Remove('RenderScreenspaceEffects', identity)

	return true
end

function GmodLeg3Faker:SetNewFrameLoopHookIdentity(identity)
	self:PopFrameLoopHook()
	self.FRAME_LOOP_HOOK_IDENTITY = identity
end

-- 这里依旧尊重
function GmodLeg3Faker:WeaponChanged(weap)
	if IsValid(self.LegEnt) then
		for i = 0, self.LegEnt:GetBoneCount() do
			self.LegEnt:ManipulateBoneScale(i, Vector(1,1,1))
			self.LegEnt:ManipulateBonePosition(i, vector_origin)
		end

		self.BonesToRemove = LocalPlayer():InVehicle() and self.BonesToRemoveVehicle or self.BonesToRemoveNormal

		for k, v in pairs(self.BonesToRemove) do
			local bone = self.LegEnt:LookupBone(v)
			if (bone) then
				self.LegEnt:ManipulateBoneScale(bone, Vector(0,0,0))
				if ( !LocalPlayer():InVehicle() ) then
					self.LegEnt:ManipulateBonePosition(bone, Vector(0,-100,0))
					self.LegEnt:ManipulateBoneAngles(bone, Angle(0,0,0))
				end
			end
		end
	end
end

-- 这里需要改一下, 原版的 腿部实体是在原点(零点), 而 UPManip 需要正确位置
function GmodLeg3Faker:DoFinalRender()
	-- 来自 GmodLegs3
	cam.Start3D(EyePos(), EyeAngles())
		if (LocalPlayer():Crouching() || LocalPlayer():InVehicle()) then
			self.RenderPos = LocalPlayer():GetPos()
		else
			self.RenderPos = LocalPlayer():GetPos() + Vector(0,0,5)
		end

		if LocalPlayer():InVehicle() then
			self.RenderAngle = LocalPlayer():GetVehicle():GetAngles()
			self.RenderAngle:RotateAroundAxis(self.RenderAngle:Up(), 90)
		else
			self.BiaisAngles = sharpeye_focus && sharpeye_focus.GetBiaisViewAngles && sharpeye_focus:GetBiaisViewAngles() || LocalPlayer():EyeAngles()
			self.RenderAngle = Angle(0, self.BiaisAngles.y, 0)
			self.RadAngle = math.rad(self.BiaisAngles.y)
			self.ForwardOffset = -22
			self.RenderPos.x = self.RenderPos.x + math.cos(self.RadAngle) * self.ForwardOffset
			self.RenderPos.y = self.RenderPos.y + math.sin(self.RadAngle) * self.ForwardOffset

			if LocalPlayer():GetGroundEntity() == NULL then
				self.RenderPos.z = self.RenderPos.z + 8
				if LocalPlayer():KeyDown(IN_DUCK) then
					self.RenderPos.z = self.RenderPos.z - 28
				end
			end
		end

		self.RenderColor = LocalPlayer():GetColor()
		
		local ClipVector = self.RenderAngle:Forward()
		local ClipDistance = ClipVector:Dot(self.RenderPos - 20 * ClipVector)

		local bEnabled = render.EnableClipping(true)
			render.PushCustomClipPlane(ClipVector, ClipDistance)
				render.SetColorModulation(self.RenderColor.r / 255, self.RenderColor.g / 255, self.RenderColor.b / 255)
					render.SetBlend(self.RenderColor.a / 255)
							self.LegEnt:SetPos(self.RenderPos)
							self.LegEnt:SetAngles(self.RenderAngle)
							self.LegEnt:SetupBones()
							self.LegEnt:DrawModel()
					render.SetBlend(1)
				render.SetColorModulation(1, 1, 1)
			render.PopCustomClipPlane()
		render.EnableClipping(bEnabled)
	cam.End3D()
end

-- 这里用元表吧, 需要重新初始化一个腿部实体
function GmodLeg3Faker:Init()
	if not g_Legs or not istable(g_Legs) then
		print('[UPExt]: [Gmod Legs 3] not install!')
		return false
	end

	if not self.Initialized then
		-- UPar.DeepInject(self, UPar.DeepClone(g_Legs))
		setmetatable(self, {__index = g_Legs})

		self.Initialized = true
		self.LegEnt = nil
	end

	self:SetUp()

	return IsValid(self.LegEnt)
end

function GmodLeg3Faker:FadeIn(tarEnt, lerpSpeed)
	if not self:Init() then
		return false
	end

	-- 快照需要在骨骼强制更新之后
	self.LegEnt:SetParent(tarEnt)
	self.LegEnt:SetupBones()
	self.Snapshot = UPManip:Snapshot(g_GmodLeg3Faker.LegEnt, 'VMLegs')
	self.TarEnt, self.LastTarEnt = tarEnt, tarEnt
	self.LerpSpeed = math.abs(isnumber(lerpSpeed) and lerpSpeed or 5)
	self.LerpT = 0

	-- 这个非常重要, 用来标记是否是第一次变换完成, UPManip 需要在第一次变换完成后才能进行插值
	-- 而原版 Gmod Legs 3 是在渲染中更新位置的, 所以尊重
	self.IsFirstTransformFinished = false

	self:PushFrameLoopHook()

	return true
end

function GmodLeg3Faker:FadeOut(lerpSpeed)
	return self:FadeIn(nil, lerpSpeed)
end

function GmodLeg3Faker:ManipThink()
	-- 这很重要
	if not self.IsFirstTransformFinished then
		return
	end

	if not isnumber(self.LerpT) then
		ErrorNoHaltWithStack('GmodLeg3Faker:ManipThink: LerpT is not a number!')
		self.LerpT = 0
	end

	if not IsValid(self.LegEnt) then
		ErrorNoHaltWithStack('GmodLeg3Faker:ManipThink: LegEnt is not valid!')
		self:PopFrameLoopHook()
	end

	self.LerpT = math.Clamp(self.LerpT + FrameTime() * self.LerpSpeed, 0, 1)
	
	if self.LastTarEnt ~= self.TarEnt then
		local newLerpT = hook.Run('UPExtGmodLegs3Manip_OnChangeSequence', self, self.LastTarEnt, self.TarEnt)
		self.LerpT = isnumber(newLerpT) and newLerpT or 0
	end
	
	if IsValid(self.TarEnt) and IsValid(self.LegEnt) then
		self.TarEnt:SetupBones()
		self.LegEnt:SetupBones()
		UPManip:LerpBoneWorld(
			self.LegEnt, 
			self.LerpT, 
			self.Snapshot or emptyTable, 
			self.TarEnt, 
			self.BoneMapping, 
			self.BoneKeys
		)
	else
		local boneMapping = UPManip:GetBoneMapping(self.BoneMapping)

		for boneName, _ in pairs(boneMapping) do
			local bone = self.LegEnt:LookupBone(boneName)

			if not bone then
				continue
			end

			local curManipPos = self.LegEnt:GetManipulateBonePosition(bone)
			local curManipAng = self.LegEnt:GetManipulateBoneAngles(bone)
			local curManipScale = self.LegEnt:GetManipulateBoneScale(bone)

			local newManipPos = LerpVector(self.LerpT, curManipPos, zerovec)
			local newManipAng = LerpAngle(self.LerpT, curManipAng, zeroang)
			local newManipScale = LerpVector(self.LerpT, curManipScale, diagonalvec)

			self.LegEnt:ManipulateBonePosition(bone, newManipPos)
			self.LegEnt:ManipulateBoneAngles(bone, newManipAng)
			self.LegEnt:ManipulateBoneScale(bone, newManipScale)
		end

		if self.LerpT >= 1 then
			local stopPop = hook.Run('UPExtGmodLegs3Manip_OnCompleteSequence', self, self.TarEnt)
			if not stopPop then self:PopFrameLoopHook() end
		end
	end

	self.LastTarEnt = self.TarEnt
end


GmodLeg3Faker.MAIN_HOOK_IDENTITY = 'UPExtGmodLegs3Manip'

GmodLeg3Faker.MAIN_HOOK_VMLegsPostPlayAnim = function(anim)
	if not VMLegs then
		print('[UPExt]: GmodLegs3Manip: [VManip Base] not install!')
		return false
	end

	if not IsValid(VMLegs.LegModel) or not IsValid(VMLegs.LegParent) then
		print('[UPExt]: GmodLegs3Manip: VMLegs has not been started yet.!')
		return false
	end

	local animData = VMLegs:GetAnim(anim)
	if not animData then
		print(string.format('[UPExt]: GmodLegs3Manip: anim "%s" not found', anim))
		return false
	end

	VMLegs.LegModel:SetNoDraw(true)

	local self = GmodLeg3Faker

	local tarEnt = VMLegs.LegParent
	local lerpSpeed = animData.lerp_speed_in

	-- 有短路保护
	local succ = self:PushFrameLoopHook()
	if succ then
		timer.Simple(0, function()
			self:FadeIn(VMLegs.LegParent, lerpSpeed)
		end)
	end

	return succ
end

GmodLeg3Faker.MAIN_HOOK_VMLegsPreRemove = function(anim)
	local self = GmodLeg3Faker
	local animData = VMLegs:GetAnim(anim)
	local lerpSpeed = animData and animData.lerp_speed_out
	self:FadeOut(lerpSpeed)

	return true
end


function GmodLeg3Faker:Register()
	local identity = self.MAIN_HOOK_IDENTITY
	hook.Add('VMLegsPostPlayAnim', identity, self.MAIN_HOOK_VMLegsPostPlayAnim)
	hook.Add('VMLegsPreRemove', identity, self.MAIN_HOOK_VMLegsPreRemove)
end

function GmodLeg3Faker:UnRegister()
	local identity = self.MAIN_HOOK_IDENTITY
	hook.Remove('VMLegsPostPlayAnim', identity)
	hook.Remove('VMLegsPreRemove', identity)
	timer.Remove(self.TIMER_IDENTITY)
	self:PopFrameLoopHook()
	if IsValid(self.LegEnt) then
		self.LegEnt:Remove()
	end
end


hook.Add('UPExtGmodLegs3Manip_OnCompleteSequence', 'test', function()
	return true
end)


local upext_gmodlegs3_manip = CreateClientConVar('upext_gmodlegs3_manip', '1', true, false, '')
local function temp_upext_gmodlegs3_manip_changecall(name, old, new)
	local HOOK_IDENTITY_COMPAT = 'upar.gmodleg3.compat'
	if new == '1' then
		print('[UPExt]: GmodLegs3Manip enabled')
		GmodLeg3Faker:Register()
	else
		print('[UPExt]: GmodLegs3Manip disabled')
		GmodLeg3Faker:UnRegister()
	end
end
cvars.AddChangeCallback('upext_gmodlegs3_manip', temp_upext_gmodlegs3_manip_changecall, 'default')
temp_upext_gmodlegs3_manip_changecall(nil, nil, upext_gmodlegs3_manip:GetBool() and '1' or '0')
temp_upext_gmodlegs3_manip_changecall = nil
-- ==============================================================
-- 菜单
-- ==============================================================

UPar.SeqHookAdd('UParExtendMenu', 'GmodLegs3Compat', function(panel)
	panel:Help('·························· GmodLegs3 ··························')
	panel:CheckBox('#upext.gmodlegs3_compat', 'upext_gmodlegs3_compat')
	panel:ControlHelp('#upext.gmodlegs3_compat.help')

	panel:CheckBox('#upext.gmodlegs3_manip', 'upext_gmodlegs3_manip')
	panel:ControlHelp('#upext.gmodlegs3_manip.help')
	local help2 = panel:ControlHelp('#upext.gmodlegs3_manip.help2')
	help2:SetTextColor(Color(255, 170, 0))

end, 1)