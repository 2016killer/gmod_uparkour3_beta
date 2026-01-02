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

	这里的插值分为两种 LerpBoneWorld 和 LerpBoneLocal
	如果从本质来看, 世界空间的插值可以看做一种特殊的局部空间插值, 只是将所有骨骼的父级都看作是 World,
	同时这里的 api 都是用骨骼名来指向操作的骨骼, 而不是 boneId, 这样的好处就是我可以将骨骼操纵拓展到
	操作实体本身, 我们用 'self' 来表示实体本身, 同时我们还能将 'self' 映射到另一个实体的骨骼上来实现
	骨架嫁接。 

	关于操纵与获取
	这里开放的其他底层包括 GetBoneMatrixLocal, GetBoneMatrix, SetBonePositionLocal, SetBonePosition
	因为操纵是通过 ManipulateBonexxx 来实现的, 所以 SetBonePosition 和 GetBoneMatrix 有着必然的耦合。 (除了 'self')
--]]


local emptyTable = UPar.emptyTable
local zero = 1e-2

UPManip = UPManip or {}

local function Log(msg, silentlog)
	if not silentlog then print(msg) end
end

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

local function GetBoneMatrix(ent, boneName)
	if boneName == 'self' then
		return ent:GetWorldTransformMatrix()
	end

	local boneId = ent:LookupBone(boneName)
	if not boneId then return nil end
	return ent:GetBoneMatrix(boneId), boneId
end

local function SetBonePosition(ent, boneName, posw, angw, silentlog) 
	-- 必须传入非奇异矩阵, 如果骨骼或父级的变换是奇异的, 则可能出现问题
	-- 在调用前最好使用 ent:SetupBones(), 否则可能获得错误数据
	-- 每帧都要更新
	-- 应该还能再优化

	if boneName == 'self' then
		ent:SetPos(posw)
		ent:SetAngles(angw)
		return posw, angw
	end

	local curTransform, boneId = GetBoneMatrix(ent, boneName)
	if not curTransform then 
		Log(string.format('[UPManip.SetBonePosition]: ent "%s" boneName "%s" no Matrix', ent, boneName), silentlog)
		return nil
	end
	
	local parentId = ent:GetBoneParent(boneId)
	local parentTransform = parentId == -1 and ent:GetWorldTransformMatrix() or ent:GetBoneMatrix(parentId)
	if not parentTransform then 
		Log(string.format('[UPManip.SetBonePosition]: ent "%s" boneName "%s" no parent', ent, boneName), silentlog)
		return nil
	end

	local curTransformInvert = GetInverse(curTransform)
	if not curTransformInvert then 
		Log(string.format('[UPManip.SetBonePosition]: ent "%s" boneName "%s" Matrix is Singular', ent, boneName), silentlog)
		return nil
	end

	local parentTransformInvert = GetInverse(parentTransform)
	if not parentTransformInvert then 
		Log(string.format('[UPManip.SetBonePosition]: ent "%s" boneName "%s" parent Matrix is Singular', ent, boneName), silentlog)
		return nil
	end


	local curAngManip = Matrix()
	curAngManip:SetAngles(ent:GetManipulateBoneAngles(boneId))
	
	local tarRotate = Matrix()
	tarRotate:SetAngles(angw)


	local newManipAng = (curAngManip * curTransformInvert * tarRotate):GetAngles()
	local newManipPos = parentTransformInvert
		* (posw - curTransform:GetTranslation() + parentTransform:GetTranslation())
		+ ent:GetManipulateBonePosition(boneId)

	ent:ManipulateBoneAngles(boneId, newManipAng)
	ent:ManipulateBonePosition(boneId, newManipPos)

	return newManipAng, newManipPos
end

