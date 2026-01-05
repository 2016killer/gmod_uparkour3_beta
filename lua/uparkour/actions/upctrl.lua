--[[
	作者:白狼
	2025 12 20
]]--

-- ==================== 总控制 ===============
local CallAct = UPar.CallAct
local GetActKV = UPar.GetActKV

local controller = UPAction:Register('upctrl', {
	AAAACreat = '白狼',
	AAADesc = '#upctrl.desc',
	icon = 'upgui/uparkour.jpg',
	label = '#upctrl',
	defaultDisabled = false,
	defaultPredictionMode = false
})

controller:InitConVars({
	{
		name = 'upctrl_vt_evlen_f',
		default = '0.5',
		widget = 'NumSlider',
		min = 0,
		max = 5,
		decimals = 2,
		help = true,
	},

	{
		name = 'upctrl_vtd_thr_f',
		default = '0.15',
		widget = 'NumSlider',
		min = 0,
		max = 5,
		decimals = 2,
		help = true,
	},

	{
		name = 'upctrl_los_cos',
		default = '0.64',
		widget = 'NumSlider',
		min = 0, max = 1, decimals = 2,
		help = true
	},

	{
		name = 'upctrl_tick_time',
		default = '0.1',
		widget = 'NumberWang',
		min = 0, max = 3600, decimals = 3, interval = 0.05,
	}
})

if SERVER then
	cvars.AddChangeCallback(controller.CV_PredictionMode:GetName(), function(name)
		PrintMessage(HUD_PRINTTALK, name .. ' 需要 重启服务器 才会生效')
	end, 'notify')
end

controller.ACT_FLAGS = {
	['upvaultdl'] = VAULTDL_FLAG,
	['uplowclimb'] = LOW_CLIMB_FLAG,
	['upvaultdh'] = VAULTDH_FLAG,
	['uphighclimb'] = HIGH_CLIMB_FLAG
}

local VAULTDL_FLAG = 0x01
local LOW_CLIMB_FLAG = 0x02
local VAULTDH_FLAG = 0x04
local HIGH_CLIMB_FLAG = 0x08
local CMD_ADD = 'upctrl_add'
local CMD_REMOVE = 'upctrl_remove'
local THINK_HOOK_IDENTITY = 'upctrl.think'
local RESET_HOOK_IDENTITY = 'upctrl.reset'

function controller:Trigger(ply, actFlag)
	if not isentity(ply) or not IsValid(ply) then 
		print('[upctrl] Trigger: ply is not valid')
		return 
	end

	if ply:GetMoveType() ~= MOVETYPE_WALK or not ply:Alive() then 
		return 
	end

	actFlag = isnumber(actFlag) and actFlag or (ply.upctrl_act_flags or 0)

	local refVel = ply:GetVelocity()

	local lowObsTrace = nil
	local lowClimbTrace = nil

	if bit.band(actFlag, VAULTDL_FLAG) ~= 0 and CallAct('upvaultdl', 'GetDisabled') == false then
		lowObsTrace, lowClimbTrace = CallAct('uplowclimb', 'Detector', ply)
		if lowObsTrace and lowClimbTrace then
			local succ = UPar.Trigger(ply, 'upvaultdl', nil, lowObsTrace, lowClimbTrace, refVel)
			if succ then return succ end
		else
			lowObsTrace, lowClimbTrace = true, true
		end 
	end

	if bit.band(actFlag, LOW_CLIMB_FLAG) ~= 0 and CallAct('uplowclimb', 'GetDisabled') == false then
		if lowClimbTrace ~= true then
			if lowClimbTrace then
				local moveData = CallAct('uplowclimb', 'GetMoveData', ply, lowObsTrace, lowClimbTrace, refVel)
				local succ = UPar.Trigger(ply, 'uplowclimb', moveData)
				if succ then return succ end
			else
				local succ = UPar.Trigger(ply, 'uplowclimb', nil, nil, nil, refVel)
				if succ then return succ end
			end
		end
	end

	local highObsTrace = nil
	local highClimbTrace = nil

	if bit.band(actFlag, VAULTDH_FLAG) ~= 0 and CallAct('upvaultdh', 'GetDisabled') == false then
		highObsTrace, highClimbTrace = CallAct('uphighclimb', 'Detector', ply)
		if highObsTrace and highClimbTrace then
			local succ = UPar.Trigger(ply, 'upvaultdh', nil, highObsTrace, highClimbTrace, refVel)
			if succ then return succ end
		else
			highObsTrace, highClimbTrace = true, true
		end 
	end
	
	if bit.band(actFlag, HIGH_CLIMB_FLAG) ~= 0 and CallAct('uphighclimb', 'GetDisabled') == false then
		if highClimbTrace ~= true then
			if highClimbTrace then
				local moveData = CallAct('uphighclimb', 'GetMoveData', ply, highObsTrace, highClimbTrace, refVel)
				local succ = UPar.Trigger(ply, 'uphighclimb', moveData)
				if succ then return succ end
			else
				local succ = UPar.Trigger(ply, 'uphighclimb', nil, nil, nil, refVel)
				if succ then return succ end
			end
		end
	end

