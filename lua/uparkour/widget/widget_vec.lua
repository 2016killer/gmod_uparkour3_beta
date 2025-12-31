--[[
	作者:白狼
	2025 12 09
--]]

-- ==================== 向量输入框 ===============
local VecEditor = {}
function VecEditor:Init()
	local inputX = vgui.Create('DNumberWang', self)
	local inputY = vgui.Create('DNumberWang', self)
	local inputZ = vgui.Create('DNumberWang', self)

	inputX.OnValueChanged = function(_, newVal)
		if isvector(self.bindVec) then self.bindVec[1] = newVal end
		self:OnChange(self:GetValue())
	end

	inputY.OnValueChanged = function(_, newVal)
		if isvector(self.bindVec) then self.bindVec[2] = newVal end
		self:OnChange(self:GetValue())
	end

	inputZ.OnValueChanged = function(_, newVal)
		if isvector(self.bindVec) then self.bindVec[3] = newVal end
		self:OnChange(self:GetValue())
	end

	self.inputX = inputX
	self.inputY = inputY
	self.inputZ = inputZ

	self:OnSizeChanged(self:GetWide(), self:GetTall())

	self:SetInterval(0.5)
	self:SetDecimals(2)
	self:SetMinMax(-10000, 10000)

	// self.UUID = 'VecEditor-' .. UPar.MiniUUID()
end

function VecEditor:OnSizeChanged(newWidth, newHeight)
	local div = newWidth / 3

	self.inputX:SetPos(0, 0)
	self.inputY:SetPos(div, 0)
	self.inputZ:SetPos(div * 2, 0)

	self.inputX:SetWidth(div)
	self.inputY:SetWidth(div)
	self.inputZ:SetWidth(div)
end

function VecEditor:SetValue(vec)
	if not isvector(vec) then 
		error(string.format('vec "%s" is not a vector\n', vec))
		return 
	end

	self.inputX:SetValue(vec[1])
	self.inputY:SetValue(vec[2])
	self.inputZ:SetValue(vec[3])
	self.bindVec = vec
end

function VecEditor:GetValue()
	return isvector(self.bindVec) and self.bindVec or Vector(
		self.inputX:GetValue(), 
		self.inputY:GetValue(), 
		self.inputZ:GetValue()
	)
end

function VecEditor:SetMinMax(min, max)
	self.inputX:SetMinMax(min, max)
	self.inputY:SetMinMax(min, max)
	self.inputZ:SetMinMax(min, max)
end

function VecEditor:SetDecimals(decimals)
	self.inputX:SetDecimals(decimals)
	self.inputY:SetDecimals(decimals)
	self.inputZ:SetDecimals(decimals)
end

function VecEditor:SetInterval(interval)
	self.inputX:SetInterval(interval)
	self.inputY:SetInterval(interval)
	self.inputZ:SetInterval(interval)
end

function VecEditor:SetMin(min)
	self.inputX:SetMin(min)
	self.inputY:SetMin(min)
	self.inputZ:SetMin(min)
end

function VecEditor:SetMax(max)
	self.inputX:SetMax(max)
	self.inputY:SetMax(max)
	self.inputZ:SetMax(max)
end

function VecEditor:SetFraction(frac)
	self.inputX:SetFraction(frac)
	self.inputY:SetFraction(frac)
	self.inputZ:SetFraction(frac)
end

function VecEditor:SetConVar(cvName)
	self.OnChange = UPar.emptyfunc

	if not isstring(cvName) then
		self.cvName = nil
		return
	end

	self.cvName = cvName
	local cvar = GetConVar(cvName)

	local vec = Vector(cvar and cvar:GetString() or '0 0 0')
	self:SetValue(vec)
	self.OnChange = self.ChangeCVar
end

function VecEditor:Think()
	-- cvars.AddChangeCallback 没法稳定触发
	if CurTime() < (self.NEXT or 0) then 
		return 
	end

	self.NEXT = CurTime() + 0.5

	local cvar = isstring(self.cvName) and GetConVar(self.cvName)
	if cvar then
		local oldChange = self.OnChange
		self.OnChange = UPar.emptyfunc
		self:SetValue(Vector(cvar:GetString()))
		self.OnChange = oldChange
	end
end

function VecEditor:ChangeCVar(newVal)
	if not isstring(self.cvName) then
		return false
	end

	RunConsoleCommand(self.cvName, tostring(newVal))

	return true
end

function VecEditor:OnRemove()
	self.NEXT = nil
	self.cvName = nil
	// self.UUID = nil
	self.inputX = nil
	self.inputY = nil
	self.inputZ = nil
	self.bindVec = nil
end

VecEditor.OnChange = UPar.emptyfunc

vgui.Register('UParVecEditor', VecEditor, 'DPanel')
VecEditor = nil