--[[
	作者:白狼
	2025 12 13
--]]

-- ==================== 简单树 ===============
local EasyTree = {}

function EasyTree:OnNodeSelected(selNode)
	local clicktime = CurTime()
	
	self:OnSelected(selNode)
	if self.selNodeLast ~= selNode then
		self:OnSelectedChange(selNode)
	elseif clicktime - (self.clickTimeLast or 0) < 0.2 then
		self:OnDoubleClick(selNode)

		self.clickTimeLast = nil
		return
	end

	self.selNodeLast = selNode
	self.clickTimeLast = clicktime
end

function EasyTree:OnRemove()
	self.selNodeLast = nil
	self.clickTimeLast = nil
end

EasyTree.OnSelected = UPar.emptyfunc
EasyTree.OnDoubleClick = UPar.emptyfunc
EasyTree.OnSelectedChange = UPar.emptyfunc

vgui.Register('UParEasyTree', EasyTree, 'DTree')
EasyTree = nil