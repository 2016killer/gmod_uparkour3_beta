--[[
	作者:白狼
	2025 12 20
--]]
local zerovec = UPar.zerovec
local zeroang = UPar.zeroang

local angVel = Vector()
local angOff = Vector()
local ANG_PUNCH_FRAMELOOP_ID = 'upunch.ang'

local function AngPunchFrameLoop(dt, curTime)
	local angacc = -(angOff * 50 + 10 * angVel)
	angOff = angOff + angVel * dt 
	angVel = angVel + angacc * dt	

	if angOff:LengthSqr() < 0.1 and angVel:LengthSqr() < 0.1 then
		angOff = Vector()
		angVel = Vector()

		return true
	end
end

UPar.AngPunch = function(vel, off, timeout)
	off = off or zerovec
	vel = vel or zerovec
	timeout = timeout or 2
	assert(isvector(off), 'off must be a vector.')
	assert(isvector(vel), 'vel must be a vector.')
	assert(isnumber(timeout), 'timeout must be a number.')

	angOff = angOff + off
	angVel = angVel + vel

	UPar.PushFrameLoop(ANG_PUNCH_FRAMELOOP_ID, AngPunchFrameLoop, nil, timeout)
end

UPar.SetAngPunch = function(vel, off, timeout)
	off = off or zerovec
	vel = vel or zerovec
	timeout = timeout or 2
	assert(isvector(off), 'off must be a vector.')
	assert(isvector(vel), 'vel must be a vector.')
	assert(isnumber(timeout), 'timeout must be a number.')

	angOff = off
	angVel = vel

	UPar.PushFrameLoop(ANG_PUNCH_FRAMELOOP_ID, AngPunchFrameLoop, nil, timeout)
end

UPar.GetAngPunch = function()
	return angOff, angVel
end


local vecVelWorld = Vector()
local vecOffWorld = Vector()
local VEC_PUNCH_WORLD_FRAMELOOP_ID = 'upunch.vec.world'
local function VecPunchWorldFrameLoop(dt, curTime)
	local vecacc = -(vecOffWorld * 50 + 10 * vecVelWorld)
	vecOffWorld = vecOffWorld + vecVelWorld * dt 
	vecVelWorld = vecVelWorld + vecacc * dt	

	if vecOffWorld:LengthSqr() < 0.1 and vecVelWorld:LengthSqr() < 0.1 then
		vecOffWorld = Vector()
		vecVelWorld = Vector()
		return true
	end
end

UPar.VecPunchWorld = function(vel, off, timeout)
	off = off or zerovec
	vel = vel or zerovec
	timeout = timeout or 2
	assert(isvector(off), 'off must be a vector.')
	assert(isvector(vel), 'vel must be a vector.')
	assert(isnumber(timeout), 'timeout must be a number.')

	vecOffWorld = vecOffWorld + off
	vecVelWorld = vecVelWorld + vel

	UPar.PushFrameLoop(VEC_PUNCH_WORLD_FRAMELOOP_ID, VecPunchWorldFrameLoop, nil, timeout)
end

UPar.SetVecPunchWorld = function(vel, off, timeout)
	off = off or zerovec
	vel = vel or zerovec
	timeout = timeout or 2
	assert(isvector(off), 'off must be a vector.')
	assert(isvector(vel), 'vel must be a vector.')
	assert(isnumber(timeout), 'timeout must be a number.')

	vecOffWorld = off
	vecVelWorld = vel

	UPar.PushFrameLoop(VEC_PUNCH_WORLD_FRAMELOOP_ID, VecPunchWorldFrameLoop, nil, timeout)
end

UPar.GetVecPunchWorld = function()
	return vecOffWorld, vecVelWorld
end


