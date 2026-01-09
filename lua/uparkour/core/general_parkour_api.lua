--[[
	作者:白狼
	2025 12 26

	通用障碍检测, 作为略微底层的函数, 不对输入类型进行检查, 仅对关键边界进行检查
--]]
local unitzvec = UPar.unitzvec

local function XYNormal(v)
	v = Vector(v)
	v[3] = 0
	v:Normalize()
	return v
end

local SAFE_OFFSET_H = 2
local SAFE_OFFSET_V = 1
local LANDSLID_ZNORM = 0.707
local CONT_OBS_MAXH_DELTA = math.Clamp(0.1, 0, 1)

UPar.XYNormal = XYNormal

UPar.ObsDetector = function(ply, pos, dirNorm, ohlenFrac, minhFrac, maxhFrac, loscos)
	-- 获取障碍位置
	-- pos 检测位置
	-- dirNorm 检测路径方向 (单位)
	-- minhFrac, maxhFrac 碰撞盒高度 比例 (玩家高度)
	-- loscos 视线余弦值

	if maxhFrac < minhFrac then
		print('[ObsDetector]: Warning: maxhFrac < minhFrac')
		return
	end

	dirNorm = XYNormal(dirNorm)

	local mins, maxs = ply:GetCollisionBounds()
	local plyWidth = math.max(maxs[1] - mins[1], maxs[2] - mins[2])
	local plyHeight = maxs[3] - mins[3]
	local ohlen = math.abs(ohlenFrac * plyHeight)

	maxs[3] = maxhFrac * plyHeight
	mins[3] = minhFrac * plyHeight

	local obsTrace = util.TraceHull({
		filter = ply, 
		mask = MASK_PLAYERSOLID,
		start = pos,
		endpos = pos + dirNorm * ohlen,
		mins = mins,
		maxs = maxs
	})

	UPar.debugwireframebox(obsTrace.HitPos, mins, maxs, 3, 
		obsTrace.Hit and Color(255, 0, 0) or Color(0, 255, 0), 
		true)

	if not obsTrace.Hit or obsTrace.HitNormal[3] >= LANDSLID_ZNORM then
		return
	end

	if isnumber(loscos) and XYNormal(-obsTrace.HitNormal):Dot(dirNorm) < loscos then 
		return 
	end

	if SERVER and IsValid(obsTrace.Entity) and obsTrace.Entity:IsPlayerHolding() then
		return
	end

	table.Merge(obsTrace, {
		mins = mins,
		maxs = maxs,
		// used = dir:Dot(obsTrace.Normal) * obsTrace.Fraction,
		used = obsTrace.Fraction * ohlen,
		loscos = loscos,
		plyw = plyWidth,
		plyh = plyHeight,
		Normal = dirNorm,
	})

	return obsTrace
end

UPar.ClimbDetector = function(ply, obsTrace, ehlenFrac)
	-- obsTrace 障碍检测结果
	-- ehlenFrac 水平检测路径距离 比例 (玩家高度)

	local pos = obsTrace.StartPos
	local obsPos = obsTrace.HitPos
	local maxh = obsTrace.maxs[3]
	local minh = obsTrace.mins[3]
	local dirNorm = obsTrace.Normal
	local plyHeight = obsTrace.plyh

	-- 确保落脚点有足够空间, 所以检测蹲碰撞盒
	local evlen = maxh - minh
	local dmins, dmaxs = ply:GetHullDuck()

	local startpos = obsPos + Vector(0, 0, maxh) + math.abs(ehlenFrac * plyHeight) * dirNorm
	local endpos = startpos - Vector(0, 0, evlen)

	local climbTrace = util.TraceHull({
		filter = ply, 
		mask = MASK_PLAYERSOLID,
		start = startpos,
		endpos = endpos,
		mins = dmins,
		maxs = dmaxs,
	})

	UPar.debugwireframebox(climbTrace.StartPos, dmins, dmaxs, 3, nil, true)
	UPar.debugwireframebox(climbTrace.HitPos, dmins, dmaxs, 3, Color(0, 255, 255), true)

	-- 确保不在滑坡上且在障碍物上
	if not climbTrace.Hit or climbTrace.HitNormal[3] < LANDSLID_ZNORM then
		return
	end

	-- 检测落脚点是否有足够空间
	-- OK, 预留1的单位高度防止极端情况
	local used = climbTrace.Fraction * evlen

	if climbTrace.StartSolid or used < SAFE_OFFSET_V then
		return
	end

	table.Merge(climbTrace, {
		mins = dmins,
		maxs = dmaxs,
		used = used
	})

	return climbTrace
