--[[
	作者:白狼
	2025 12 13
--]]

UPar.GenEffClear = function(self, ply, _, interruptSource)
	if SERVER then
		ply:SetNWString('UP_WOS', '')
	elseif CLIENT and VManip then
		local currentAnim = VManip:GetCurrentAnim()
		if currentAnim and currentAnim == self.VManipAnim then
			if interruptSource then
				VManip:Remove()
			else
				VManip:QuitHolding(currentAnim)
			end
		end

		local currentLegsAnim = VMLegs:GetCurrentAnim()
		if interruptSource and currentLegsAnim and currentLegsAnim == self.VMLegsAnim then
			VMLegs:Remove()
		end
	end
end


UPar.GetPlayerEffect = function(ply, actName, effName)
	local actEffects = UPar.EffInstances[actName]
	if not istable(actEffects) then
		return nil
	end

    if effName == 'CACHE' then
        return ply.upeff_cache[actName]
    else
        return actEffects[effName]
    end
end

UPar.EffectTest = function(ply, actName, effName)
	local effect = UPar.GetPlayerEffect(ply, actName, effName)
	if not effect then
		print(string.format('[UPar]: effect test failed, can not find effect named "%s" from act "%s"', effName, actName))
		return
	end

	effect:Start(ply)
	timer.Simple(0.5, function() effect:Rhythm(ply) end)
	timer.Simple(1, function() effect:Clear(ply) end)
end

if SERVER then
	util.AddNetworkString('UParEffectTest')

	net.Receive('UParEffectTest', function(len, ply)
		local actName = net.ReadString()
		local effName = net.ReadString()
		
		UPar.EffectTest(ply, actName, effName)
	end)
elseif CLIENT then
	UPar.CallServerEffectTest = function(actName, effName)
		net.Start('UParEffectTest')
			net.WriteString(actName)
			net.WriteString(effName)
		net.SendToServer()
	end
end