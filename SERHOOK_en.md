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

## Sequence Hooks

## Usage Methods

![shared](./materials/upgui/shared.jpg)
**int** UPar.SeqHookAdd(**string** eventName, **string** identifier, **function** func, **int** priority)
```note
Use this to add sequence hooks for events. If the identifier is duplicated and priority is nil, the previous priority will be inherited.
Returns the current priority.
```

![shared](./materials/upgui/shared.jpg)
UPar.SeqHookRemove(**string** eventName, **string** identifier)
```note
Removes the hook with the specified identifier.
```

## Existing Hooks
![client](./materials/upgui/client.jpg)
**@Name:** **UParExtendMenu**   
**@Parameters:** panel **DForm**
```note
Called when creating the extension menu.
```
```lua
UPar.SeqHookAdd('UParExtendMenu', 'GmodLegs3Compat', function(panel)
	panel:CheckBox('#upext.gmodlegs3_compat', 'upext_gmodlegs3_compat')
	panel:ControlHelp('#upext.gmodlegs3_compat.help')
end, 1)
```

![shared](./materials/upgui/shared.jpg)
**@Name:** UParVersionCompat
```note
Place code in the `version_compat` directory as much as possible. This hook is used to handle data compatibility across different versions, and it is recommended to set the priority to the version number (e.g., 210 for version 2.1.0).
```

![client](./materials/upgui/client.jpg)
**@Name:** **UParActCVarWidget** + **actName**  
**@Parameters:** cvCfg **table**, panel **DForm**  
**@Returns:** created **bool** or **nil**
```note
This is local and only applies to the panel of the specified action.
Can be used to customize the parameter editor for the action.
```
```lua
UPar.SeqHookAdd('UParActCVarWidget_test_lifecycle', 'example.special.widget', function(cvCfg, panel)
  if cvCfg.name == 'example_special' then
    panel:Help('#upgui.dev.special_widget')
    return true
  end
end)
```

![client](./materials/upgui/client.jpg)
**@Name:** **UParActCVarWidget**   
**@Parameters:** actName **string**, cvCfg **table**, panel **DForm**  
**@Returns:** created **bool** or **nil**
```note
This is global and takes effect when the local hook returns no value.
Can be used to customize the parameter editor for actions.
```
```lua
UPar.SeqHookAdd('UParActCVarWidget', 'example.special.widget', function(actName, cvCfg, panel)
  if cvCfg.name == 'example_special' then
    panel:Help('#upgui.dev.special_widget_global')
    return true
  end
end)
```

![client](./materials/upgui/client.jpg)
**@Name:** **UParActSundryPanels** + **actName**  
**@Parameters:** editor **UParActEditor**

```note
This is local.
```
```lua
UPar.SeqHookAdd('UParActSundryPanels_test_lifecycle', 'sundrypanel.example.1', function(editor)
	local panel = vgui.Create('DButton', editor)
	panel:Dock(FILL)
	panel:SetText('#upgui.button')
	editor:AddSheet('#upgui.dev.sundry', 'icon16/add.png', panel)
end)
```

![client](./materials/upgui/client.jpg)
**@Name:** **UParActSundryPanels**    
**@Parameters:** actName **string**, editor **UParActEditor**

```note
This is global.

The description panel is added internally using this hook.
```

![server](./materials/upgui/server.jpg)
**@Name:** **UParActAllowInterrupt** + **actName**  
**@Parameters:** ply **Player**, playingData **table**, interruptSource **string**  
**@Returns:** allowInterrupt **bool** or **nil**
```note
This is local.

interruptSource is the name of the interrupting action (UPAction).
playingData is a reference, note data safety.
```
```lua
UPar.SeqHookAdd('UParActAllowInterrupt_test_lifecycle', 'example.interrupt', function(ply, playingData, interruptSource)
  if interruptSource == 'test_interrupt' then
    return true
  end
end)
```

![server](./materials/upgui/server.jpg)
**@Name:** **UParActAllowInterrupt**  
**@Parameters:** playingName **string**, ply **Player**, playingData **table**, interruptSource **string**  
**@Returns:** allowInterrupt **bool** or **nil**
```note
This is global.

playingName is the name of the action being interrupted.
interruptSource is the name of the interrupting action (UPAction).
playingData is a reference, note data safety.
```

```lua
UPar.SeqHookAdd('UParActAllowInterrupt', 'example.interrupt', function(playingName, ply, playingData, interruptSource)
	if playingName == 'test_lifecycle' and interruptSource == 'test_interrupt' then
		return true
	end
end)
```

