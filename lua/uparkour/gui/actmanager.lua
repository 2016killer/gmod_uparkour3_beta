--[[
	作者:白狼
	2025 12 13
--]]



local function CreateMenu(panel)
	panel:Clear()

	local isAdmin = LocalPlayer():IsAdmin()
	local actManager = vgui.Create('UParEasyTree')
	actManager:SetSize(200, 400)
	actManager.OnDoubleClick = function(self, selNode)
		local actEditor = vgui.Create('UParActEditor')
		actEditor:Init2(selNode.actName)
	end

	actManager.RefreshNode = function(self)
		actManager:Clear()

		local ActionSet = UPar.ActInstances
		local keys = {}
		for k, v in pairs(ActionSet) do table.insert(keys, k) end
		table.sort(keys)

		for i, k in ipairs(keys) do
			local v = ActionSet[k]
			if not UPar.isupaction(v) then
				ErrorNoHaltWithStack(string.format('Invalid action "%s" named "%s" (not upaction)', action, k))
				continue
			end

			if v.invisible then 
				continue 
			end

			local label = isstring(v.label) and v.label or k
			local icon = isstring(v.icon) and v.icon or 'icon32/tool.png'
			
			local node = self:AddNode(label, icon)
			node.actName = v.Name


			local editButton = vgui.Create('DButton', node)
			editButton:SetSize(20, 18)
			editButton:Dock(RIGHT)
			
			editButton:SetText('')
			editButton:SetIcon('icon16/application_edit.png')
			
			editButton.DoClick = function()
				local actEditor = vgui.Create('UParActEditor')
				actEditor:Init2(node.actName)
			end

			if not isAdmin then 
				continue 
			end

			if v:GetDisabled() ~= nil then
				local disableButton = vgui.Create('DButton', node)
				disableButton:SetSize(20, 18)
				disableButton:Dock(RIGHT)
				
				disableButton:SetText('')
				disableButton:SetIcon(v:GetDisabled() and 'icon16/delete.png' or 'icon16/accept.png')
				
				disableButton.DoClick = function()
					local newValue = not v:GetDisabled()
					v:SetDisabled(newValue)
					disableButton:SetIcon(newValue and 'icon16/delete.png' or 'icon16/accept.png')
				end
			end


			if v:GetPredictionMode() ~= nil then
				local predictionModeButton = vgui.Create('DButton', node)
				predictionModeButton:SetSize(20, 18)
				predictionModeButton:Dock(RIGHT)
				
				predictionModeButton:SetText('')
				predictionModeButton:SetIcon(v:GetPredictionMode() and 'upgui/client.jpg' or 'upgui/server.jpg')
				
				predictionModeButton.DoClick = function()
					local newValue = not v:GetPredictionMode()
					v:SetPredictionMode(newValue)
					predictionModeButton:SetIcon(newValue and 'upgui/client.jpg' or 'upgui/server.jpg')
				end
			end

		end
	end

	actManager:RefreshNode()
	panel:AddItem(actManager)

	local refreshButton = panel:Button('#upgui.refresh', '')
	refreshButton.DoClick = function()
		actManager:RefreshNode()
	end

	panel:Help('==========Version==========')
	panel:ControlHelp(UPar.Version)

	UPar.GUI_ActManager = actManager

	hook.Add('UParRegisterAction', 'upar.update.actmanager', function(actName, action)
		timer.Create('upar.update.actmanager', 0.5, 1, function()
			if not IsValid(panel) then
				hook.Remove('UParRegisterAction', 'upar.update.actmanager')
				timer.Remove('upar.update.actmanager')
				return 
			end

			actManager:RefreshNode()
		end)
	end)
end

hook.Add('PopulateToolMenu', 'upar.menu.actmanager', function()
	spawnmenu.AddToolMenuOption('Options', 
		'UParkour 3', 
		'upar.menu.actmanager', 
		'#upgui.menu.actmanager', '', '', 
		CreateMenu
	)
end)