end

UPar.IsInSolid = function(ply, startpos, cur)
	local pmins, pmaxs = nil
	if cur then
		pmins, pmaxs = ply:GetCollisionBounds()
	else
		pmins, pmaxs = ply:GetHull()
	end

	startpos = isvector(startpos) and startpos or ply:GetPos()

	local solidTrace = util.TraceHull({
		filter = ply, 
		mask = MASK_PLAYERSOLID,
		start = startpos,
		endpos = startpos,
		mins = pmins,
		maxs = pmaxs,
	})
	
	UPar.debugwireframebox(startpos, pmins, pmaxs, 3, 
		(solidTrace.StartSolid or solidTrace.Hit) and Color(255, 0, 0) or Color(0, 255, 0), 
		true)

	return solidTrace.StartSolid or solidTrace.Hit 
end

UPar.VaultDetector = function(ply, obsTrace, climbTrace, ehlenFrac, evlenFrac)
	-- obsTrace 障碍检测结果
	-- climbTrace 攀爬检测结果
	-- ehlenFrac 水平检测路径距离 比例 (玩家高度)
	-- evlenFrac 垂直检测路径距离 比例 (玩家高度)
	
	-- 翻越的条件为可攀爬且障碍的镜像满足一定条件, 实际上是做一次镜像 obs 检测 + 垂直定位
	-- 镜像 obs 检测时, 障碍最大的高度变化为 CONT_OBS_MAXH_DELTA, 超过部分则不视为障碍的一部分

	local plyHeight = obsTrace.plyh
	local plyWidth = obsTrace.plyw
	local dirNorm = obsTrace.Normal
	local landpos = climbTrace.HitPos
	local dmins, dmaxs = climbTrace.mins, climbTrace.maxs

	-- 简单检测一下是否会被阻挡 0.707 = 2^0.5 * 0.5
	local ehlen = math.abs(ehlenFrac * plyHeight)

	local linelen = ehlen + 0.707 * plyWidth
	local line = dirNorm * linelen
	
	local simpletrace1 = util.QuickTrace(landpos + Vector(0, 0, dmaxs[3]), line, ply)
	local simpletrace2 = util.QuickTrace(landpos + Vector(0, 0, dmaxs[3] * 0.5), line, ply)
	
	debugoverlay.Line(
		landpos + Vector(0, 0, dmaxs[3]), 
		landpos + Vector(0, 0, dmaxs[3]) + line, 
		3, nil, true)

	debugoverlay.Line(
		landpos + Vector(0, 0, dmaxs[3] * 0.5), 
		landpos + Vector(0, 0, dmaxs[3] * 0.5) + line, 
		3, nil, true)

	if simpletrace1.StartSolid or simpletrace2.StartSolid then
		return
	end

	-- 更新水平检测范围
	local maxVaultWidth, maxVaultWidthVec
	if simpletrace1.Hit or simpletrace2.Hit then
		maxVaultWidth = math.max(0, linelen * math.min(simpletrace1.Fraction, simpletrace2.Fraction) - plyWidth * 0.707)
		maxVaultWidthVec = dirNorm * maxVaultWidth
	else
		maxVaultWidth = ehlen
		maxVaultWidthVec = dirNorm * maxVaultWidth
	end
 
	local oimins, oimaxs = Vector(obsTrace.mins), Vector(obsTrace.maxs)
	oimins[3] = oimins[3] * (1 - CONT_OBS_MAXH_DELTA)
 
	local obsImgTrace = util.TraceHull({
		filter = ply, 
		mask = MASK_PLAYERSOLID,
		start = obsTrace.HitPos + maxVaultWidthVec,
		endpos = obsTrace.HitPos,
		mins = oimins,
		maxs = oimaxs
	})

	UPar.debugwireframebox(obsImgTrace.StartPos, oimins, oimaxs, 3, Color(0, 255, 0), true)
	UPar.debugwireframebox(obsImgTrace.HitPos, oimins, oimaxs, 3, Color(255, 0, 255), true)

	if obsImgTrace.StartSolid or not obsImgTrace.Hit then
		return
	end

	local usedImg = obsImgTrace.Fraction * maxVaultWidth	
		
	local evlen = math.min(landpos[3] - obsTrace.StartPos[3], math.abs(evlenFrac * plyHeight))
	local startpos = obsImgTrace.HitPos + dirNorm * math.min(SAFE_OFFSET_H, usedImg)
	startpos[3] = landpos[3]
	local endpos = startpos - Vector(0, 0, evlen)

	local vaultTrace = util.TraceHull({
		filter = ply, 
		mask = MASK_PLAYERSOLID,
		start = startpos,
		endpos = endpos,
		mins = dmins,
		maxs = dmaxs,
	})

	local usedVault = vaultTrace.Fraction * evlen

	if vaultTrace.StartSolid or usedVault < SAFE_OFFSET_V then
		return
	end

	UPar.debugwireframebox(vaultTrace.StartPos, dmins, dmaxs, 3, Color(0, 0, 0), true)
	UPar.debugwireframebox(vaultTrace.HitPos, dmins, dmaxs, 3, nil, true)

	table.Merge(vaultTrace, {
		mins = Vector(dmins),
		maxs = Vector(dmaxs),
		used = usedVault
	})

	table.Merge(obsImgTrace, {
		mins = oimins,
		maxs = oimaxs,
		used = usedImg
	})

	return vaultTrace, obsImgTrace
