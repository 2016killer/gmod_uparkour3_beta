--[[
	作者:白狼
	2025 11 5
--]]

hook.Add('CalcMainActivity', 'upar.effect.WOS', function(ply, velocity)
	local anim = ply:GetNWString('UP_WOS')
	if anim == '' then
		return
	end

	return -1, ply:LookupSequence(anim)
end)