![shared](./materials/upgui/shared.jpg)
**@Name:** **UParActPreStartValidate** + **actName**  
**@Parameters:** ply **Player**, checkResult **table**  
**@Returns:** invalid **bool** or **nil**
```note
This is local.

checkResult is a reference, note data safety.
```
```lua
-- Stop randomly
UPar.SeqHookAdd('UParActPreStartValidate_test_lifecycle', 'example.prestart.validate', function(ply, checkResult)
	return math.random() > 0.5
end)
```

![shared](./materials/upgui/shared.jpg)
**@Name:** **UParActPreStartValidate**  
**@Parameters:** actName **string**, ply **Player**, checkResult **table**  
**@Returns:** invalid **bool** or **nil**
```note
This is global.

checkResult is a reference, note data safety.
```
```lua
-- Stop all actions randomly
UPar.SeqHookAdd('UParActPreStartValidate', 'example.prestart.validate', function(actName, ply, checkResult)
	return math.random() > 0.5
end)
```

![client](./materials/upgui/client.jpg)
**@Name:** **UParEffVarPreviewColor** + **actName** + **effName**  
**@Parameters:** key **string**, val **any**  
**@Returns:** color **Color** or **nil** or **bool**
```note
This is local.

Return a Color object, nil, or false to cancel the preview.
```
```lua
local red = Color(255, 0, 0)
UPar.SeqHookAdd('UParEffVarPreviewColor_test_lifecycle_default', 'example.red', function(key, val)
  if key == 'rhythm_sound' then return red end
end, 1)
```

![client](./materials/upgui/client.jpg)
**@Name:** **UParEffVarPreviewColor**   
**@Parameters:** actName **string**, effName **string**, key **string**, val **any**  
**@Returns:** color **Color** or **nil** or **bool**
```note
This is global.

Return a Color object, nil, or false to cancel the preview.
```
```lua
local yellow = Color(255, 255, 0)
UPar.SeqHookAdd('UParEffVarPreviewColor', 'example.yellow', function(actName, effName, key, val)
  if actName == 'test_lifecycle' and key == 'rhythm_sound' then 
    return yellow 
  end
end, 1)
```

![client](./materials/upgui/client.jpg)
**@Name:** **UParEffVarEditorColor** + **actName** + **effName**  
**@Parameters:** key **string**, val **any**  
**@Returns:** color **Color** or **nil** or **bool**

![client](./materials/upgui/client.jpg)
**@Name:** **UParEffVarEditorColor**   
**@Parameters:** actName **string**, effName **string**, key **string**, val **any**  
**@Returns:** color **Color** or **nil** or **bool**

![client](./materials/upgui/client.jpg)
**@Name:** **UParEffVarEditorWidget** + **actName** + **effName**  
**@Parameters:** key **string**, val **any**, editor **DForm**, keyColor **Color**  
**@Returns:** created **bool** or **nil**
```note
This is local.

keyColor is the color obtained from UParEffVarEditorColor.
```
```lua
UPar.SeqHookAdd('UParEffVarEditorWidget_test_lifecycle_default', 'example.local', function(key, val, editor, keyColor)
  if key == 'rhythm_sound' then
    local comboBox = editor:ComboBox(UPar.SnakeTranslate_2(key), '')

    comboBox.OnSelect = function(self, index, value, data)
      editor:Update(key, value)
    end
    comboBox:AddChoice('hl1/fvox/blip.wav')
    comboBox:AddChoice('Weapon_AR2.Single')
    comboBox:AddChoice('Weapon_Pistol.Single')

    editor:Help('#upgui.dev.special_widget')
    return true
  end
end, 1)
```

![client](./materials/upgui/client.jpg)
**@Name:** **UParEffVarEditorWidget**   
**@Parameters:** actName **string**, effName **string**, key **string**, val **any**, editor **DForm**, keyColor **Color**  
**@Returns:** created **bool** or **nil**

![client](./materials/upgui/client.jpg)
**@Name:** **UParEffVarPreviewWidget** + **actName** + **effName**  
**@Parameters:** key **string**, val **any**, editor **DForm**, keyColor **Color**  
**@Returns:** created **bool** or **nil**

![client](./materials/upgui/client.jpg)
**@Name:** **UParEffVarPreviewWidget**   
**@Parameters:** actName **string**, effName **string**, key **string**, val **any**, editor **DForm**, keyColor **Color**  
**@Returns:** created **bool** or **nil**