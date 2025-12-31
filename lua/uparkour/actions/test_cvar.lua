--[[
	作者:白狼
	2025 12 18
]]--

if not GetConVar('developer') or not GetConVar('developer'):GetBool() then return end
-- ==================== 测试参数控件 ===============
local action = UPAction:Register('test_lifecycle', {})

action:InitConVars({
	{
		name = 'example_numslider',
		label = '#upgui.dev.example_numslider',
		default = '0',
		widget = 'NumSlider',
		min = 0, max = 1, decimals = 2,
		help = '#upgui.dev.example_help',
	},

	{
		name = 'example_color',
		label = '#upgui.dev.example_color_editor',
		default = '255 0 0 255',
		widget = 'UParColorEditor'
	},

	{
		name = 'example_ang',
		label = '#upgui.dev.example_ang_editor',
		default = '0.5 0.5 0.5',
		widget = 'UParAngEditor',
		min = -1, max = 1, decimals = 1, interval = 0.1,
	},

	{
		name = 'example_vec',
		label = '#upgui.dev.example_vec_editor',
		default = '0 1 0',
		widget = 'UParVecEditor',
		min = -2, max = 2, decimals = 2, interval = 0.5,
	},

	{
		name = 'example_keybinder',
		label = '#upgui.dev.example_keybinder',
		default = '[9, 1]',
		widget = 'UParKeyBinder',
	},

	{
		name = 'example_invisible',
		label = '#upgui.dev.example_invisible',
		default = '0',
		widget = 'NumSlider',
		invisible = true,
	},

	{
		name = 'example_admin',
		label = '#upgui.dev.example_admin',
		default = '0',
		widget = 'NumSlider',
		admin = true,
	}
}) 

action:AddConVar({
	name = 'example_special',
	default = '0',
	widget = 'Special'
})

if CLIENT then
	-- 注册预设
	action:RegisterPreset(
		'example',
		{
			AAAACreat = 'Miss DouBao',
			AAAContrib = 'Zack',

			label = '#upgui.dev.example',
			values = {
				['example_numslider'] = '0.5'
			}
		}
	)

	UPar.SeqHookAdd('UParActCVarWidget_test_lifecycle', 'example.special.widget', function(cvCfg, panel)
		if cvCfg.name == 'example_special' then
			panel:Help('#upgui.dev.special_widget')
			return true
		end
	end)

	UPar.SeqHookAdd('UParActCVarWidget', 'example.special.widget', function(actName, cvCfg, panel)
		if cvCfg.name == 'example_special' then
			panel:Help('#upgui.dev.special_widget_global')
			return true
		end
	end)
end