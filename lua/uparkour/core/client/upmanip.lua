--[[
	作者:白狼
	2025 12 28

	此方法的使用门槛极高, 首先 ManipulateBonePosition 有距离限制, 限制为 128 个单位,
	所以如果想完成正确插值的话, 则必须在位置更新完成的那一帧, 
	所以想要完成正确插值, 最好单独加一个标志 + 回调来处理, 这样不容易导致混乱。

	由于这些函数常常在帧循环中, 加上计算略显密集, 所以很多的错误都是无声的, 这极大
	地增加了调试难度, 有点像GPU编程, 操, 所以我并不推荐使用这些。

	插值需要指定骨骼映射和其排序, GetEntBonesFamilyLevel(ent, useLRU2) 可以辅助排序,
	完成后再手动编码。
--]]


local emptyTable = UPar.emptyTable

UPManip = UPManip or {}

local function Log(msg, silentlog)
	if not silentlog then print(msg) end
end

local function SetBonePosition(ent, boneId, posw, angw, silentlog) 
	-- 最好传入非奇异矩阵, 如果骨骼或父级的变换是奇异的, 则可能出现问题
	-- 在调用前最好使用 ent:SetupBones(), 否则可能获得错误数据
	-- 每帧都要更新
	-- 应该还能再优化

	if not isentity(ent) or not IsValid(ent) then
		Log(string.format('[UPManip.SetBonePosition]: invaild ent "%s"', ent), silentlog)
		return
	end
	
	if boneId == -1 then
		Log('[UPManip.SetBonePosition]: invalid boneId "-1"', silentlog)
		return false
	end
	
	local curTransform = ent:GetBoneMatrix(boneId)
	if not curTransform then 
		Log(string.format('[UPManip.SetBonePosition]: ent "%s" boneId "%s" no Matrix', ent, boneId), silentlog)
		return false
	end
	
	local parentboneId = ent:GetBoneParent(boneId)
	local parentTransform = parentboneId == -1 and ent:GetWorldTransformMatrix() or ent:GetBoneMatrix(parentboneId)
	if not parentTransform then 
		Log(string.format('[UPManip.SetBonePosition]: ent "%s" boneId "%s" no parent', ent, boneId), silentlog)
		return false
	end

	local curTransformInvert = curTransform:GetInverse()
	if not curTransformInvert then 
		Log(string.format('[UPManip.SetBonePosition]: ent "%s" boneId "%s" Matrix is Singular', ent, boneId), silentlog)
		return false
	end

	local parentTransformInvert = parentTransform:GetInverse()
	if not parentTransformInvert then 
		Log(string.format('[UPManip.SetBonePosition]: ent "%s" boneId "%s" parent Matrix is Singular', ent, boneId), silentlog)
		return false
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

UPManip.InitBoneMappingOffset = function(boneMapping)
	-- 主要是验证参数类型和初始化偏移矩阵
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
		local targetBoneName = val.boneName

		assert(isstring(targetBoneName) or targetBoneName == nil, string.format('boneName is invalid, expect (string or nil), got %s', type(targetBoneName)))
		assert(isangle(offsetAng) or offsetAng == nil, string.format('ang is invalid, expect (angle or nil), got %s', type(offsetAng)))
		assert(isvector(offsetPos) or offsetPos == nil, string.format('pos is invalid, expect (vector or nil), got %s', type(offsetPos)))
		assert(isvector(offsetScale) or offsetScale == nil, string.format('scale is invalid, expect (vector or nil), got %s', type(offsetScale)))

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

UPManip.SetBonePosition = SetBonePosition
UPManip.UnpackBMData = UnpackBMData
UPManip.GetEntBonesFamilyLevel = GetEntBonesFamilyLevel
UPManip.LerpBoneWorld = function(t, ent, target, boneMapping, silentlog)
	-- 在调用前最好使用 ent:SetupBones(), 否则可能获得错误数据
	-- 每帧都要更新
	local main = boneMapping.main
	local keySort = boneMapping.keySort
 
	if main['self'] then
		local offsetMatrix = istable(main['self']) and main['self'].offset or nil
		local targetMatrix = offsetMatrix and target:GetWorldTransformMatrix() * offsetMatrix or target:GetWorldTransformMatrix()
		local pos, ang = targetMatrix:GetTranslation(), targetMatrix:GetAngles()
		ent:SetPos(LerpVector(t, ent:GetPos(), pos))
		ent:SetAngles(LerpAngle(t, ent:GetAngles(), ang))
	end

	for _, boneName in ipairs(keySort) do
		if boneName == 'self' then
			continue
		end

		local mappingData = main[boneName]
		local boneId = ent:LookupBone(boneName)
		
		if not boneId or not mappingData then 
			Log(string.format('[UPManip.LerpBoneWorld]: can not find (boneId or mappingData), boneName: "%s", ent "%s"', boneName, ent), silentlog)
			continue
		end

		local initMatrix = ent:GetBoneMatrix(boneId)
		if not initMatrix then 
			Log(string.format('[UPManip.LerpBoneWorld]: fail to get boneMatrix, boneName: "%s", ent "%s"', boneName, ent), silentlog)
			continue
		end

		local targetBoneName = istable(mappingData) and (mappingData.boneName or boneName) or boneName
		local targetBoneId = target:LookupBone(targetBoneName)

		if not targetBoneId then 
			Log(string.format('[UPManip.LerpBoneWorld]: can not find targetBoneId, boneName: "%s", target "%s"', targetBoneName, target), silentlog)
			continue 
		end

		local finalMatrix = target:GetBoneMatrix(targetBoneId)
		if not finalMatrix then 
			Log(string.format('[UPManip.LerpBoneWorld]: fail to get targetBoneMatrix, boneName: "%s", target "%s"', targetBoneName, target), silentlog)
			continue
		end
			
		local offsetMatrix = istable(mappingData) and mappingData.offset or nil

		finalMatrix = offsetMatrix and finalMatrix * offsetMatrix or finalMatrix

		local newPos = LerpVector(t, initMatrix:GetTranslation(), finalMatrix:GetTranslation())
		local newAng = LerpAngle(t, initMatrix:GetAngles(), finalMatrix:GetAngles())
		local newScale = LerpVector(t, initMatrix:GetScale(), finalMatrix:GetScale())

		ent:ManipulateBoneScale(boneId, newScale)
		SetBonePosition(ent, boneId, newPos, newAng, silentlog)
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

		UPManip.LerpBoneWorld(0.1, mossman, mossman2, boneMapping)
		
		ang = ang + FrameTime()
	end)

	timer.Simple(5, function()
		timer.Remove('upmanip_test')
		if IsValid(mossman) then mossman:Remove() end
		if IsValid(mossman2) then mossman2:Remove() end
	end)
end)

