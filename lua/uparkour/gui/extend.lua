--[[
	作者:白狼
	2025 12 10
--]]


local function CreateMenu(panel)
	panel:Clear()

	UPar.SeqHookRunAllSafe('UParExtendMenu', panel)

	panel:Help('==========Version==========')
	panel:ControlHelp(UPar.Version)
end

hook.Add('PopulateToolMenu', 'upar.menu.extend', function()
	spawnmenu.AddToolMenuOption('Options', 
		'UParkour 3', 
		'upar.menu.extend', 
		'#upgui.menu.extend', '', '', 
		CreateMenu
	)
end)