local vecVel = Vector()
local vecOff = Vector()
local VEC_PUNCH_FRAMELOOP_ID = 'upunch.vec'
local function VecPunchFrameLoop(dt, curTime)
	local vecacc = -(vecOff * 50 + 10 * vecVel)
	vecOff = vecOff + vecVel * dt 
	vecVel = vecVel + vecacc * dt	

	if vecOff:LengthSqr() < 0.1 and vecVel:LengthSqr() < 0.1 then
		vecOff = Vector()
		vecVel = Vector()
		return true
	end
end

UPar.VecPunch = function(vel, off, timeout)
	off = off or zerovec
	vel = vel or zerovec
	timeout = timeout or 2
	assert(isvector(off), 'off must be a vector.')
	assert(isvector(vel), 'vel must be a vector.')
	assert(isnumber(timeout), 'timeout must be a number.')

	vecOff = vecOff + off
	vecVel = vecVel + vel

	UPar.PushFrameLoop(VEC_PUNCH_FRAMELOOP_ID, VecPunchFrameLoop, nil, timeout)
end

UPar.SetVecPunch = function(vel, off, timeout)
	off = off or zerovec
	vel = vel or zerovec
	timeout = timeout or 2
	assert(isvector(off), 'off must be a vector.')
	assert(isvector(vel), 'vel must be a vector.')
	assert(isnumber(timeout), 'timeout must be a number.')

	vecOff = off
	vecVel = vel
	
	UPar.PushFrameLoop(VEC_PUNCH_FRAMELOOP_ID, VecPunchFrameLoop, nil, timeout)
end

UPar.GetVecPunch = function()
	return vecOff, vecVel
end

local CALC_HOOK_IDENTITY = 'upunch.calc'

local function UPunchCalcView(ply, pos, angles, fov)
	local view = GAMEMODE:CalcView(ply, pos, angles, fov) 
	local eyeAngles = view.angles

	view.origin = view.origin 
		+ eyeAngles:Forward() * vecOff.x 
		+ eyeAngles:Right() * vecOff.y 
		+ eyeAngles:Up() * vecOff.z
		+ vecOffWorld

	view.angles = eyeAngles + Angle(angOff.x, angOff.y, angOff.z)

	return view
end

local function UPunchCalcViewModelView(wep, vm, oP, oA, p, a)
	local wp, wa = p, a
	if isfunction(wep.CalcViewModelView) then wp, wa = wep:CalcViewModelView(vm, oP, oA, p, a) end
	if isfunction(wep.GetViewModelPosition) then wp, wa = wep:GetViewModelPosition(p, a) end
	if not (wp and wa) then wp, wa = p, a end
	return wp + vecOffWorld, wa + Angle(angOff.x, angOff.y, angOff.z)
end

hook.Add('UParPushFrameLoop', 'upunch.start', function(identity, endtime, addition)
	if identity == VEC_PUNCH_FRAMELOOP_ID then
		hook.Add('CalcView', CALC_HOOK_IDENTITY, UPunchCalcView)
		return true
	elseif identity == ANG_PUNCH_FRAMELOOP_ID or identity == VEC_PUNCH_WORLD_FRAMELOOP_ID then
		hook.Add('CalcView', CALC_HOOK_IDENTITY, UPunchCalcView)
		hook.Add('CalcViewModelView', CALC_HOOK_IDENTITY, UPunchCalcViewModelView)
		return true
	end
	
end)

hook.Add('UParPopFrameLoop', 'upunch.out', function(identity, endtime, addition, reason)
	if reason == 'OVERRIDE' then return end
	if not UPar.IsFrameLoopExist(VEC_PUNCH_FRAMELOOP_ID)
	and not UPar.IsFrameLoopExist(ANG_PUNCH_FRAMELOOP_ID)  
	and not UPar.IsFrameLoopExist(VEC_PUNCH_WORLD_FRAMELOOP_ID)
	then
		hook.Remove('CalcView', CALC_HOOK_IDENTITY)
		hook.Remove('CalcViewModelView', CALC_HOOK_IDENTITY)
	end
end)