--[[
	作者:白狼
	2025 12 09
--]]


local color_black = color_black

-- ==================== 动作编辑器 ===============
local ActEditor = {}

function ActEditor:Init2(actName)
	local action = UPar.GetAction(actName)
	local actName = action.Name

	if not UPar.isupaction(action) then
		ErrorNoHaltWithStack(string.format('Invalid action "%s" (not upaction)', action))
		return
	end

	local old = UPar.LRUGet(string.format('UI_ActEditor_%s', actName))
	if IsValid(old) and ispanel(old) then old:Remove() end
	UPar.LRUSet(string.format('UI_ActEditor_%s', actName), self)

	local size = UPar.LRUGet('UI_ActEditor_Size')
	if isvector(size) then
		self:SetSize(math.max(100, size[1]), math.max(100, size[2]))
	else
		self:SetSize(600, 400)
	end

	self:Center()
	self:MakePopup()
	self:SetSizable(true)
	self:SetDeleteOnClose(true)
	self:SetTitle(string.format(
		'%s   %s', 
		language.GetPhrase('#upgui.menu.actmanager'), 
		language.GetPhrase(isstring(action.label) and action.label or actName)
	))
	self:SetIcon(isstring(action.icon) and action.icon or 'icon32/tool.png')


	local Tabs = vgui.Create('DPropertySheet', self)
	Tabs:Dock(FILL)

	self.Tabs = Tabs
	self.action = action

	if istable(UPar.GetEffects(actName)) and not table.IsEmpty(UPar.GetEffects(actName)) then
		local effectManager = vgui.Create('UParEffectManager', self)
		Tabs:AddSheet('#upgui.effect', effectManager, 'icon16/user.png', false, false, '')
		effectManager:Init2(actName)
	end

	if istable(action.ConVarsWidget) then
		local mainPanel = self:AddSheet('#upgui.options', 'icon16/wrench.png')
		local scrollPanel = vgui.Create('DScrollPanel', mainPanel)
		local panel = vgui.Create('DForm', scrollPanel)

		scrollPanel:Dock(FILL)
		panel:Dock(FILL)

		local succ, err = pcall(self.CreateConVarsPanel, self, panel)
		if not succ then
			ErrorNoHaltWithStack(string.format('CreateConVarsPanel: %s', err))
		end
	end

	UPar.SeqHookRunAllSafe('UParActSundryPanels_' .. actName, self)
	UPar.SeqHookRunAllSafe('UParActSundryPanels', actName, self)
	
	if GetConVar('developer') and GetConVar('developer'):GetBool() then
		self.Paint = self.PaintDevMode
		self:SetTitle(string.format(
			'%s   %s  -  DevMode', 
			language.GetPhrase('#upgui.menu.actmanager'), 
			actName
		))
	end
end

function ActEditor:OnClose()
	UPar.LRUDelete(string.format('UI_ActEditor_%s', self.action.Name))

	local w, h = self:GetSize()
	UPar.LRUSet('UI_ActEditor_Size', Vector(w, h, 0))
end

function ActEditor:PaintDevMode(w, h)
	draw.RoundedBox(8, 0, 0, w, h, color_black)
end


function ActEditor:AddSheet(label, icon, mainPanel)
	mainPanel = mainPanel or vgui.Create('DPanel')
	
	if IsValid(mainPanel) and ispanel(mainPanel) then
		mainPanel:SetParent(Tabs)
		mainPanel:Dock(FILL)
	else 
		ErrorNoHaltWithStack(string.format('Invalid mainPanel "%s"', mainPanel))
		return
	end

	label = isstring(label) and label or 'UNKNOWN'
	icon = isstring(icon) and icon or 'icon16/add.png'

	self.Tabs:AddSheet(label, mainPanel, icon, false, false, '')

	return mainPanel
end