local function GetBoneMatrixLocal(ent, boneName, parentName, invert)
	-- 这里 parentName 参数是为插值而设计的, 因为 ent 骨骼映射到不同的实体上时, 父级可能会不同

	-- 在这里, 我们将实体本身的父级视为 World
	if boneName == 'self' then 
		return ent:GetWorldTransformMatrix() 
	end

	local boneId = ent:LookupBone(boneName)
	if not boneId then return nil end
	local boneMatrix = ent:GetBoneMatrix(boneId)
	if not boneMatrix then return nil end

	local parentId = nil
	if parentName then
		parentId = parentName == 'self' and -1 or ent:LookupBone(parentName)
	else
		parentId = ent:GetBoneParent(boneId)
	end

	local parentMatrix = parentId == -1 and ent:GetWorldTransformMatrix() or ent:GetBoneMatrix(parentId)
	if not parentMatrix then return nil end

	if invert then
		if IsMatrixSingular(parentMatrix) then return nil end
		local boneMatrixInvert = GetInverse(boneMatrix)
		if not boneMatrixInvert then return nil end
		return boneMatrixInvert * parentMatrix, parentId
	else
		if IsMatrixSingular(boneMatrix) then return nil end
		local parentMatrixInvert = GetInverse(parentMatrix)
		if not parentMatrixInvert then return nil end
		return parentMatrixInvert * boneMatrix, boneId, parentId
	end
end

local function SetBonePositionLocal(ent, boneName, posl, angl, silentlog) 
	-- 必须传入非奇异矩阵, 如果骨骼或父级的变换是奇异的, 则可能出现问题
	-- 在调用前最好使用 ent:SetupBones(), 否则可能获得错误数据
	-- 每帧都要更新
	-- 应该还能再优化

	-- 在这里, 我们将实体本身的父级视为 World
	if boneName == 'self' then
		ent:SetPos(posl)
		ent:SetAngles(angl)
		return posl, angl
	end
	
	local curLocalTransformInvert, boneId, parentId = GetBoneMatrixLocal(ent, boneName, nil, true)
	if not curLocalTransformInvert then 
		Log(string.format('[UPManip.SetBonePositionLocal]: ent "%s" boneName "%s" GetBoneMatrixLocal failed', ent, boneName), silentlog)
		return nil 
	end

	local curAngManip = Matrix()
	curAngManip:SetAngles(ent:GetManipulateBoneAngles(boneId))
	
	local curPosManip = Matrix()
	curPosManip:SetTranslation(ent:GetManipulateBonePosition(boneId))

	local tarMat = Matrix()
	tarMat:SetAngles(angl)
	tarMat:SetTranslation(posl)


	local newAngManip = curAngManip * curLocalTransformInvert * tarMat
	local newPosManip = tarMat * curLocalTransformInvert * curPosManip

	local newManipAng = newAngManip:GetAngles()
	local newManipPos = newPosManip:GetTranslation()


	ent:ManipulateBoneAngles(boneId, newManipAng)
	ent:ManipulateBonePosition(boneId, newManipPos)

	return newManipAng, newManipPos
end

local function MarkBoneFamilyLevel(boneId, currentLevel, family, familyLevel, cached)
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
		MarkBoneFamilyLevel(childIdx, currentLevel + 1, family, familyLevel, cached)
	end
end

local function GetEntBonesFamilyLevel(ent, useLRU2)
	if not isentity(ent) or not IsValid(ent) or not ent:GetModel() then
		print(string.format('[UPManip.GetEntBonesFamilyLevel]: invaild ent "%s"', ent))
		return
	end

	if useLRU2 then
		local bonesLevel = UPar.LRU2Get(string.format('BonesFamilyLevel_%s', ent:GetModel()))
		if istable(bonesLevel) then
			return bonesLevel
		end
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

    MarkBoneFamilyLevel(-1, 0, family, familyLevel)

	if useLRU2 then
		UPar.LRU2Set(string.format('BonesFamilyLevel_%s', ent:GetModel()), familyLevel)
	end

	return familyLevel
end

