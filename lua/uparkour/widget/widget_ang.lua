--[[
	作者:白狼
	2025 12 09
--]]
-- ==================== 角度编辑器 ===============
local AngEditor = {}
function AngEditor:Init()
	local inputPitch = vgui.Create('DNumberWang', self)
	local inputYaw = vgui.Create('DNumberWang', self)
	local inputRoll = vgui.Create('DNumberWang', self)

	inputPitch.OnValueChanged = function(_, newVal)
		if isangle(self.bindAng) then self.bindAng[1] = newVal end
		self:OnChange(self:GetValue())
	end

	inputYaw.OnValueChanged = function(_, newVal)
		if isangle(self.bindAng) then self.bindAng[2] = newVal end
		self:OnChange(self:GetValue())
	end

	inputRoll.OnValueChanged = function(_, newVal)
		if isangle(self.bindAng) then self.bindAng[3] = newVal end
		self:OnChange(self:GetValue())
	end

	self.inputPitch = inputPitch
	self.inputYaw = inputYaw
	self.inputRoll = inputRoll

	self:OnSizeChanged(self:GetWide(), self:GetTall())

	self:SetInterval(0.5)
	self:SetDecimals(2)
	self:SetMinMax(-10000, 10000)

	// self.UUID = 'AngEditor-' .. UPar.MiniUUID()
end

function AngEditor:SetValue(ang)
	if not isangle(ang) then 
		error(string.format('ang "%s" is not an angle\n', ang))
		return 
	end

	self.inputPitch:SetValue(ang[1])
	self.inputYaw:SetValue(ang[2])
	self.inputRoll:SetValue(ang[3])
	self.bindAng = ang
end

function AngEditor:GetValue()
	return isangle(self.bindAng) and self.bindAng or Angle(
		self.inputPitch:GetValue(), 
		self.inputYaw:GetValue(), 
		self.inputRoll:GetValue()
	)
end

function AngEditor:OnSizeChanged(newWidth, newHeight)
	local div = newWidth / 3
	
	self.inputPitch:SetPos(0, 0)
	self.inputYaw:SetPos(div, 0)
	self.inputRoll:SetPos(div * 2, 0)

	self.inputPitch:SetWidth(div)
	self.inputYaw:SetWidth(div)
	self.inputRoll:SetWidth(div)
end

function AngEditor:SetMinMax(min, max)
	self.inputPitch:SetMinMax(min, max)
	self.inputYaw:SetMinMax(min, max)
	self.inputRoll:SetMinMax(min, max)
end

function AngEditor:SetDecimals(decimals)
	self.inputPitch:SetDecimals(decimals)
	self.inputYaw:SetDecimals(decimals)
	self.inputRoll:SetDecimals(decimals)
end

function AngEditor:SetInterval(interval)
	self.inputPitch:SetInterval(interval)
	self.inputYaw:SetInterval(interval)
	self.inputRoll:SetInterval(interval)
end

function AngEditor:SetMin(min)
	self.inputPitch:SetMin(min)
	self.inputYaw:SetMin(min)
	self.inputRoll:SetMin(min)
end

function AngEditor:SetMax(max)
	self.inputPitch:SetMax(max)
	self.inputYaw:SetMax(max)
	self.inputRoll:SetMax(max)
end

function AngEditor:SetFraction(frac)
	self.inputPitch:SetFraction(frac)
	self.inputYaw:SetFraction(frac)
	self.inputRoll:SetFraction(frac)
end

function AngEditor:SetConVar(cvName)
	self.OnChange = UPar.emptyfunc

	if not isstring(cvName) then
		self.cvName = nil
		return
	end

	self.cvName = cvName
	local cvar = GetConVar(cvName)
	local ang = Angle(cvar and cvar:GetString() or '0 0 0')
	self:SetValue(ang)
	self.OnChange = self.ChangeCVar
end


function AngEditor:Think()
	-- cvars.AddChangeCallback 没法稳定触发
	if CurTime() < (self.NEXT or 0) then 
		return 
	end

	self.NEXT = CurTime() + 0.5

	local cvar = isstring(self.cvName) and GetConVar(self.cvName)
	if cvar then
		local oldChange = self.OnChange
		self.OnChange = UPar.emptyfunc
		self:SetValue(Angle(cvar:GetString()))
		self.OnChange = oldChange
	end
end


function AngEditor:ChangeCVar(newVal)
	if not isstring(self.cvName) then
		return false
	end

	RunConsoleCommand(self.cvName, tostring(newVal))

	return true
end

function AngEditor:OnRemove()
	self.NEXT = nil
	self.cvName = nil
	// self.UUID = nil
	self.inputPitch = nil
	self.inputYaw = nil
	self.inputRoll = nil
	self.bindAng = nil
end

AngEditor.OnChange = UPar.emptyfunc

vgui.Register('UParAngEditor', AngEditor, 'DPanel')
AngEditor = nil