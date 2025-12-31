--[[
	作者:白狼
	2025 12 17
--]]

local lightblue = Color(0, 100, 230)
-- ==================== 特效管理器 ===============
local EffectManager = {}

function EffectManager:Init2(actName)
	self.actName = actName

	local div = vgui.Create('DHorizontalDivider', self)
	local div2 = vgui.Create('DVerticalDivider', div)
	local effTree = vgui.Create('UParEffTree', div2)
	local custTree = vgui.Create('UParCustEffTree', div2)
	

	effTree:Init2(actName)
	custTree:Init2(actName)

	div:Dock(FILL)
	div:SetLeft(div2)
	div:SetLeftWidth(250)
	div:SetDividerWidth(5)

	div2:SetDividerHeight(5)
	div2:SetTop(effTree)
	div2:SetBottom(custTree)

	self.div = div
	self.div2 = div2
	self.effTree = effTree
	self.custTree = custTree

	local oldOnSelectedChange = effTree.OnSelectedChange
	effTree.OnSelectedChange = function(self2, node)
		oldOnSelectedChange(self2, node)

		local effName = node.effName
		local effect = UPar.GetEffect(actName, effName)
		self:CreatePreview(effect, node)

		custTree:SetSelectedItem()
		custTree.selNodeLast = nil
	end
	effTree.OnHitNode = function(self2, node)
		if IsValid(node) then 
			custTree:HitNode() 
			custTree:SetSelectedItem()
			custTree.selNodeLast = nil
		end
	end
	effTree.OnRefresh = function()
		if IsValid(self.div:GetRight()) then self.div:GetRight():Remove() end
	end

	effTree.DoRightClick = function(self2, node)
		local menu = DermaMenu()
		local effName = node.effName
		menu:AddOption('#upgui.custom', function()
			self:CreateCustomEffectByDerma(effName)
		end)
		menu:Open()
	end

	local oldOnSelectedChange_ = custTree.OnSelectedChange
	custTree.OnSelectedChange = function(self2, node)
		local effect = oldOnSelectedChange_(self2, node)
		self:CreateEditor(effect, node)
		effTree:SetSelectedItem()
		effTree.selNodeLast = nil
	end
	custTree.OnHitNode = function(self2, node)
		if IsValid(node) then 
			effTree:HitNode() 
			effTree:SetSelectedItem()
			effTree.selNodeLast = nil
		end
	end
	custTree.OnRefresh = function()
		if IsValid(self.div:GetRight()) then self.div:GetRight():Remove() end
	end

	local layout = UPar.LRUGet('UI_EffectEditor_Layout')
	if isvector(layout) then
		div:SetLeftWidth(math.max(20, layout[1]))
		div2:SetTopHeight(math.max(20, layout[2]))
	else
		div:SetLeftWidth(250)
		div2:SetTopHeight(200)
	end
end

function EffectManager:CreateCustomEffectByDerma(effName)
	Derma_StringRequest(
		'#upgui.derma.filename',           
		'',  
		string.format('Custom-%s-%s', effName, os.time()),         
		function(text)    
			if string.find(text, '[\\/:*?"<>|]') then
				error(string.format('Invalid name "%s" (contains invalid filename characters)', text))
			end

			text = string.lower(text)

			local exist = true
			for i = 0, 2 do
				local suffix = i == 0 and '' or ('_' .. tostring(i))
				local newFileName = string.format('%s%s', text, suffix)
				if not self.effTree.EffNames[newFileName] 
				and not self.custTree.EffNames[newFileName] then
					text = newFileName
					exist = false
					break
				end
			end

			if exist then
				notification.AddLegacy(string.format('Custom Effect "%s" already exist', text), NOTIFY_ERROR, 5)
				surface.PlaySound('Buttons.snd10')

				return
			end

			local actName = self.actName
			local custName = text

			local custom = UPar.CreateUserCustEff(actName, effName, custName, true)
			UPar.InitCustomEffect(custom)
			UPar.LRUSet(string.format('UI_CE_%s', custName), custom)

			self.custTree.EffNames[custName] = 1
			self.custTree:AddNode2(custName)
		end,
		nil,
		'#upgui.derma.submit',                    
		'#upgui.derma.cancel'
	)
end

function EffectManager:Refresh()
	self.effTree:Refresh()
	self.custTree:Refresh()

	if IsValid(self.div:GetRight()) then 
		self.div:GetRight():Remove() 
	end
end

