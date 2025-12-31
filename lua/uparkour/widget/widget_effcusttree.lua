--[[
	作者:白狼
	2025 12 17
--]]


-- ==================== 特效树 ===============
local CustEffTree = {}

function CustEffTree:Init2(actName)
	self.actName = actName
	self:Refresh()
end

function CustEffTree:OnDoubleClick(node)
	self:Take(node)
	self:Play(node) 
	self:HitNode(node)
end

function CustEffTree:Refresh()
	self:Clear()

	local keys = UPar.GetUserCustEffFiles(self.actName) or UPar.emptyTable
	table.sort(keys)

	self.EffNames = table.Flip(keys)
	
	local actName = self.actName
	local usingName = UPar.GetPlyUsingEffName(LocalPlayer(), actName)
	local cache = UPar.GetPlyEffCache(LocalPlayer(), actName)

	for _, effName in pairs(keys) do
		local node = self:AddNode2(effName, 'icon64/tool.png')

		if istable(cache) and usingName == 'CACHE' and cache.Name == effName then
			self.curSelNode = node
			node:SetIcon('icon16/accept.png')
		end
	end

	self:OnRefresh()
end

function CustEffTree:AddNode2(effName)
	local effect = UPar.LRUGet(string.format('UI_CE_%s', effName))

	local label = nil
	local icon = nil
	if istable(effect) then
		label = isstring(effect.label) and effect.label or effName
		icon = isstring(effect.icon) and effect.icon or 'icon64/tool.png'
	else
		label = effName
		icon = 'icon64/tool.png'
	end

	local node = self:AddNode(label, icon)
	node.effName = effName
	node.icon = icon

	return node
end

function CustEffTree:InitNode(node)
	local actName = self.actName
	local effName = node.effName

	local effect = UPar.LRUGet(string.format('UI_CE_%s', effName))

	if not istable(effect) then
		effect = UPar.LoadUserCustEffFromDisk(actName, effName)

		if not istable(effect) then
			print(string.format('[UPar]: custom effect init failed, can not find custom effect named "%s" from disk', effName))
			return
		end

		UPar.InitCustomEffect(effect)

		local label = isstring(effect.label) and effect.label or effName
		local icon = isstring(effect.icon) and effect.icon or 'icon64/tool.png'
		
		node:SetText(label)
		node:SetIcon(icon)

		UPar.LRUSet(string.format('UI_CE_%s', effName), effect)
	end

	return effect
end

function CustEffTree:Play(node)
	local actName = self.actName
	local effName = node.effName

	UPar.EffectTest(LocalPlayer(), actName, 'CACHE')
	UPar.CallServerEffectTest(actName, 'CACHE')

	self:OnPlay(node)
end

function CustEffTree:Take(node)
	local actName = self.actName
	local effName = node.effName

	local effect = self:InitNode(node)

	local cfg = {[actName] = 'CACHE'}
	local cache = {[actName] = effect}

	UPar.PushPlyEffSetting(LocalPlayer(), cfg, cache)
	UPar.SaveUserEffCfgToDisk()
	UPar.SaveUserEffCacheToDisk()
	UPar.SaveUserCustEffToDisk(effect, true)
	UPar.CallServerPushPlyEffSetting(cfg, cache)
	
	self:OnTake(node)
end

function CustEffTree:OnSelectedChange(node)
	return self:InitNode(node)
end

function CustEffTree:HitNode(node)
	if IsValid(self.curSelNode) then
		self.curSelNode:SetIcon(self.curSelNode.icon)
	end

	if IsValid(node) then
		node:SetIcon('icon16/accept.png')
	end

	self.curSelNode = node
	self:OnHitNode(node)
end

function CustEffTree:OnRemove()
	self.actName = nil
	self.curSelNode = nil
	self.EffNames = nil
end

function CustEffTree:DoRightClick(node)
	local menu = DermaMenu()

	local delOpt = menu:AddOption('#upgui.delete', function()
		local actName = self.actName
		local effName = node.effName

		local succ = UPar.DeleteUserCustEff(actName, effName)
		if succ then 
			UPar.LRUDelete(string.format('UI_CE_%s', effName))
			self:Refresh()
		end
	end)
	delOpt:SetIcon('icon16/delete.png')

	local copyOpt = menu:AddOption('#upgui.copy', function()
		self:Copy(node)
	end)
	copyOpt:SetIcon('icon16/application_cascade.png')


	menu:Open()
end

function CustEffTree:Copy(node)
	local effName = node.effName
	local effect = self:InitNode(node)
	if not istable(effect) or not effect.linkName then
		notification.AddLegacy(string.format('copy failed, can not find custom effect named "%s"', effName), NOTIFY_ERROR, 5)
		surface.PlaySound('Buttons.snd10')
		return
	end

	local actName = effect.linkAct
	local linkName = effect.linkName

	Derma_StringRequest(
		'#upgui.derma.filename',           
		'',  
		string.format('Copy-%s-%s', effName, os.time()),         
		function(text)    
			if string.find(text, '[\\/:*?"<>|]') then
				error(string.format('Invalid name "%s" (contains invalid filename characters)', text))
			end

			text = string.lower(text)

			local exist = true
			for i = 0, 2 do
				local suffix = i == 0 and '' or ('_' .. tostring(i))
				local newFileName = string.format('%s%s', text, suffix)
				if not self.EffNames[newFileName] then
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

			local custName = text
			local custom = UPar.CreateUserCustEff(actName, linkName, custName, true)
			UPar.DeepInject(custom, effect)
			UPar.InitCustomEffect(custom)
			UPar.LRUSet(string.format('UI_CE_%s', custName), custom)

			self.EffNames[custName] = 1
			self:AddNode2(custName)
		end,
		nil,
		'#upgui.derma.submit',                    
		'#upgui.derma.cancel'
	)
end


CustEffTree.OnHitNode = UPar.emptyfunc
CustEffTree.OnPlay = UPar.emptyfunc
CustEffTree.OnTake = UPar.emptyfunc
CustEffTree.OnRefresh = UPar.emptyfunc
vgui.Register('UParCustEffTree', CustEffTree, 'UParEasyTree')
CustEffTree = nil
