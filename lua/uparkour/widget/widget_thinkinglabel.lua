--[[
	作者:白狼
	2025 12 09
--]]

-- ====================  ===============
local ThinkingLabel = {}

function ThinkingLabel:Init()
	self.NEXT = CurTime() + 0.5
	self.INTERVAL = 0.5
end

function ThinkingLabel:Think()
	if CurTime() < self.NEXT then 
		return 
	end

	self.NEXT = CurTime() + self.INTERVAL
	local text = self:Update()
	if isstring(text) then self:SetText(text) end
end

function ThinkingLabel:OnRemove()
	self.NEXT = nil
	self.INTERVAL = nil
end

ThinkingLabel.Update = UPar.emptyfunc

vgui.Register('UParThinkingLabel', ThinkingLabel, 'DLabel')
ThinkingLabel = nil
