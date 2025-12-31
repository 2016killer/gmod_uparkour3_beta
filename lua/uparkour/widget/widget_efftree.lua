--[[
	作者:白狼
	2025 12 17
--]]

-- ==================== 特效树 ===============
local EffTree = {}

function EffTree:Init2(actName)
	self.actName = actName
	self:Refresh()
end

function EffTree:OnDoubleClick(node)
	self:Take(node)
	self:Play(node) 
	self:HitNode(node)
end

function EffTree:Refresh()
	self:Clear()

	local keys = {}
	local Effects = UPar.GetEffects(self.actName)
	
	if not istable(Effects) then
		return
	end
	
	for k, v in pairs(Effects) do table.insert(keys, k) end
	table.sort(keys)

	self.EffNames = table.Flip(keys)
	
	local actName = self.actName
	local usingName = UPar.GetPlyUsingEffName(LocalPlayer(), actName)

	for _, effName in pairs(keys) do
		local effect = Effects[effName]

		if not istable(effect) then
			ErrorNoHaltWithStack(string.format('Invalid effect named "%s" (not table)', effName))
			continue
		end

		local label = isstring(effect.label) and effect.label or effName
		local icon = isstring(effect.icon) and effect.icon or 'icon16/attach.png'

		local node = self:AddNode(label, icon)
		node.effName = effName
		node.icon = icon

		local playButton = vgui.Create('DButton', node)
		playButton:SetSize(60, 18)
		playButton:Dock(RIGHT)
		playButton:SetText('#upgui.play')
		playButton:SetIcon('icon16/cd_go.png')
		playButton.DoClick = function() 
			self:Take(node)
			self:Play(node) 
			self:HitNode(node)
		end

		if usingName ~= 'CACHE' and usingName == effName then
			self.curSelNode = node
			node:SetIcon('icon16/accept.png')
		end
	end
end

function EffTree:Play(node)
	local actName = self.actName
	local effName = node.effName

	UPar.EffectTest(LocalPlayer(), actName, effName)
	UPar.CallServerEffectTest(actName, effName)

	self:OnPlay(node)
end

function EffTree:Take(node)
	local actName = self.actName
	local effName = node.effName

	local cfg = {[actName] = effName}
	UPar.PushPlyEffSetting(LocalPlayer(), cfg, nil)
	UPar.SaveUserEffCfgToDisk()
	UPar.CallServerPushPlyEffSetting(cfg, nil)
		
	self:OnTake(node)
end

function EffTree:HitNode(node)
	if IsValid(self.curSelNode) then
		self.curSelNode:SetIcon(self.curSelNode.icon)
	end

	if IsValid(node) then
		node:SetIcon('icon16/accept.png')
	end

	self.curSelNode = node
	self:OnHitNode(node)
end

function EffTree:OnRemove()
	self.actName = nil
	self.curSelNode = nil
	self.EffNames = nil
end

EffTree.OnHitNode = UPar.emptyfunc
EffTree.OnPlay = UPar.emptyfunc
EffTree.OnTake = UPar.emptyfunc
EffTree.OnRefresh = UPar.emptyfunc
vgui.Register('UParEffTree', EffTree, 'UParEasyTree')
EffTree = nil
