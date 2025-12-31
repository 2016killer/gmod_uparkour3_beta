<p align="center">
  <a href="./README_en.md">English</a> |
  <a href="./README.md">简体中文</a>
</p>

## Table of Contents

<a href="./UPACTION_en.md">UPAction</a>  
<a href="./UPEFFECT_en.md">UPEffect</a>  
<a href="./SERHOOK_en.md">SeqHook</a>  
<a href="./HOOK_en.md">Hook</a>  
<a href="./LRU_en.md">LRU</a>  
<a href="./CUSTOMEFFECT_en.md">Custom Effect</a>  
<a href="./UPMANIP_en.md">UPManip</a>  
<a href="./UPKEYBOARD_en.md">UPKeyboard</a>  
<a href="./FRAMELOOP_en.md">FrameLoop</a>  

# UPAction Class
```note
We should treat UPAction as a static container and must not store any runtime results in it.
```

## About UPAction Interface Implementation
We no longer use the parameter-aligned syntax from version 2.1.0. Although the sequence table performed well in network transmission, frequent unpacking is cumbersome and the code is hard to maintain—so we reverted to the version 1.0.0 approach.

This approach has many advantages: for example, persistent data can be directly stored in tables, or inheritable data can be added directly, which greatly reduces development difficulty.

However, there are also drawbacks, such as data insecurity. It’s best to determine which data needs protection at the beginning; otherwise, if subsequent developers arbitrarily modify data in hooks, it may lead to unknown issues.

## Optional Parameters
![client](./materials/upgui/client.jpg)
**UPAction**.icon: ***string*** Icon  
![client](./materials/upgui/client.jpg)
**UPAction**.label: ***string*** Name  
![client](./materials/upgui/client.jpg)
**UPAction**.AAAACreat: ***string*** Creator  
![client](./materials/upgui/client.jpg)
**UPAction**.AAADesc: ***string*** Description  
![client](./materials/upgui/client.jpg)
**UPAction**.AAAContrib: ***string*** Contributor  
![shared](./materials/upgui/shared.jpg)
**UPAction**.TrackId: ***int*** or ***string*** Track ID  
```note
Default is 0. Interruption checks are triggered when actions with the same TrackId are activated simultaneously.
```

## Methods to Implement
![shared](./materials/upgui/shared.jpg) 
***table*** **UPAction**:Check(**Player** ply, **any** data)  
```note
After returning a table, the hooks "UParActPreStartValidate_" + "actName" and "UParActStartValidate" will be triggered. If validation passes, it proceeds to Start.

"UParActPreStartValidate" is a hook for subsequent developers to add additional trigger conditions for the action.
```

![shared](./materials/upgui/shared.jpg)
**UPAction**:Start(**Player** ply, **table** checkResult)
```note
Executed once at startup, then enters Think.

Initialize required resources here. Resource loading and unloading should preferably have no context dependencies—i.e., they should be loadable and unloadable in any scenario.
```

![server](./materials/upgui/server.jpg)
***any*** **UPAction**:Think(**Player** ply, **table** checkResult, **CMoveData** mv, **CUserCmd** cmd)
```note
Return a truthy value to enter Clear; otherwise, maintain the current state.
```

![shared](./materials/upgui/shared.jpg)
**UPAction**:Clear(**Player** ply, **table** checkResult, **CMoveData** mv, **CUserCmd** cmd, **bool** or **string** interruptSource)
```note
Called when Think returns a truthy value, forced termination, interruption, etc.
interruptSource is true for forced termination, and the interruption name for other cases.

Clean up resources here. Resource loading and unloading should preferably have no context dependencies—i.e., they should be loadable and unloadable in any scenario.
```


![server](./materials/upgui/server.jpg)
**bool** **UPAction**:OnValCltPredRes(**Player** ply, **table** checkResult)
```note
When UPar.Trigger is called and validated on the client, data is sent to the server. 
The server can validate the data here.
Generally not required, mainly used to prevent illegal modification of data by the client.
```
```lua
-- Verify if checkResult.endpos is too far from the player's position
-- Restrict speed to non-negative values
function moveAct:OnValCltPredRes(ply, checkResult)
	if isvector(checkResult.endpos) then
		if not isnumber(checkResult.speed) or (checkResult.endpos - ply:GetPos()):LengthSqr() > 1000 ^ 2 then
			return false
		end

		checkResult.speed = math.max(checkResult.speed, 0)
		
		return true
	else
		return false
	end
end
```

## Available Methods
![shared](./materials/upgui/shared.jpg)
**UPAction**:InitCVarPredictionMode(**string** default)
```note
Will appear in the Q menu after initialization.

false: Use server-side calculation
true: Use client-side prediction

The parameter itself has no effect and needs to be handled manually.
```

![shared](./materials/upgui/shared.jpg)
**UPAction**:InitConVars(**table** config)
```lua
-- Example:
-- Will appear in the action editor after initialization
-- Access via self.ConVars
action:InitConVars({
	{
		name = 'example_numslider',
		label = '#upgui.dev.example_numslider',
		default = '0',
		widget = 'NumSlider',
		min = 0, max = 1, decimals = 2,
		help = '#upgui.dev.example_help',
	},

	{
		name = 'example_color',
		label = '#upgui.dev.example_color_editor',
		default = '255 0 0 255',
		widget = 'UParColorEditor'
	},

	{
		name = 'example_ang',
		label = '#upgui.dev.example_ang_editor',
		default = '0.5 0.5 0.5',
		widget = 'UParAngEditor',
		min = -1, max = 1, decimals = 1, interval = 0.1,
	},

	{
		name = 'example_vec',
		label = '#upgui.dev.example_vec_editor',
		default = '0 1 0',
		widget = 'UParVecEditor',
		min = -2, max = 2, decimals = 2, interval = 0.5,
	},

	{
		name = 'example_keybinder',
		label = '#upgui.dev.example_keybinder',
		default = '[9, 1]',
		widget = 'UParKeyBinder',
	},

	{
		name = 'example_invisible',
		label = '#upgui.dev.example_invisible',
		default = '0',
		widget = 'NumSlider',
		invisible = true,
	},

	{
		name = 'example_admin',
		label = '#upgui.dev.example_admin',
		default = '0',
		widget = 'NumSlider',
		admin = true,
	}
}) 
```

![client](./materials/upgui/client.jpg)
**UPAction**:RegisterPreset(**table** preset)
```lua
if CLIENT then
	action:RegisterPreset(
		{
			AAAACreat = 'Miss DouBao',
			AAAContrib = 'Zack',

			label = '#upgui.dev.example',
			values = {
				['example_numslider'] = '0.5'
			}
		}
	) 
end
```

![shared](./materials/upgui/shared.jpg)
**UPAction**:AddConVar(**table** cvCfg)
```lua
action:AddConVar({
	name = 'example_other',
	widget = 'NumSlider'
})
```

![shared](./materials/upgui/shared.jpg)
**UPAction**:RemoveConVar(**string** cvName)
```lua
action:RemoveConVar('example_other')
```