function ActEditor:CreateConVarsPanel(panel)
	local action = self.action
	local actName = action.Name

	local ctrl = vgui.Create('ControlPresets', panel)
	ctrl:SetPreset(actName)
	panel:AddItem(ctrl)
	panel:SetLabel('#upgui.options')

	local isAdmin = not LocalPlayer():IsAdmin()

	local defaultPreset = {}
	for idx, cvCfg in ipairs(action.ConVarsWidget) do
		local invisible = cvCfg.invisible
		local admin = cvCfg.admin
		local cvName = cvCfg.name
		local cvDefault = cvCfg.default or '0'
		local cvHelp = cvCfg.help
		local cvWidget = cvCfg.widget or 'NumSlider'

		if cvWidget ~= 'Label' then
			ctrl:AddConVar(cvName)
			defaultPreset[cvName] = cvDefault
		end

		if invisible then 
			continue 
		end

		if admin and not isAdmin then 
			continue 
		end

		local temp = UPar.SeqHookRunSafe('UParActCVarWidget_' .. actName, cvCfg, panel) or
		UPar.SeqHookRunSafe('UParActCVarWidget', actName, cvCfg, panel)
	end
	
	ctrl:AddOption('#preset.default', defaultPreset)

	if istable(action.ConVarsPreset) then 
		for pname, pdata in pairs(action.ConVarsPreset) do
			local label = isstring(pdata.label) and pdata.label or pname
			local values = pdata.values

			ctrl:AddOption(label, values)
		end
	end

	panel:Help('')
end


function ActEditor:OnRemove()
	self.action = nil
	self.Tabs = nil
end

vgui.Register('UParActEditor', ActEditor, 'DFrame')
ActEditor = nil


UPar.SeqHookAdd('UParActCVarWidget', 'default', function(actName, cvCfg, panel)
	local cvName = cvCfg.name
	local cvHelp = cvCfg.help
	local cvWidget = cvCfg.widget or 'NumSlider'
	
	local label = cvCfg.label or UPar.GetConVarPhrase(cvName)
	local created = false
	if cvWidget == 'NumSlider' then 
		panel:NumSlider(
			label, 
			cvName, 
			isnumber(cvCfg.min) and cvCfg.min or 0, 
			isnumber(cvCfg.max) and cvCfg.max or 1, 
			isnumber(cvCfg.decimals) and cvCfg.decimals or 2
		)
		created = true
	elseif cvWidget == 'NumberWang' then
		local numberWang = vgui.Create('DNumberWang', panel)
		numberWang:SetMinMax(
			isnumber(cvCfg.min) and cvCfg.min or 0, 
			isnumber(cvCfg.max) and cvCfg.max or 1
		)
		numberWang:SetDecimals(isnumber(cvCfg.decimals) and cvCfg.decimals or 2)
		numberWang:SetInterval(isnumber(cvCfg.interval) and cvCfg.interval or 0.5)
		numberWang:SetValue(GetConVar(cvName) and GetConVar(cvName):GetFloat() or 0)
		numberWang:SetConVar(cvName)

		panel:Help(label)
		panel:AddItem(numberWang)

		created = true
	elseif cvWidget == 'CheckBox' then
		panel:CheckBox(label, cvName)
		created = true
	elseif cvWidget == 'ComboBox' then
		local comboBox = panel:ComboBox(label, cvName)

		if istable(cvCfg.choices) then
			for _, choice in ipairs(cvCfg.choices) do
				if isstring(choice) then
					comboBox:AddChoice(choice)
				elseif istable(choice) then
					comboBox:AddChoice(unpack(choice))
				else
					print(string.format('[UPar]: Warning: ComboBox choice must be a string or a table, but got %s', type(choice)))
				end
			end
		end
		created = true
	elseif cvWidget == 'TextEntry' then
		panel:TextEntry(label, cvName)
		created = true
	elseif cvWidget == 'KeyBinder' then
		panel:KeyBinder(label, cvName)
		created = true
	elseif cvWidget == 'UParColorEditor' then
		local colorEditor = vgui.Create('UParColorEditor', panel)
		colorEditor:SetConVar(cvName)

		panel:Help(label)
		panel:AddItem(colorEditor)
		created = true
	elseif cvWidget == 'UParAngEditor' then
		local angEditor = vgui.Create('UParAngEditor', panel)
		angEditor:SetMin(isnumber(cvCfg.min) and cvCfg.min or -10000)
		angEditor:SetMax(isnumber(cvCfg.max) and cvCfg.max or 10000)
		angEditor:SetDecimals(isnumber(cvCfg.decimals) and cvCfg.decimals or 2)
		angEditor:SetInterval(isnumber(cvCfg.interval) and cvCfg.interval or 0.5)
		angEditor:SetConVar(cvName)

		panel:Help(label)
		panel:AddItem(angEditor)
		created = true
	elseif cvWidget == 'UParVecEditor' then
		local vecEditor = vgui.Create('UParVecEditor', panel)
		vecEditor:SetMin(isnumber(cvCfg.min) and cvCfg.min or -10000)
		vecEditor:SetMax(isnumber(cvCfg.max) and cvCfg.max or 10000)
		vecEditor:SetDecimals(isnumber(cvCfg.decimals) and cvCfg.decimals or 2)
		vecEditor:SetInterval(isnumber(cvCfg.interval) and cvCfg.interval or 0.5)
		vecEditor:SetConVar(cvName)

		panel:Help(label)
		panel:AddItem(vecEditor)
		created = true
	elseif cvWidget == 'UParKeyBinder' then
		local keyBinder = vgui.Create('UParKeyBinder', panel)
		keyBinder:SetConVar(cvName)

		panel:Help(label)
		panel:AddItem(keyBinder)
		created = true
	elseif cvWidget == 'Label' then
		local label = panel:Help(label)
		if IsColor(cvCfg.color) then label:SetTextColor(cvCfg.color) end
		created = true
	end

	if not created then 
		return 
	end

	if isstring(cvHelp) then
		panel:ControlHelp(cvHelp)
	elseif cvHelp then
		panel:ControlHelp(UPar.GetConVarPhrase(cvName) .. '.help')
	end

	return true
end, 10)

