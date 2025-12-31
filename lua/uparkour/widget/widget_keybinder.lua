--[[
	作者:白狼
	2025 12 15
--]]

-- ==================== 按键绑定器 ===============
local KeyBinder = {}

function KeyBinder:Init()
    self.values = {}
    self:UpdateText()
end

function KeyBinder:OnKeyCodePressed(keyCode)
end

function KeyBinder:OnKeyCodeReleased(keyCode)
    table.insert(self.values, keyCode)
    self:UpdateText2()

    if keyCode == KEY_ENTER or keyCode == KEY_PAD_ENTER then
        self:FocusPrevious()
    end
end

function KeyBinder:OnFocusChanged(gained)
    if gained then 
        self:SetEnabled(false)
        self.values = {}
        self.pressedKeys = {}
        self:UpdateText2() 
    else
        self:SetEnabled(true)
        self:OnChange(self.values)
        self:UpdateText()
    end
end

function KeyBinder:DoRightClick()
    self.values = {}
    self:OnChange(self.values)
    self:UpdateText()
end

function KeyBinder:GetValue()
    return self.values
end

function KeyBinder:SetValue(values)
    if not istable(values) then 
        error(string.format('Invalid values "%s" (not a table)', values))
    end

    local newValue = {}
    for _, v in ipairs(values) do
        if not isnumber(v) then continue end
        table.insert(newValue, v) 
    end

    self.values = newValue
    self:OnChange(self.values)
    self:UpdateText()
end
    
function KeyBinder:UpdateText()
    local text = {}

    if table.IsEmpty(self.values) then
        text[1] = 'None'
    else
        for i, v in ipairs(self.values) do
            text[i] = input.GetKeyName(v) or 'None'
        end
    end

    self:SetText(table.concat(text, ' + '))
end

function KeyBinder:UpdateText2()
    local text = {}

    if table.IsEmpty(self.values) then
        text = language.GetPhrase('upgui.widget.keyinput')
    else
        for i, v in ipairs(self.values) do
            text[i] = input.GetKeyName(v) or 'None'
        end

        text = table.concat(text, ' + ') .. ' + ..., ' .. language.GetPhrase('upgui.widget.keyinput.submit')
    end

    self:SetText(text)
end

function KeyBinder:SetConVar(cvName)
	local cvar = GetConVar(cvName)

	local keys = util.JSONToTable(cvar and cvar:GetString() or '[0]')
	keys = istable(keys) and keys or {}

    self:SetValue(keys)

	self.OnChange = function(self, newVal)
		RunConsoleCommand(cvName, util.TableToJSON(newVal))
	end
end


KeyBinder.OnChange = UPar.emptyfunc

vgui.Register('UParKeyBinder', KeyBinder, 'DTextEntry')
KeyBinder = nil