--[[
	作者:白狼
	2025 12 28

	此方法的使用门槛极高, 首先 ManipulateBonePosition 有距离限制, 限制为 128 个单位,
	所以如果想完成正确插值的话, 则必须在位置更新完成的那一帧, 
	所以想要完成正确插值, 最好单独加一个标志 + 回调来处理, 这样不容易导致混乱。

	由于这些函数常常在帧循环中, 加上计算略显密集 (串行), 所以很多的错误都是无声的, 这极大
	地增加了调试难度, 有点像GPU编程, 操, 所以我并不推荐使用这些。

	插值需要指定骨骼映射和其排序, GetEntBonesFamilyLevel(ent, useLRU2) 可以辅助排序,
	完成后再手动编码。

	这里的可选的插值分为两种 LerpBoneWorld 和 LerpBoneLocal
	如果从本质来看, 世界空间的插值可以看做一种特殊的局部空间插值, 只是将所有骨骼的父级都看作是 World,
	
	同时这里的 api 都是用骨骼名来指向操作的骨骼, 而不是 boneId, 这对编写、调试都有好处, 缺点是不能像
	数字索引那样高效地递归处理外部骨骼 (实体本身的父级等), 当然这里不需要, 又不是要操作机甲..., 

	所以这里也不处理实体本身, 因为一旦处理, 为了保证逻辑的一致性就必须要处理外部骨骼, 而这太低效了, 代码
	的可读性和可维护性都要差很多, 还不如自行处理, 或者以后给UPManip加个拓展,
	如果临时需要, 则在迭代器中传入自定义处理器。

--]]

local ENTITY = FindMetaTable("Entity")
local emptyTable = UPar.emptyTable
local zero = 1e-2

UPManip = UPManip or {}

local SUCC_FLAG = 0x00
local ERR_FLAG_BONEID = 0x01
local ERR_FLAG_MATRIX = 0x02
local ERR_FLAG_SINGULAR = 0x04

local ERR_FLAG_PARENT = 0x08
local ERR_FLAG_PARENT_MATRIX = 0x10
local ERR_FLAG_PARENT_SINGULAR = 0x20

local ERR_FLAG_TAR_BONEID = 0x40
local ERR_FLAG_TAR_MATRIX = 0x80
local ERR_FLAG_TAR_SINGULAR = 0x100

local ERR_FLAG_TAR_PARENT = 0x200
local ERR_FLAG_TAR_PARENT_MATRIX = 0x400
local ERR_FLAG_TAR_PARENT_SINGULAR = 0x800

local CALL_FLAG_LERP_WORLD = 0x1000
local CALL_FLAG_LERP_LOCAL = 0x2000
local CALL_FLAG_SET_POSITION = 0x4000
local CALL_FLAG_SNAPSHOT = 0x8000
local ERR_FLAG_LERP_METHOD = 0x10000

local RUNTIME_FLAG_LOG = {
	[SUCC_FLAG] = nil,
	[ERR_FLAG_BONEID] = 'can not find boneId',
	[ERR_FLAG_MATRIX] = 'can not find Matrix',
	[ERR_FLAG_SINGULAR] = 'matrix is singular',

	[ERR_FLAG_PARENT] = 'can not find parent',
	[ERR_FLAG_PARENT_MATRIX] = 'can not find parent Matrix',
	[ERR_FLAG_PARENT_SINGULAR] = 'parent matrix is singular',
	
	[ERR_FLAG_TAR_BONEID] = 'can not find tarBoneId',
	[ERR_FLAG_TAR_MATRIX] = 'can not find tarBone Matrix',
	[ERR_FLAG_TAR_SINGULAR] = 'target matrix is singular',

	[ERR_FLAG_TAR_PARENT] = 'can not find tarBone parent',
	[ERR_FLAG_TAR_PARENT_MATRIX] = 'can not find tarBone parent Matrix',
	[ERR_FLAG_TAR_PARENT_SINGULAR] = 'target parent matrix is singular',
	[CALL_FLAG_LERP_LOCAL] = 'call: lerp in world space',
	[CALL_FLAG_LERP_WORLD] = 'call: lerp in local space',
	[CALL_FLAG_SET_POSITION] = 'call: set position',
	[CALL_FLAG_SNAPSHOT] = 'call: snapshot',
	[ERR_FLAG_LERP_METHOD] = 'invalid lerp method'
}