UPar.SeqHookAdd('UParActSundryPanels', 'DescPanel', function(actName, editor)
	local action = UPar.GetAction(actName)

	if not UPar.isupaction(action) then
		print(string.format('[UPar]: DescPanel failed: can not find action named "%s"', actName))
		return
	end

	local actName = action.Name
	local mainPanel = editor:AddSheet('#upgui.desc', 'icon16/information.png', panel)
	local scrollPanel = vgui.Create('DScrollPanel', mainPanel)
	local panel = vgui.Create('DForm', scrollPanel)

	scrollPanel:Dock(FILL)
	panel:Dock(FILL)

	panel.label = '#upgui.desc'
	panel.icon = 'icon16/information.png'
	panel:SetLabel('#upgui.desc')
	
	panel:Help(string.format('%s: %s', language.GetPhrase('upgui.desc'), language.GetPhrase(tostring(action.AAADesc))))
	panel:Help('')

	panel:Help(string.format('%s: %s', language.GetPhrase('upgui.creat'), action.AAAACreat or ''))
	panel:Help(string.format('%s: %s', language.GetPhrase('upgui.contrib'), action.AAAContrib or ''))
	

	if istable(action.ConVarsPreset) then
		panel:Help('====================')
		for pname, pdata in pairs(action.ConVarsPreset) do
			local label = isstring(pdata.label) and pdata.label or pname
			panel:Help(string.format('%s: %s', language.GetPhrase('#preset'), language.GetPhrase(label)))
			panel:Help(string.format('%s: %s', language.GetPhrase('upgui.creat'), pdata.AAAACreat or ''))
			panel:Help(string.format('%s: %s', language.GetPhrase('upgui.contrib'), pdata.AAAContrib or ''))
			
			panel:Help('')
		end
	end

	
	local Effects = UPar.GetEffects(actName)

	if istable(Effects) then
		panel:Help('====================')
		for effName, effect in pairs(Effects) do
			if not UPar.isupeffect(effect) then
				ErrorNoHaltWithStack(string.format('Invalid effect "%s" (not upeffect)', effect))
				continue
			end
			panel:Help(string.format('%s: %s', language.GetPhrase('upgui.effect'), effName))
			panel:Help(string.format('%s: %s', language.GetPhrase('upgui.creat'), effect.AAAACreat or ''))
			panel:Help(string.format('%s: %s', language.GetPhrase('upgui.contrib'), effect.AAAContrib or ''))	
			panel:Help('')
		end
	end
end, 10)
