--[[
	作者:白狼
	2025 12 29
--]]

local upext_gmodlegs3_compat = CreateClientConVar('upext_gmodlegs3_compat', '1', true, false, '')

-- ==============================================================
-- 兼容 GmodLegs3 (启动 VMLegs 时 禁用 GmodLegs3)
-- ==============================================================
local function temp_changecall(name, old, new)
	local temp_identity = 'UPExtGmodLegs3Compat'

	local function temp_should_disable_legs()
		// return VMLegs and VMLegs:IsActive()
		// 不能直接返回 VMLegs and VMLegs:IsActive(), 因为这是布尔不是nil
		if VMLegs and VMLegs:IsActive() then
			return true
		end
	end

	if new == '1' then
		print('[UPExt]: GmodLegs3Compat enabled')
		hook.Add('ShouldDisableLegs', temp_identity, temp_should_disable_legs)
	else
		print('[UPExt]: GmodLegs3Compat disabled')
		hook.Remove('ShouldDisableLegs', temp_identity)
	end

	temp_should_disable_legs = nil
	temp_identity = nil
end
cvars.AddChangeCallback('upext_gmodlegs3_compat', temp_changecall, 'default')
temp_changecall(nil, nil, upext_gmodlegs3_compat:GetBool() and '1' or '0')
temp_changecall = nil

-- ==============================================================
-- 菜单
-- ==============================================================

UPar.SeqHookAdd('UParExtendMenu', 'GmodLegs3Compat', function(panel)
	panel:Help('·························· GmodLegs3 ··························')
	panel:CheckBox('#upext.gmodlegs3_compat', 'upext_gmodlegs3_compat')
	panel:ControlHelp('#upext.gmodlegs3_compat.help')
end, 1)