UPManip.RUNTIME_FLAG_LOG = RUNTIME_FLAG_LOG


local function IsMatrixSingular(mat)
	-- 这个方法并不严谨, 只是工程化方案, 比直接求逆快很多
	-- 如果它底层是先算行列式的话
	local forward = mat:GetForward()
	local up = mat:GetUp()
	local right = mat:GetRight()

	return forward:LengthSqr() < zero or up:LengthSqr() < zero
	or right:LengthSqr() < zero
end

local function GetInverse(mat)
	return not IsMatrixSingular(mat) and mat:GetInverse() or nil
end

local function GetMatrixLocal(mat, parentMat, invert)
	if invert then
		if IsMatrixSingular(parentMat) then return nil end
		local matInvert = GetInverse(mat)
		if not matInvert then return nil end
		return matInvert * parentMat
	else
		if IsMatrixSingular(mat) then return nil end
		local parentMatInvert = GetInverse(parentMat)
		if not parentMatInvert then return nil end
		return parentMatInvert * mat
	end
end

UPManip.GetMatrixLocal = GetMatrixLocal
UPManip.IsMatrixSingular = IsMatrixSingular
UPManip.InitBoneIterator = function(boneIterator)
	-- 主要是验证参数类型和初始化偏移矩阵
	-- parent 和 tarParent 字段仅对局部空间插值有效

	assert(istable(boneIterator), string.format('invalid boneIterator, expect table, got %s', type(boneIterator)))
	assert(istable(boneIterator.main), string.format('invalid boneIterator.main, expect table, got %s', type(boneIterator.main)))

	for _, mappingData in pairs(boneIterator.main) do
		assert(istable(mappingData), string.format('boneIterator.main value is invalid, expect table, got %s', type(mappingData)))
		assert(isstring(mappingData.bone), string.format('field "bone" is invalid, expect string, got %s', type(mappingData.bone)))
		assert(isstring(mappingData.tarBone) or mappingData.tarBone == nil, string.format('field "tarBone" is invalid, expect (string or nil), got %s', type(mappingData.tarBone)))
		assert(isstring(mappingData.parent) or mappingData.parent == nil, string.format('field "parent" is invalid, expect (string or nil), got %s', type(mappingData.parent)))
		assert(isstring(mappingData.tarParent) or mappingData.tarParent == nil, string.format('field "tarParent" is invalid, expect (string or nil), got %s', type(mappingData.tarParent)))

		if ismatrix(mappingData.offset) then
			continue
		end

		local offsetMatrix = nil
		local offsetAng = mappingData.ang
		local offsetPos = mappingData.pos
		local offsetScale = mappingData.scale

		assert(isangle(offsetAng) or offsetAng == nil, string.format('field "ang" is invalid, expect (angle or nil), got %s', type(offsetAng)))
		assert(isvector(offsetPos) or offsetPos == nil, string.format('field "pos" is invalid, expect (vector or nil), got %s', type(offsetPos)))
		assert(isvector(offsetScale) or offsetScale == nil, string.format('field "scale" is invalid, expect (vector or nil), got %s', type(offsetScale)))

		if isangle(offsetAng) then
			offsetMatrix = offsetMatrix or Matrix()
			offsetMatrix:SetAngles(offsetAng)
		end

		if isvector(offsetPos) then
			offsetMatrix = offsetMatrix or Matrix()
			offsetMatrix:SetTranslation(offsetPos)
		end

		if isvector(offsetScale) then
			offsetMatrix = offsetMatrix or Matrix()
			offsetMatrix:SetScale(offsetScale)
		end

		if offsetMatrix then
			val.offset = offsetMatrix
		end
	end
end

local function __internal_MarkBoneFamilyLevel(boneId, currentLevel, family, familyLevel, cached)
	cached = cached or {}

	if cached[boneId] then 
		print('What the hell are you doing?')
		return
	end
	cached[boneId] = true

	familyLevel[boneId] = currentLevel

	if not family[boneId] then
		return
	end
	
	for childIdx, _ in pairs(family[boneId]) do
		__internal_MarkBoneFamilyLevel(childIdx, currentLevel + 1, family, familyLevel, cached)
	end
end

