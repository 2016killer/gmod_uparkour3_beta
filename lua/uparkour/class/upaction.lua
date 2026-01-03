--[[
	作者:白狼
	2025 12 10
--]]

UPar.ActInstances = UPar.ActInstances or {}
UPar.EffInstances = UPar.EffInstances or {}

UPAction = UPAction or {}
UPAction.__index = UPAction

local UPAction = UPAction
local isinstance = UPar.IsInstance
local Instances = UPar.ActInstances
local EffInstances = UPar.EffInstances

local function sanitizeConVarName(name)
    return 'upact_' .. string.gsub(name, '[\\/:*?"<>|]', '_')
end

local function isupaction(obj)
    return isinstance(obj, UPAction)
end

function UPAction:Register(name, initData, new)
    assert(isstring(name), string.format('Invalid name "%s" (not a string)', name))
    assert(not string.find(name, '[\\/:*?"<>|]'), string.format('Invalid name "%s" (contains invalid filename characters)', name))

    local cached = Instances[name]
    local exist = istable(cached)
    if exist then print(string.format('[UPAction]: Warning: Action "%s" already registered (overwritten)', name)) end

    new = new or not exist

    local self = new and setmetatable({}, UPAction) or cached

    if not isupaction(self) then
        setmetatable(self, UPAction)
    end 

    Instances[name] = self
    EffInstances[name] = istable(EffInstances[name]) and EffInstances[name] or {}

    if istable(initData) then
        for k, v in pairs(initData) do
            self[k] = v
        end
    end

    self.Name = name
 
    self:InitCVarDisabled(self.defaultDisabled)
    self:InitCVarPredictionMode(self.defaultPredictionMode)

    self.icon = CLIENT and self.icon or nil
    self.label = CLIENT and self.label or nil
    self.AAAACreat = CLIENT and self.AAAACreat or nil
    self.AAADesc = CLIENT and self.AAADesc or nil
    self.AAAContrib = CLIENT and self.AAAContrib or nil

    self.TrackId = self.TrackId or 0
    
    assert(isfunction(self.Check), string.format('Invalid field "Check" = "%s" (not a function)', self.Check))
    assert(isfunction(self.Start), string.format('Invalid field "Start" = "%s" (not a function)', self.Start))
    assert(isfunction(self.Think), string.format('Invalid field "Think" = "%s" (not a function)', self.Think))
    assert(isfunction(self.Clear), string.format('Invalid field "Clear" = "%s" (not a function)', self.Clear))
    assert(isfunction(self.OnValCltPredRes), string.format('Invalid field "OnValCltPredRes" = "%s" (not a function)', self.OnValCltPredRes))

    if new then hook.Run('UParRegisterAction', name, self) end
    
    return self
end

function UPAction:Check(...)
    UPar.printinputs(string.format('act.Check is empty: "%s", TrackId: %s', self.Name, self.TrackId), ...)
    return {argx = 1}
end

function UPAction:Start(...)
    UPar.printinputs(string.format('act.Start is empty: "%s", TrackId: %s', self.Name, self.TrackId), ...)
end

function UPAction:Think(...)
    UPar.printinputs(string.format('act.Think is empty: "%s", TrackId: %s', self.Name, self.TrackId), ...)
    return true
end

function UPAction:Clear(...)
    UPar.printinputs(string.format('act.Clear is empty: "%s", TrackId: %s', self.Name, self.TrackId), ...)
end

function UPAction:OnValCltPredRes(...)
    return true
end

function UPAction:GetUsingEffect(ply)
    local actName = self.Name
    local effName = ply.upeff_cfg[actName] or 'default'
    if effName == 'CACHE' then
        return ply.upeff_cache[actName]
    else
        return EffInstances[actName][effName]
    end
end

function UPAction:InitCVarDisabled(default)
    local cvName = sanitizeConVarName(self.Name) .. '_disabled'

    if self.CV_Disabled and self.CV_Disabled:GetName() ~= cvName then 
        self.CV_Disabled = nil
    end

    if default == nil then 
        return 
    end

    local cvFlags = {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY}
    local cvar = CreateConVar(cvName, default and '1' or '0', cvFlags, '')
    self.CV_Disabled = cvar
end

function UPAction:GetDisabled()
    if not self.CV_Disabled then return nil end
    return self.CV_Disabled:GetBool()
end

function UPAction:SetDisabled(disabled)
    if not self.CV_Disabled then 
        print(string.format('[UPAction]: Warning: Action "%s" has no CV_Disabled', self.Name))
        return 
    end
    if SERVER then 
        self.CV_Disabled:SetBool(!!disabled)
    elseif CLIENT then
        RunConsoleCommand(self.CV_Disabled:GetName(), (!!disabled) and '1' or '0')
    end