end


local function temp_add_act_flag(ply, cmd, args)
	local actFlag = tonumber(args[1])
	if not actFlag then 
		print(string.format('Invalid actFlag "%s" (not a number)', args[1]))
		return
	end

	ply.upctrl_act_flags = bit.bor(ply.upctrl_act_flags or 0, actFlag)
	controller:Trigger(ply)
end

local function temp_remove_act_flag(ply, cmd, args)
	local actFlag = tonumber(args[1])
	if not actFlag then 
		actFlag = 0xff
		print('[upctrl]: Remove all actFlags')
		return
	end
			
	ply.upctrl_act_flags = bit.band(ply.upctrl_act_flags or 0, bit.bnot(actFlag))
end

if SERVER then
	if controller:GetPredictionMode() then
		hook.Remove('PlayerPostThink', THINK_HOOK_IDENTITY)
		hook.Remove('PlayerSpawn', RESET_HOOK_IDENTITY)
		cvars.RemoveChangeCallback('upctrl_tick_time', 'default')
		concommand.Remove(CMD_ADD)
		concommand.Remove(CMD_REMOVE)
	else
		local interval = GetConVar('upctrl_tick_time') and GetConVar('upctrl_tick_time'):GetFloat() or 0.1
		local nextThinkTime = 0

		cvars.AddChangeCallback('upctrl_tick_time', function(name, old, new)
			local newVal = tonumber(new)
			if not newVal then return end
			interval = newVal 
			nextThinkTime = CurTime() + interval
		end, 'default')

		hook.Add('PlayerSpawn', RESET_HOOK_IDENTITY, function(ply)
			ply.upctrl_act_flags = 0
		end)

		hook.Add('PlayerPostThink', THINK_HOOK_IDENTITY, function(ply)
			if CurTime() < nextThinkTime then return end
			nextThinkTime = CurTime() + interval

			controller:Trigger(ply)
		end)

		concommand.Add(CMD_ADD, temp_add_act_flag)
		concommand.Add(CMD_REMOVE, temp_remove_act_flag)
	end
elseif CLIENT then
	if not controller:GetPredictionMode() then
		hook.Remove('Think', THINK_HOOK_IDENTITY)
		concommand.Remove(CMD_ADD)
		concommand.Remove(CMD_REMOVE)
	else
		local interval = GetConVar('upctrl_tick_time')
		local nextThinkTime = 0

		hook.Add('Think', THINK_HOOK_IDENTITY, function()
			if CurTime() < nextThinkTime then return end
			nextThinkTime = CurTime() + interval:GetFloat()

			controller:Trigger(LocalPlayer())
		end)

		concommand.Add(CMD_ADD, temp_add_act_flag)
		concommand.Add(CMD_REMOVE, temp_remove_act_flag)
	end
end

temp_add_act_flag = nil
temp_remove_act_flag = nil
THINK_HOOK_IDENTITY = nil
RESET_HOOK_IDENTITY = nil