end

UPar.GetFallDamageInfo = function(ply, fallspeed, thr)
	fallspeed = fallspeed or ply:GetVelocity()[3]
	if fallspeed < thr then
		local damage = hook.Run('GetFallDamage', ply, fallspeed) or 0
		if isnumber(damage) and damage > 0 then
			local d = DamageInfo()
			d:SetDamage(damage)
			d:SetAttacker(Entity(0))
			d:SetDamageType(DMG_FALL) 

			return d	
		end 
	end
end

local function Hermite3(t_norm, m0, m1)
    local t = math.Clamp(t_norm, 0, 1)
    local t2 = t * t
    local t3 = t2 * t

    local h10 = t3 - 2 * t2 + t
    local h01 = -2 * t3 + 3 * t2
    local h11 = t3 - t2

    local result = m0 * h10 + h01 + m1 * h11

    return math.Clamp(result, 0, 1)
end

UPar.Hermite3 = Hermite3


UPar.UniformAccelInterpPos = function(t, startpos, endpos, startspeed, endspeed)
	-- 注意: 最好验证下 startspeed + endspeed >= 0
	local speed_max = math.abs(math.max(startspeed, endspeed, 0.001))
	local result = Hermite3(t, startspeed / speed_max, endspeed / speed_max)
	return LerpVector(result, startpos, endpos), result
end


UPar.GetUniformAccelMoveData = function(startpos, endpos, startspeed, endspeed)
	-- 可以直接作为 upaciton 的 movedata 使用
	local dirNorm = (endpos - startpos):GetNormalized()
	local dis = (endpos - startpos):Dot(dirNorm)
	local duration = dis * 2 / (startspeed + endspeed)
	if duration <= 0 then 
		print('[UniformAccelInterpVaildate]: Warning: duration <= 0')
		return
	end

	return {
		startpos = startpos,
		endpos = endpos,
		startspeed = startspeed,
		endspeed = endspeed,
		duration = duration,
		starttime = CurTime()
	}
end


UPar.UniformAccelMoveThink = function(_, ply, data, mv, cmd)
	local startpos = data.startpos
	local endpos = data.endpos
	local startspeed = data.startspeed
	local endspeed = data.endspeed
	local duration = data.duration

	local dt = CurTime() - data.starttime
	local speed_max = math.abs(math.max(startspeed, endspeed, 0.001))
	local result = Hermite3(dt / duration, startspeed / speed_max, endspeed / speed_max)
	local endflag = dt > duration or result >= 1

	mv:SetOrigin(endflag and endpos or LerpVector(result, startpos, endpos))

	return endflag
end