function ENTITY:UPMaGetEntBonesFamilyLevel()
	if self:GetModel() then
		print('[UPMaGetEntBonesFamilyLevel]: ent no model')
		return
	end

	ent:SetupBones()

    local boneCount = ent:GetBoneCount()
    local family = {} 
    local familyLevel = {}

    for boneIdx = 0, boneCount - 1 do
        local parentIdx = ent:GetBoneParent(boneIdx)
        
        if not family[parentIdx] then
            family[parentIdx] = {}
        end
        family[parentIdx][boneIdx] = true
    end

	if not family[-1] then
		print(string.format('[UPManip.GetEntBonesFamilyLevel]: ent "%s" no root bone', ent))
		return
	end

    __internal_MarkBoneFamilyLevel(-1, 0, family, familyLevel)

	return familyLevel
end

function ENTITY:UPMaSetBonePosition(boneName, posw, angw) 
	-- 必须传入非奇异矩阵, 如果骨骼或父级的变换是奇异的, 则可能出现问题
	-- 在调用前最好使用 ent:SetupBones(), 否则可能获得错误数据
	-- 一般放在帧循环中
	-- 应该还能再优化

	local boneId = self:LookupBone(boneName)
	if not boneId then return nil, ERR_FLAG_BONEID end
	
	local curTransform = self:GetBoneMatrix(boneId)
	if not curTransform then return nil, bit.bor(ERR_FLAG_MATRIX, CALL_FLAG_SET_POSITION) end
	
	local parentId = self:GetBoneParent(boneId)
	local parentTransform = parentId == -1 and self:GetWorldTransformMatrix() or self:GetBoneMatrix(parentId)
	if not parentTransform then return nil, bit.bor(ERR_FLAG_PARENT, CALL_FLAG_SET_POSITION) end

	local curTransformInvert = GetInverse(curTransform)
	if not curTransformInvert then return nil, bit.bor(ERR_FLAG_SINGULAR, CALL_FLAG_SET_POSITION) end

	local parentTransformInvert = GetInverse(parentTransform)
	if not parentTransformInvert then return nil, bit.bor(ERR_FLAG_PARENT_SINGULAR, CALL_FLAG_SET_POSITION) end


	local curAngManip = Matrix()
	curAngManip:SetAngles(self:GetManipulateBoneAngles(boneId))
	
	local tarRotate = Matrix()
	tarRotate:SetAngles(angw)


	local newManipAng = (curAngManip * curTransformInvert * tarRotate):GetAngles()
	local newManipPos = parentTransformInvert
		* (posw - curTransform:GetTranslation() + parentTransform:GetTranslation())
		+ self:GetManipulateBonePosition(boneId)

	self:ManipulateBoneAngles(boneId, newManipAng)
	self:ManipulateBonePosition(boneId, newManipPos)

	return SUCC_FLAG
end

function ENTITY:UPMaSnapshot(boneIterator)
	-- 默认已经初始化验证过了, 这里不再重复验证
	local main = boneIterator.main
	local snapshot = {}
	local flags = {}

	for _, mappingData in pairs(main) do
		local boneName = mappingData.bone

		local boneId = self:LookupBone(boneName)
		if not boneId then 
			flags[boneName] = bit.bor(ERR_FLAG_BONEID, CALL_FLAG_SNAPSHOT)
			continue 
		end

		local matrix = self:GetBoneMatrix(boneId)
		if not matrix then 
			flags[boneName] = bit.bor(ERR_FLAG_MATRIX, CALL_FLAG_SNAPSHOT)
			continue 
		end

		snapshot[boneName] = matrix
		flags[boneName] = SUCC_FLAG
	end
	return snapshot, flags
end

local function GetBoneMatrixFromSnapshot(boneName, snapshotOrEnt)
	-- 一般在帧循环中调用, 所以不作验证
	if istable(snapshotOrEnt) then
		return snapshotOrEnt[boneName]
	end

	local boneId = snapshotOrEnt:LookupBone(boneName)
	if not boneId then return nil end
	return snapshotOrEnt:GetBoneMatrix(boneId)
end

UPManip.GetBoneMatrixFromSnapshot = GetBoneMatrixFromSnapshot