local function LerpBoneWorld(t, ent, tarEnt, boneName, tarBoneName, offsetMatrix, silentlog)
	-- 不传入 tarBoneName 则使用恒等映射
	-- 在调用前最好使用 ent:SetupBones(), 否则可能获得错误数据
	-- 每帧都要更新

	local curMatrix, boneId = GetBoneMatrix(ent, boneName)
	if not curMatrix then 
		Log(string.format('[UPManip.LerpBoneWorld]: can not find curMatrix, boneName: "%s", ent "%s"', boneName, ent), silentlog)
		return nil
	end

	tarBoneName = tarBoneName or boneName
	local tarMatrix = GetBoneMatrix(tarEnt, tarBoneName)
	if not tarMatrix then 
		Log(string.format('[UPManip.LerpBoneWorld]: can not find tarMatrix, tarBoneName: "%s", tarEnt "%s"', tarBoneName, tarEnt), silentlog)
		return nil
	end

	tarMatrix = offsetMatrix and tarMatrix * offsetMatrix or tarMatrix

	local newPos = LerpVector(t, curMatrix:GetTranslation(), tarMatrix:GetTranslation())
	local newAng = LerpAngle(t, curMatrix:GetAngles(), tarMatrix:GetAngles())
	local newScale = LerpVector(t, curMatrix:GetScale(), tarMatrix:GetScale())

	ent:ManipulateBoneScale(boneId, newScale)
	return SetBonePosition(ent, boneName, newPos, newAng, silentlog)
end

local function LerpBoneLocal(t, ent, tarEnt, boneName, tarBoneName, parentName, tarParentName, offsetMatrix, silentlog)
	-- 在调用前最好使用 ent:SetupBones(), 否则可能获得错误数据
	-- 每帧都要更新

	local curMatrixLocal, boneId = GetBoneMatrixLocal(ent, boneName, parentName)
	if not curMatrixLocal then
		Log(string.format('[UPManip.LerpBoneLocal]: get local matrix failed, boneName: "%s", ent "%s"', boneName, ent), silentlog)
		return nil
	end

	tarBoneName = tarBoneName or boneName
	tarParentName = tarParentName or parentName
	local tarMatrixLocal = GetBoneMatrixLocal(tarEnt, tarBoneName, tarParentName)
	if not tarMatrixLocal then 
		Log(string.format('[UPManip.LerpBoneLocal]: fail to get targetBoneMatrix, boneName: "%s", target "%s"', tarBoneName, tarEnt), silentlog)
		return nil
	end
		
	tarMatrixLocal = offsetMatrix and tarMatrixLocal * offsetMatrix or tarMatrixLocal

	local newPos = LerpVector(t, curMatrixLocal:GetTranslation(), tarMatrixLocal:GetTranslation())
	local newAng = LerpAngle(t, curMatrixLocal:GetAngles(), tarMatrixLocal:GetAngles())
	local newScale = LerpVector(t, curMatrixLocal:GetScale(), tarMatrixLocal:GetScale())

	ent:ManipulateBoneScale(boneId, newScale)
	return SetBonePositionLocal(ent, boneName, newPos, newAng, silentlog)
end

UPManip.GetBoneMatrix = GetBoneMatrix
UPManip.GetBoneMatrixLocal = GetBoneMatrixLocal
UPManip.SetBonePosition = SetBonePosition
UPManip.SetBonePositionLocal = SetBonePositionLocal
UPManip.GetEntBonesFamilyLevel = GetEntBonesFamilyLevel
UPManip.IsMatrixSingular = IsMatrixSingular
UPManip.LerpBoneWorld = LerpBoneWorld
UPManip.LerpBoneLocal = LerpBoneLocal