end

function UPAction:InitCVarPredictionMode(default)
    local cvName = sanitizeConVarName(self.Name) .. '_pred_mode'
    
    if self.CV_PredictionMode and self.CV_PredictionMode:GetName() ~= cvName then 
        self.CV_PredictionMode = nil
    end

    if default == nil then 
        return 
    end

    local cvFlags = {FCVAR_ARCHIVE, FCVAR_REPLICATED, FCVAR_SERVER_CAN_EXECUTE, FCVAR_NOTIFY}
    local cvar = CreateConVar(cvName, default and '1' or '0', cvFlags, '')
    self.CV_PredictionMode = cvar
end

function UPAction:GetPredictionMode()
    if not self.CV_PredictionMode then return nil end
    return self.CV_PredictionMode:GetBool()
end

function UPAction:SetPredictionMode(predictionMode)
    if not self.CV_PredictionMode then 
        print(string.format('[UPAction]: Warning: Action "%s" has no CV_PredictionMode', self.Name))
        return 
    end

    if SERVER then 
        self.CV_PredictionMode:SetBool(!!predictionMode)
    elseif CLIENT then
        RunConsoleCommand(self.CV_PredictionMode:GetName(), (!!predictionMode) and '1' or '0')
    end
end

function UPAction:AddConVar(cvCfg)
    assert(istable(cvCfg), string.format('Invalid cvCfg "%s" (not a table)', cvCfg))

    self.ConVars = istable(self.ConVars) and self.ConVars or {}
    
    if cvCfg.widget ~= 'Label' then
        local cvName = cvCfg.name
        local cvDefault = cvCfg.default or '0'
        local isclient = cvCfg.client

        assert(isstring(cvName), string.format('Invalid field "name" (not a string), name = "%s"', cvName))
        assert(isstring(cvDefault), string.format('Invalid field "default" (not a string), name = "%s"', cvName))
        assert(isclient == nil or isbool(isclient), string.format('Invalid field "client" (must be a boolean or nil), name = "%s"', cvName))

        if isclient == nil then
            self.ConVars[cvName] = CreateConVar(cvName, cvDefault, { FCVAR_ARCHIVE, FCVAR_CLIENTCMD_CAN_EXECUTE, FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE })
        elseif SERVER and isclient == false then
            self.ConVars[cvName] = CreateConVar(cvName, cvDefault, { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE })
        elseif CLIENT and isclient == true then
            self.ConVars[cvName] = CreateClientConVar(cvName, cvDefault, true, false) 
        end
    end

    if SERVER then
        self.ConVarsWidget = nil
    elseif CLIENT then
        self.ConVarsWidget = istable(self.ConVarsWidget) and self.ConVarsWidget or {}
        table.insert(self.ConVarsWidget, cvCfg) 
    end
end

function UPAction:RemoveConVar(cvName)
    assert(isstring(cvName), string.format('Invalid cvName "%s" (not a string)', cvName))

    self.ConVarsWidget = CLIENT and (istable(self.ConVarsWidget) and self.ConVarsWidget or {}) or nil
    self.ConVars = istable(self.ConVars) and self.ConVars or {}
    
    self.ConVars[cvName] = nil
    if CLIENT then
        for i = #self.ConVarsWidget, 1, -1 do
            if self.ConVarsWidget[i].name == cvName then
                table.remove(self.ConVarsWidget, i)
            end
        end
    end
end

function UPAction:InitConVars(config)
    assert(istable(config), string.format('Invalid config "%s" (not a table)', config))

    self.ConVars = {}
    self.ConVarsWidget = CLIENT and {} or nil

    for i, v in ipairs(config) do self:AddConVar(v) end
end

if CLIENT then
    function UPAction:RegisterPreset(name, preset)
        assert(isstring(name), string.format('Invalid name "%s" (not a string)', name))
        assert(istable(preset), string.format('Invalid preset "%s" (not a table)', preset))
        assert(istable(preset.values), string.format('Invalid values "%s" (not a table)', preset.values))

        for cvName, val in pairs(preset.values) do
            assert(isstring(cvName), string.format('Invalid cvName "%s" (not a string)', cvName))
            assert(isstring(val), string.format('Invalid val "%s" (not a string), cvName = "%s"', val, cvName))
        end

        self.ConVarsPreset = istable(self.ConVarsPreset) and self.ConVarsPreset or {}

        self.ConVarsPreset[name] = preset
    end
end

UPar.GetAllActions = function() return Instances end
UPar.GetAction = function(name) return Instances[name] end
UPar.isupaction = isupaction