function ENTITY:UPMaLerpBoneBatch(t, snapshot, tarSnapshotOrEnt, boneIterator)
	-- 一般在帧循环中调用, 所以不作验证
	-- 在调用前最好使用 ent:SetupBones(), 否则可能获得错误数据
	-- 每帧都要更新

	local main = boneIterator.main
	local resultBatch = {}
	local flags = {}

	for _, boneName in ipairs(keySort) do
		local mappingData = main[boneName]

		local boneName = mappingData.bone
		local tarBoneName = mappingData.tarBone or boneName
		local offsetMatrix = mappingData.offset
		local lerpMethod = mappingData.lerpMethod or CALL_FLAG_LERP_LOCAL
		local parentId = self:GetBoneParent(boneId)

		-- 根节点只能使用世界空间插值
		lerpMethod = parentId == -1 and CALL_FLAG_LERP_WORLD or lerpMethod


		local initMatrix = GetBoneMatrixFromSnapshot(boneName, snapshot or self)
		if not initMatrix then 
			flags[boneName] = bit.bor(ERR_FLAG_MATRIX, lerpMethod)
			continue
		end

		local finalMatrix = GetBoneMatrixFromSnapshot(tarBoneName, tarEntOrSnapshot)
		if not finalMatrix then 
			flags[boneName] = bit.bor(ERR_FLAG_TAR_BONEID, lerpMethod)
			continue
		end
		
		if lerpMethod == CALL_FLAG_LERP_WORLD then
			finalMatrix = offsetMatrix and finalMatrix * offsetMatrix or finalMatrix
			resultBatch[boneName] = {
				LerpVector(t, initMatrix:GetTranslation(), finalMatrix:GetTranslation()),
				LerpAngle(t, initMatrix:GetAngles(), finalMatrix:GetAngles()),
				LerpVector(t, initMatrix:GetScale(), finalMatrix:GetScale()), 
			}
			flags[boneName] = SUCC_FLAG

		elseif lerpMethod == CALL_FLAG_LERP_LOCAL then
			local parentName = mappingData.parent
			local tarParentName = mappingData.tarParent or parentName

			local parentMatrix = GetBoneMatrixFromSnapshot(parentName, snapshot or self)
			if not parentMatrix then 
				flags[boneName] = bit.bor(ERR_FLAG_PARENT_MATRIX, lerpMethod)
				continue 
			end

			local tarParentMatrix = GetBoneMatrixFromSnapshot(tarParentName, tarEntOrSnapshot)
			if not tarParentMatrix then 
				flags[boneName] = bit.bor(ERR_FLAG_TAR_PARENT_MATRIX, lerpMethod)
				continue 
			end

			if not IsMatrixSingular(parentMatrix) then 
				flags[boneName] = bit.bor(ERR_FLAG_PARENT_SINGULAR, lerpMethod)
				continue 
			end

			local tarParentMatrixInvert = GetInverse(tarParentMatrix)
			if not tarParentMatrixInvert then 
				flags[boneName] = bit.bor(ERR_FLAG_TAR_PARENT_SINGULAR, lerpMethod)
				continue 
			end

			finalMatrix = parentMatrix * tarParentMatrixInvert * finalMatrix
			finalMatrix = offsetMatrix and finalMatrix * offsetMatrix or finalMatrix

			resultBatch[boneName] = {
				LerpVector(t, initMatrix:GetTranslation(), finalMatrix:GetTranslation()),
				LerpAngle(t, initMatrix:GetAngles(), finalMatrix:GetAngles()),
				LerpVector(t, initMatrix:GetScale(), finalMatrix:GetScale()), 
			}
			
			flags[boneName] = SUCC_FLAG
		else
			flags[boneName] = ERR_FLAG_LERP_METHOD
			continue
		end
	end

	return resultBatch, flags
end

