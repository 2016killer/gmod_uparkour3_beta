--[[
	作者:白狼
	2025 12 23
]]--

-- ==================== 高爬动作特效 ===============

local effect = UPEffect:Register('uphighclimb', 'default', {
	VManipAnim = 'dp_catch_BaiLang',
	VMLegsAnim = '',
	WOSAnim = '',

	sound = 'uparkour/bailang/highclimb.mp3',

	upunch = true,
	upunch_vec_second = Vector(0, 0, 25),

	punch = true,
	punch_ang_first = Angle(-20, 5, 0),
	punch_ang_second = Angle(20, 0, 0),
	
	AAAACreat = '白狼',
	AAADesc = '#default',
})

function effect:start_first(ply)
	-- WOS动画
	if self.WOSAnim and self.WOSAnim ~= '' then
		if SERVER then
			ply:SetNWString('UP_WOS', self.WOSAnim)
		elseif CLIENT then
			local seq = ply:LookupSequence(self.WOSAnim)
			if seq and seq > 0 then
				ply:AddVCDSequenceToGestureSlot(GESTURE_SLOT_JUMP, seq, 0, true)
				ply:SetPlaybackRate(1)
			end
		end
	end

	-- ViewPunch
	if SERVER and self.punch then
		ply:ViewPunch(self.punch_ang_first)
	end

	-- VManip手部动画、音效
	if CLIENT and self.VManipAnim and self.VManipAnim ~= '' then
		VManip:PlayAnim(self.VManipAnim)
	end

	-- VManip腿部动画
	if CLIENT and self.VMLegsAnim and self.VMLegsAnim ~= '' then
		VMLegs:PlayAnim(self.VMLegsAnim)
	end

	-- 音效
	if CLIENT and self.sound and self.sound ~= '' then
		surface.PlaySound(self.sound)
	end
end

function effect:start_second(ply)
	-- ViewPunch
	if SERVER and self.punch then
		ply:ViewPunch(self.punch_ang_second)
	end

	-- upunch
	if CLIENT and self.upunch then
		UPar.SetVecPunch(self.upunch_vec_second)
	end
end

function effect:Start(ply)
	self:start_first(ply)
	timer.Simple(0.2, function() self:start_second(ply) end)
end

effect.Clear = UPar.GenEffClear