if CLIENT then
	UPKeyboard.Register('upctrl_lowclimb', '[33,65]')
	UPKeyboard.Register('upctrl_highclimb', '[33,65]')
	UPKeyboard.Register('upctrl_vaultdl', '[33,65]')
	UPKeyboard.Register('upctrl_vaultdh', '[33,79,65]')

	UPar.SeqHookAdd('UParKeyPress', 'upctrl', function(eventflags)
		local actFlag = 0
		actFlag = bit.bor(actFlag, eventflags['upctrl_lowclimb'] and LOW_CLIMB_FLAG or 0)
		actFlag = bit.bor(actFlag, eventflags['upctrl_highclimb'] and HIGH_CLIMB_FLAG or 0)
		actFlag = bit.bor(actFlag, eventflags['upctrl_vaultdl'] and VAULTDL_FLAG or 0)
		actFlag = bit.bor(actFlag, eventflags['upctrl_vaultdh'] and VAULTDH_FLAG or 0)

		if actFlag == 0 then
			return
		end

		RunConsoleCommand(CMD_ADD, actFlag)

		eventflags['upctrl_lowclimb'] = UPKeyboard.KEY_EVENT_FLAGS.HANDLED
		eventflags['upctrl_highclimb'] = UPKeyboard.KEY_EVENT_FLAGS.HANDLED
		eventflags['upctrl_vaultdl'] = UPKeyboard.KEY_EVENT_FLAGS.HANDLED
		eventflags['upctrl_vaultdh'] = UPKeyboard.KEY_EVENT_FLAGS.HANDLED
	end)

	UPar.SeqHookAdd('UParKeyRelease', 'upctrl', function(eventflags)
		local actFlag = 0
		actFlag = bit.bor(actFlag, eventflags['upctrl_lowclimb'] and LOW_CLIMB_FLAG or 0)
		actFlag = bit.bor(actFlag, eventflags['upctrl_highclimb'] and HIGH_CLIMB_FLAG or 0)
		actFlag = bit.bor(actFlag, eventflags['upctrl_vaultdl'] and VAULTDL_FLAG or 0)
		actFlag = bit.bor(actFlag, eventflags['upctrl_vaultdh'] and VAULTDH_FLAG or 0)

		if actFlag == 0 then
			return
		end

		RunConsoleCommand(CMD_REMOVE, actFlag)

		eventflags['upctrl_lowclimb'] = UPKeyboard.KEY_EVENT_FLAGS.HANDLED
		eventflags['upctrl_highclimb'] = UPKeyboard.KEY_EVENT_FLAGS.HANDLED
		eventflags['upctrl_vaultdl'] = UPKeyboard.KEY_EVENT_FLAGS.HANDLED
		eventflags['upctrl_vaultdh'] = UPKeyboard.KEY_EVENT_FLAGS.HANDLED
	end)

	UPar.SeqHookAdd('UParActCVarWidget_upctrl', 'default', function(cvCfg, panel)
		local cvName = cvCfg.name
		if cvName == 'upctrl_los_cos' 
		or cvName == 'upctrl_vt_evlen_f'
		or cvName == 'upctrl_vtd_thr_f'
		then
			local created = UPar.SeqHookRun('UParActCVarWidget', 'upctrl', cvCfg, panel)
			if not created then
				return
			end

			local predi = panel:ControlHelp('')
			predi.Think = function(self)
				if CurTime() < (self.NextThinkTime or 0) then
					return
				end

				self.NextThinkTime = CurTime() + 0.5
				local cvar = UPar.GetActKV('upctrl', 'ConVars')[cvName]
				local value = nil
				if cvName == 'upctrl_los_cos' then
					value = math.Round(math.acos(controller.ConVars.upctrl_los_cos:GetFloat()) * 180 / math.pi, 2)
				elseif cvName == 'upctrl_vt_evlen_f' or cvName == 'upctrl_vtd_thr_f' then
					local min, max = LocalPlayer():GetCollisionBounds()
					local plyHeight = max[3] - min[3]
					value = math.Round(plyHeight * cvar:GetFloat(), 2)
				end

				self:SetText(string.format('%s: %s', 
					language.GetPhrase('#upgui.predi'), 
					value
				))
			end

			predi.OnRemove = function(self)
				self.NextThinkTime = nil
			end

			return true
		end
	end)
end