UPManip.InitBoneMappingOffset = function(boneMapping)
	-- 主要是验证参数类型和初始化偏移矩阵
	-- custParent 和 tarParent 字段仅对局部空间插值有效
	-- 如果指定了 custParent 最好也指定 tarParent, 否则 tarParent 默认为 custParent

	assert(istable(boneMapping), string.format('invalid boneMapping, expect table, got %s', type(boneMapping)))
	assert(istable(boneMapping.main), string.format('invalid boneMapping.main, expect table, got %s', type(boneMapping.main)))
	assert(istable(boneMapping.keySort), string.format('invalid boneMapping.keySort, expect table, got %s', type(boneMapping.keySort)))

	for key, val in pairs(boneMapping.main) do
		assert(isstring(key), string.format('boneMapping.main key is invalid, expect string, got %s', type(key)))
		assert(istable(val) or val == true, string.format('boneMapping.main value is invalid, expect (table or true), got %s', type(val)))

		if val == true or ismatrix(val.offset) then
			continue
		end

		local offsetMatrix = nil
		local offsetAng = val.ang
		local offsetPos = val.pos
		local offsetScale = val.scale
		local customParent = val.custParent
		local targetBoneName = val.tarBone
		local targetParentName = val.tarParent

		assert(isstring(customParent) or customParent == nil, string.format('field "custParent" is invalid, expect (string or nil), got %s', type(customParent)))
		assert(isstring(targetBoneName) or targetBoneName == nil, string.format('field "tarBone" is invalid, expect (string or nil), got %s', type(targetBoneName)))
		assert(isstring(targetParentName) or targetParentName == nil, string.format('field "tarParent" is invalid, expect (string or nil), got %s', type(targetParentName)))
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

UPManip.LerpBoneWorldByMapping = function(t, ent, tarEnt, boneMapping, silentlog)
	-- 在调用前最好使用 ent:SetupBones(), 否则可能获得错误数据
	-- 每帧都要更新

	local main = boneMapping.main
	local keySort = boneMapping.keySort
	for _, boneName in ipairs(keySort) do
		local val = main[boneName]
		if istable(val) then
			LerpBoneWorld(t, ent, tarEnt, 
				boneName, val.tarBone, 
			val.offset, silentlog)
		else
			LerpBoneWorld(t, ent, tarEnt, 
				boneName, nil, 
			nil, silentlog)
		end
	end
end

UPManip.LerpBoneLocalByMapping = function(t, ent, tarEnt, boneMapping, silentlog)
	-- 在调用前最好使用 ent:SetupBones(), 否则可能获得错误数据
	-- 每帧都要更新

	local main = boneMapping.main
	local keySort = boneMapping.keySort
	for _, boneName in ipairs(keySort) do
		local val = main[boneName]

		if istable(val) then
			LerpBoneLocal(t, ent, tarEnt, 
				boneName, val.tarBone, 
				val.custParent, val.tarParent, 
				val.offset, 
			silentlog)
		else
			LerpBoneLocal(t, ent, tarEnt, 
				boneName, nil, 
				nil, nil, 
				nil, 
			silentlog)
		end
	end
end


concommand.Add('upmanip_test', function(ply)
	local pos = ply:GetPos()
	pos = pos + UPar.XYNormal(ply:GetAimVector()) * 100

	local mossman = ClientsideModel('models/mossman.mdl', RENDERGROUP_OTHER)
	local mossman2 = ClientsideModel('models/mossman.mdl', RENDERGROUP_OTHER)

	mossman:SetPos(pos)
	mossman2:SetPos(pos)

	local boneMapping = {
		main = {
			['self'] = {ang = Angle(90, 0, 0)},
			['ValveBiped.Bip01_Head1'] = {ang = Angle(90, 0, 0)}
		},
		keySort = {
			'self', 
			'ValveBiped.Bip01_Head1'
		},
	}
	UPManip.InitBoneMappingOffset(boneMapping)

	mossman:SetupBones()
	mossman2:SetupBones()

	local ang = 0
	timer.Create('upmanip_test', 0, 0, function()
		mossman2:SetPos(pos + Vector(math.cos(ang) * 100, math.sin(ang) * 100, 0))
		mossman2:SetupBones()
		mossman:SetupBones()

		UPManip.LerpBoneWorldByMapping(0.1, mossman, mossman2, boneMapping)
		
		ang = ang + FrameTime()
	end)

	timer.Simple(5, function()
		timer.Remove('upmanip_test')
		if IsValid(mossman) then mossman:Remove() end
		if IsValid(mossman2) then mossman2:Remove() end
	end)
end)