function EffectManager:CreatePreview(effect, node)
	if not istable(effect) then
		ErrorNoHaltWithStack(string.format('Invalid effect "%s" (not table)', effect))
		return
	end
	
	local actName = self.actName
	local effName = effect.Name
	local mainPanel = vgui.Create('DPanel')

	if IsValid(self.div) then 
		if IsValid(self.div:GetRight()) then self.div:GetRight():Remove() end
		self.div:SetRight(mainPanel)
	end

	local customButton = vgui.Create('DButton', mainPanel)
	customButton:SetText('#upgui.custom')
	customButton:SetIcon('icon64/tool.png')
	customButton.DoClick = function()
		self:CreateCustomEffectByDerma(effName)
	end
	customButton:Dock(TOP)
	customButton:DockMargin(0, 5, 0, 5)

	local obj = effect
	local scrollPanel = vgui.Create('DScrollPanel', mainPanel)
	local preview = vgui.Create('DForm', scrollPanel)
	
	scrollPanel:Dock(FILL)
	preview:Dock(FILL)
	preview:SetLabel(effName)
	preview.obj = obj
	preview.OnRemove = function(self)
		self.obj = nil
	end

	local keys = {}
	for k, _ in pairs(obj) do table.insert(keys, k) end
	table.sort(keys)

	for _, key in ipairs(keys) do
		local val = obj[key]

		local keyColor = UPar.SeqHookRunSafe(string.format('UParEffVarPreviewColor_%s_%s', actName, effName), key, val) 
		or UPar.SeqHookRunSafe('UParEffVarPreviewColor', actName, effName, key, val)
	
		if keyColor == false then 
			continue 
		end

		local temp = UPar.SeqHookRunSafe(string.format('UParEffVarPreviewWidget_%s_%s', actName, effName), key, val, preview, keyColor) 
		or UPar.SeqHookRunSafe('UParEffVarPreviewWidget', actName, effName, key, val, preview, keyColor)
	end
	
	preview:Help('')

	return mainPanel
end

function EffectManager:CreateEditor(effect, node)
	if not istable(effect) then
		ErrorNoHaltWithStack(string.format('Invalid effect "%s" (not table)', effect))
		return
	end

	local effName = effect.Name
	local actName = self.actName
	local linkName = effect.linkName

	local mainPanel = vgui.Create('DPanel')
	if IsValid(self.div) then 
		if IsValid(self.div:GetRight()) then self.div:GetRight():Remove() end
		self.div:SetRight(mainPanel)
	end

	local obj = effect
	local scrollPanel = vgui.Create('DScrollPanel', mainPanel)
	local editor = vgui.Create('DForm', scrollPanel)

	local playButton = vgui.Create('DButton', mainPanel)
	playButton:Dock(TOP)
	playButton:DockMargin(0, 5, 0, 5)
	playButton:SetText('#upgui.play_save')
	playButton:SetIcon('icon16/cd_go.png')
	playButton.DoClick = function()
		self.custTree:OnDoubleClick(node)
	end

	scrollPanel:Dock(FILL)
	editor:Dock(FILL)
	editor:SetLabel(language.GetPhrase('#upgui.link') .. '-' .. tostring(obj.linkName))
	editor.obj = obj
	editor.OnRemove = function(self)
		self.obj = nil
	end
	editor.Update = function(self, key, newVal)
		if not istable(self.obj) then
			print(string.format('Invalid obj "%s" (not table)', self.obj)) 
			return 
		end
		print(string.format('Update "%s" to "%s"', key, newVal))
		self.obj[key] = newVal
	end

	
	local keys = {}
	for k, _ in pairs(obj) do table.insert(keys, k) end
	table.sort(keys)

	for _, key in ipairs(keys) do
		local val = obj[key]

		local keyColor = UPar.SeqHookRunSafe(string.format('UParEffVarEditorColor_%s_%s', actName, linkName), key, val) 
		or UPar.SeqHookRunSafe('UParEffVarEditorColor', actName, linkName, key, val)
	
		if keyColor == false then 
			continue 
		end

		local temp = UPar.SeqHookRunSafe(string.format('UParEffVarEditorWidget_%s_%s', actName, linkName), key, val, editor, keyColor) 
		or UPar.SeqHookRunSafe('UParEffVarEditorWidget', actName, linkName, key, val, editor, keyColor)
	end
	
	editor:Help('')

	return mainPanel
end