concommand.Add('upmanip_test_world', function(ply)
	local pos = ply:GetPos()
	pos = pos + UPar.XYNormal(ply:GetAimVector()) * 100

	local mossman = ClientsideModel('models/mossman.mdl', RENDERGROUP_OTHER)
	local mossman2 = ClientsideModel('models/mossman.mdl', RENDERGROUP_OTHER)

	mossman:SetPos(pos)
	mossman2:SetPos(pos)

	local boneIterator = {
		main = {
			{
				bone = 'ValveBiped.Bip01_Head1',
				ang = Angle(90, 0, 0),
				scale = Vector(2, 2, 2)
			}
		}
	}
	UPManip.InitBoneIteratorOffset(boneIterator)

	mossman:SetupBones()
	mossman2:SetupBones()

	local ang = 0
	timer.Create('upmanip_test_world', 0, 0, function()
		mossman2:SetPos(pos + Vector(math.cos(ang) * 100, math.sin(ang) * 100, 0))
		mossman2:SetupBones()
		mossman:SetupBones()

		UPManip.LerpBoneWorldByMapping(0.1, mossman, mossman2, boneIterator, true)
		
		ang = ang + FrameTime()
	end)

	timer.Simple(5, function()
		timer.Remove('upmanip_test_world')
		if IsValid(mossman) then mossman:Remove() end
		if IsValid(mossman2) then mossman2:Remove() end
	end)
end)

concommand.Add('upmanip_test_local', function(ply)
	local pos = ply:GetPos()
	pos = pos + UPar.XYNormal(ply:GetAimVector()) * 100

	local pos2 = pos + Vector(0, 100, 0)

	local mossman = ClientsideModel('models/mossman.mdl', RENDERGROUP_OTHER)
	local mossman2 = ClientsideModel('models/gman_high.mdl', RENDERGROUP_OTHER)

	mossman:SetPos(pos)
	
	mossman2:SetPos(pos2)
	mossman2:ResetSequenceInfo()
	mossman2:SetPlaybackRate(1)
	mossman2:ResetSequence(mossman2:LookupSequence('crouch_reload_pistol'))


	local boneIterator = {
		main = {
			{
				bone = 'ValveBiped.Bip01_Spine',
				tarBone = 'ValveBiped.Bip01_Spine',

				parent = 'ValveBiped.Bip01_Spine',
				tarParent = 'ValveBiped.Bip01_Spine',

				angOffset = Angle(90, 0, 0),
				posOffset = Vector(0, 0, 10),
				scale = Vector(0.5, 0.5, 0.5),
			}


			['ValveBiped.Bip01_Spine'] = true,
			['ValveBiped.Bip01_Spine1'] = true,
			['ValveBiped.Bip01_Spine2'] = true,
			['ValveBiped.Bip01_L_Clavicle'] = true,
			['ValveBiped.Bip01_L_UpperArm'] = true,
			['ValveBiped.Bip01_L_Forearm'] = true,
			['ValveBiped.Bip01_L_Hand'] = true,
			['ValveBiped.Bip01_R_Clavicle'] = true,
			['ValveBiped.Bip01_R_UpperArm'] = true,
			['ValveBiped.Bip01_R_Forearm'] = true,
			['ValveBiped.Bip01_R_Hand'] = true,
			['ValveBiped.Bip01_Neck1'] = true,
			['ValveBiped.Bip01_Head1'] = {
				ang = Angle(90, 0, 0),
				scale = Vector(2, 2, 2)
			},
		},
		keySort = {
			'ValveBiped.Bip01_Spine',
			'ValveBiped.Bip01_Spine1',
			'ValveBiped.Bip01_Spine2',
			'ValveBiped.Bip01_L_Clavicle',
			'ValveBiped.Bip01_L_UpperArm',
			'ValveBiped.Bip01_L_Forearm',
			'ValveBiped.Bip01_L_Hand',
			'ValveBiped.Bip01_R_Clavicle',
			'ValveBiped.Bip01_R_UpperArm',
			'ValveBiped.Bip01_R_Forearm',
			'ValveBiped.Bip01_R_Hand',
			'ValveBiped.Bip01_Neck1',
			'ValveBiped.Bip01_Head1',
		},
	}

	
	UPManip.InitBoneIteratorOffset(boneIterator)

	mossman:SetupBones()
	mossman2:SetupBones()

	local ang = 0
	timer.Create('upmanip_test_local', 0, 0, function()
		mossman2:SetCycle((mossman2:GetCycle() + FrameTime()) % 1)
		mossman2:SetupBones()

		mossman:SetupBones()
		UPManip.LerpBoneLocalByMapping(1, mossman, mossman2, boneIterator, true)
		
		ang = ang + FrameTime()
	end)
		
	timer.Simple(5, function()
		timer.Remove('upmanip_test_local')
		if IsValid(mossman) then mossman:Remove() end
		if IsValid(mossman2) then mossman2:Remove() end
	end)
end)
