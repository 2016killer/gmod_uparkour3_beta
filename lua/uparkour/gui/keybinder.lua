--[[
	作者:白狼
	2025 12 10
--]]

local function CreateMenu(panel)
	panel.RefreshNode = function(self)
		self:Clear()

		local refreshButton = panel:Button('#upgui.refresh', '')
		refreshButton.DoClick = function()
			panel:RefreshNode()
		end

		panel:Help('')
		panel:ControlHelp('#upgui.menu.keybinder.help')
		local help2 = panel:ControlHelp('#upgui.menu.keybinder.help2')
		help2:SetTextColor(Color(255, 170, 0, 255))
		panel:Help('=========================')
   		panel:NumSlider('#upgui.keycheck_interval', 'upkeycheck_interval', 0, 0.1, 2)

		local keys = {}
		for k, v in pairs(UPKeyboard.KeySet) do table.insert(keys, k) end
		table.sort(keys)

		for i, k in ipairs(keys) do
			local v = UPKeyboard.KeySet[k]
			
			local keybinder = vgui.Create('UParKeyBinder')
			keybinder:SetConVar(v.cvar:GetName())

			self:Help(v.label)
			self:AddItem(keybinder)
		end

		panel:Help('==========Version==========')
		panel:ControlHelp(UPar.Version)
	end

	panel:RefreshNode()

	UPar.GUI_KeyBinder = panel

	hook.Add('UParRegisterKey', 'upar.update.keybinder', function()
		timer.Create('upar.update.keybinder', 0.5, 1, function()
			if not IsValid(panel) then
				hook.Remove('UParRegisterKey', 'upar.update.keybinder')
				timer.Remove('upar.update.keybinder')
				return 
			end
			panel:RefreshNode()
		end)
	end)
end


hook.Add('PopulateToolMenu', 'upar.menu.keybinder', function()
	spawnmenu.AddToolMenuOption('Options', 
		'UParkour 3', 
		'upar.menu.keybinder', 
		'#upgui.menu.keybinder', '', '', 
		CreateMenu
	)
end)
