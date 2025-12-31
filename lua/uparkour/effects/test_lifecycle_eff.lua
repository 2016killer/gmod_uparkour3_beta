--[[
	作者:白狼
	2025 12 13
]]--

-- ==================== 生命周期 ===============
if not GetConVar('developer') or not GetConVar('developer'):GetBool() then return end

local effect = UPEffect:Register('test_lifecycle', 'default', {
	label = '#default', 
	AAAACreat = '白狼',
	rhythm_sound = 'hl1/fvox/blip.wav'
})

function effect:Start(ply, checkResult)
	if SERVER then return end
	surface.PlaySound('hl1/fvox/activated.wav')
end

function effect:Rhythm(ply, customData)
	print('customData:', customData)
	if SERVER then return end
	surface.PlaySound(self.rhythm_sound)
end

function effect:Clear(ply, checkResult)
	if SERVER then return end
	surface.PlaySound('hl1/fvox/deactivated.wav')
end

UPar.RegisterEffectEasy('test_lifecycle', 'default', 'example', {
	AAAACreat = 'Miss DouBao',
	AAADesc = '#upgui.dev.example',
	label = '#upgui.dev.example'
})

UPEffect:Register('test_lifecycle_t1', 'default', effect, true)

if CLIENT then
	local red = Color(255, 0, 0)
	local yellow = Color(150, 150, 0)


	UPar.SeqHookAdd('UParEffVarPreviewColor_test_lifecycle_default', 'example.red', function(key, val)
		if key == 'rhythm_sound' then return red end
	end, 1)

	UPar.SeqHookAdd('UParEffVarPreviewColor', 'example.yellow', function(actName, effName, key, val)
		if key == 'rhythm_sound' then 
			return yellow 
		end
	end, 1)

	UPar.SeqHookAdd('UParEffVarEditorWidget_test_lifecycle_default', 'example.local', function(key, val, editor, keyColor)
		if key == 'rhythm_sound' then
			local comboBox = editor:ComboBox(UPar.SnakeTranslate_2(key), '')

			comboBox.OnSelect = function(self, index, value, data)
				editor:Update(key, value)
			end
			comboBox:AddChoice('hl1/fvox/blip.wav')
			comboBox:AddChoice('Weapon_AR2.Single')
			comboBox:AddChoice('Weapon_Pistol.Single')

			editor:Help('#upgui.dev.special_widget')
			return true
		end
	end, 1)

	UPar.SeqHookAdd('UParEffVarEditorWidget', 'example.global', function(actName, effName, key, val, editor, keyColor)
		if key == 'rhythm_sound' then
			local comboBox = editor:ComboBox(UPar.SnakeTranslate_2(key), '')

			comboBox.OnSelect = function(self, index, value, data)
				editor:Update(key, value)
			end
			comboBox:AddChoice('hl1/fvox/blip.wav')
			comboBox:AddChoice('Weapon_Shotgun.Double')
			comboBox:AddChoice('Weapon_357.Single')

			editor:Help('#upgui.dev.special_widget_global')
			return true
		end
	end, 1)

end