function EffectManager:OnRemove()
	local layout = Vector()
	layout[1] = IsValid(self.div) and self.div:GetLeftWidth() or 250
	layout[2] = IsValid(self.div2) and self.div2:GetTopHeight() or 200
	UPar.LRUSet('UI_EffectEditor_Layout', layout)


	self.actName = nil
	self.div = nil
	self.div2 = nil
	self.effTree = nil
	self.custTree = nil
end

vgui.Register('UParEffectManager', EffectManager, 'DPanel')
EffectManager = nil


UPar.SeqHookAdd('UParEffVarPreviewColor', 'default', function(_, _, key, val)
	if key == 'AAAACreat' or key == 'AAAContrib' or key == 'AAADesc' then
		return lightblue
	end
end, 10)

UPar.SeqHookAdd('UParEffVarPreviewWidget', 'default', function(_, _, key, val, preview, keyColor)
	local label = nil
	if key == 'AAADesc'  then 
		label = preview:Help(string.format('%s = %s', UPar.SnakeTranslate(key), language.GetPhrase(tostring(val))))
	else
		label = preview:Help(string.format('%s = %s', UPar.SnakeTranslate(key), val))
	end

	if IsColor(keyColor) and IsValid(label) then 
		label:SetColor(keyColor) 
	end
	
	return true
end, 10)


UPar.SeqHookAdd('UParEffVarEditorColor', 'default', function(_, _, key, val)
	if key == 'linkName' or key == 'linkAct' or key == 'Name' then
		return false
	end

	return !(isfunction(val) or ismatrix(val) or isentity(val) or ispanel(val) or istable(val))
end, 10)


UPar.SeqHookAdd('UParEffVarEditorWidget', 'default', function(_, _, key, val, editor, _)
	if key == 'VManipAnim' or key == 'VMLegsAnim' then
		local label = editor:Help(UPar.SnakeTranslate(key))

		-- 针对特殊的键名进行特殊处理
		local target = key == 'VManipAnim' and VManip.Anims or VMLegs.Anims
		local anims = {}
		for a, _ in pairs(target) do table.insert(anims, a) end
		table.sort(anims)
		
		local comboBox = vgui.Create('DComboBox', editor)
		for _, a in ipairs(anims) do comboBox:AddChoice(a, nil, a == val) end
		comboBox.OnSelect = function(_, _, newVal) editor:Update(key, newVal) end

		editor:AddItem(comboBox)

		return true
	elseif isstring(val) then
		local label = editor:Help(UPar.SnakeTranslate(key))

		local textEntry = vgui.Create('DTextEntry', editor)
		textEntry:SetText(val)
		textEntry.OnChange = function()
			local newVal = textEntry:GetText()
			editor:Update(key, newVal)
		end

		editor:AddItem(textEntry)

		return true
	elseif isnumber(val) then
		local label = editor:Help(UPar.SnakeTranslate(key))
		local numberWang = vgui.Create('DNumberWang', editor)
		numberWang:SetValue(val)
		numberWang.OnValueChanged = function(_, newVal)
			editor:Update(key, newVal)
		end
		numberWang:SetInterval(0.5)
		numberWang:SetDecimals(2)
		numberWang:SetMinMax(-10000, 10000)

		editor:AddItem(numberWang)

		return true
	elseif isbool(val) then
		local label = editor:Help(UPar.SnakeTranslate(key))

		local checkBox = vgui.Create('DCheckBoxLabel', editor)
		checkBox:SetChecked(val)
		checkBox:SetText('')
		checkBox.OnChange = function(_, newVal)
			editor:Update(key, newVal)
		end

		editor:AddItem(checkBox)

		return true
	elseif isvector(val) then
		local label = editor:Help(UPar.SnakeTranslate(key))

		local vecEditor = vgui.Create('UParVecEditor', editor)
		vecEditor:SetValue(val)

		vecEditor.OnChange = function(_, newVal)
			editor:Update(key, newVal)
		end
		
		editor:AddItem(vecEditor)

		return true
	elseif isangle(val) then
		local label = editor:Help(UPar.SnakeTranslate(key))

		local angEditor = vgui.Create('UParAngEditor', editor)
		angEditor:SetValue(val)

		angEditor.OnChange = function(_, newVal)
			editor:Update(key, newVal)
		end

		editor:AddItem(angEditor)

		return true
	else
		local label = editor:Help(UPar.SnakeTranslate(key))

		editor:ControlHelp('unknown type')
		return true
	end
end, 10)