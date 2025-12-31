--[[
	作者:白狼
	2025 12 29
--]]

-- ==============================================================
-- 修改 VMLegs.PlayAnim 以方便捕获其生命周期
-- 使用延迟注入来兼容其他开发者对其的修改
-- ==============================================================
concommand.Add('upext_vmlegs_inject', function()
	if not VMLegs then
		print('[UPExt]: can not find VMLegs')
		return
	end

	VMLegs.OriginalPlayAnim = isfunction(VMLegs.OriginalPlayAnim) and VMLegs.OriginalPlayAnim or VMLegs.PlayAnim
	VMLegs.PlayAnim = function(self, anim, ...)
		hook.Run('VMLegsPrePlayAnim', anim)
		self:OriginalPlayAnim(anim, ...)
		hook.Run('VMLegsPostPlayAnim', anim)
	end

	print('[UPExt]: VMLegs.PlayAnim already injected')
	

	VMLegs.OriginalRemove = isfunction(VMLegs.OriginalRemove) and VMLegs.OriginalRemove or VMLegs.Remove
	VMLegs.Remove = function(...)
		local anim = VMLegs:GetCurrentAnim()
		hook.Run('VMLegsPreRemove', anim)
		VMLegs.OriginalRemove(...)
		hook.Run('VMLegsRemove', anim)
	end

	print('[UPExt]: VMLegs.Remove already injected')
	
end)

concommand.Add('upext_vmlegs_recovery', function()
	if not VMLegs then
		print('[UPExt]: can not find VMLegs')
		return
	end

	VMLegs.PlayAnim = isfunction(VMLegs.OriginalPlayAnim) and VMLegs.OriginalPlayAnim or VMLegs.PlayAnim
	print('[UPExt]: VMLegs.PlayAnim already recovered')
	
	VMLegs.Remove = isfunction(VMLegs.OriginalRemove) and VMLegs.OriginalRemove or VMLegs.Remove
	print('[UPExt]: VMLegs.Remove already recovered')
end)


hook.Add('KeyPress', 'UPExtVMLegsInject', function()
	hook.Remove('KeyPress', 'UPExtVMLegsInject')
	timer.Simple(3, function() RunConsoleCommand('upext_vmlegs_inject') end)
end)

-- ==============================================================
-- 菜单
-- ==============================================================
UPar.SeqHookAdd('UParExtendMenu', 'VMLegsInject', function(panel)
	panel:Help('·························· VMLegs ··························')
	panel:ControlHelp('#upext.vmlegs_inject.help')
	panel:Button('#upext.vmlegs_inject', 'upext_vmlegs_inject')
	panel:Button('#upext.vmlegs_recovery', 'upext_vmlegs_recovery')
end, 2)