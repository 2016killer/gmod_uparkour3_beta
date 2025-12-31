--[[
	作者:白狼
	2025 12 09
--]]

-- ==================== 向量输入框 ===============
local ColorEditor = {}
function ColorEditor:Init()
	local inputR = vgui.Create('DNumberWang', self)
	local inputG = vgui.Create('DNumberWang', self)
	local inputB = vgui.Create('DNumberWang', self)
	local inputA = vgui.Create('DNumberWang', self)

	inputR.OnValueChanged = function(_, newVal)
		if IsColor(self.bindColor) then self.bindColor.r = newVal end
		self:OnChange(self:GetValue())
	end

	inputG.OnValueChanged = function(_, newVal)
		if IsColor(self.bindColor) then self.bindColor.g = newVal end
		self:OnChange(self:GetValue())
	end

	inputB.OnValueChanged = function(_, newVal)
		if IsColor(self.bindColor) then self.bindColor.b = newVal end
		self:OnChange(self:GetValue())
	end

	inputA.OnValueChanged = function(_, newVal)
		if IsColor(self.bindColor) then self.bindColor.a = newVal end
		self:OnChange(self:GetValue())
	end

	self.inputR = inputR
	self.inputG = inputG
	self.inputB = inputB
	self.inputA = inputA

	self:OnSizeChanged(self:GetWide(), self:GetTall())


	inputR:SetMinMax(0, 255)
	inputG:SetMinMax(0, 255)
	inputB:SetMinMax(0, 255)
	inputA:SetMinMax(0, 255)

	inputR:SetDecimals(0)
	inputG:SetDecimals(0)
	inputB:SetDecimals(0)
	inputA:SetDecimals(0)

	inputR:SetInterval(1)
	inputG:SetInterval(1)
	inputB:SetInterval(1)
	inputA:SetInterval(1)

	// self.UUID = 'ColorEditor-' .. UPar.MiniUUID()
end

function ColorEditor:OnSizeChanged(newWidth, newHeight)
	local div = newWidth / 4

	self.inputR:SetPos(0, 0)
	self.inputG:SetPos(div, 0)
	self.inputB:SetPos(div * 2, 0)
	self.inputA:SetPos(div * 3, 0)

	self.inputR:SetWidth(div)
	self.inputG:SetWidth(div)
	self.inputB:SetWidth(div)
	self.inputA:SetWidth(div)
end

function ColorEditor:SetValue(color)
	if not IsColor(color) then 
		error(string.format('color "%s" is not a Color\n', color))
		return 
	end

	self.inputR:SetValue(color.r)
	self.inputG:SetValue(color.g)
	self.inputB:SetValue(color.b)
	self.inputA:SetValue(color.a)
	self.bindColor = color
end

function ColorEditor:GetValue()
	return IsColor(self.bindColor) and self.bindColor or Color(
		self.inputR:GetValue(), 
		self.inputG:GetValue(), 
		self.inputB:GetValue(),
		self.inputA:GetValue()
	)
end

function ColorEditor:SetConVar(cvName)
	self.OnChange = UPar.emptyfunc

	if not isstring(cvName) then
		self.cvName = nil
		return
	end

	self.cvName = cvName
	local cvar = GetConVar(cvName)
	local color = string.ToColor(cvar and cvar:GetString() or '0 0 0 255')
	self:SetValue(color)
	self.OnChange = self.ChangeCVar
end



function ColorEditor:Think()
	-- cvars.AddChangeCallback 没法稳定触发
	if CurTime() < (self.NEXT or 0) then 
		return 
	end

	self.NEXT = CurTime() + 0.5

	local cvar = isstring(self.cvName) and GetConVar(self.cvName)
	if cvar then
		local oldChange = self.OnChange
		self.OnChange = UPar.emptyfunc
		self:SetValue(string.ToColor(cvar:GetString()))
		self.OnChange = oldChange
	end
end

function ColorEditor:ChangeCVar(newVal)
	if not isstring(self.cvName) then
		return false
	end

	RunConsoleCommand(self.cvName, tostring(newVal))

	return true
end

function ColorEditor:OnRemove()
	self.NEXT = nil
	self.cvName = nil
	// self.UUID = nil
	self.inputR = nil
	self.inputG = nil
	self.inputB = nil
	self.inputA = nil
	self.bindColor = nil
end

ColorEditor.OnChange = UPar.emptyfunc

vgui.Register('UParColorEditor', ColorEditor, 'DPanel')
ColorEditor = nil