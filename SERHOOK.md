<p align="center">
  <a href="./README_en.md">English</a> |
  <a href="./README.md">简体中文</a>
</p>

## 目录

<a href="./UPACTION.md">动作</a>  
<a href="./UPEFFECT.md">特效</a>  
<a href="./SERHOOK.md">序列钩子</a>  
<a href="./HOOK.md">钩子</a>  
<a href="./LRU.md">LRU存储</a>  
<a href="./CUSTOMEFFECT.md">自定义特效</a>  
<a href="./UPMANIP.md">骨骼操纵</a>  
<a href="./UPKEYBOARD.md">键盘</a>  
<a href="./FRAMELOOP.md">帧循环</a>  

## 序列钩子

## 操作方法

![shared](./materials/upgui/shared.jpg)
**int** UPar.SeqHookAdd(**string** eventName, **string** identifier, **function** func, **int** priority)
```note
使用此添加事件的序列钩子, 如果标识符重复且priority为nil的情况则继承之前的优先级。
返回当前优先级。
```

![shared](./materials/upgui/shared.jpg)
UPar.SeqHookRemove(**string** eventName, **string** identifier)
```note
移除指定标识符的钩子
```

## 已存在的钩子
![client](./materials/upgui/client.jpg)
**@名字:** **UParExtendMenu**   
**@参数:** panel **DForm**
```note
在创建拓展菜单的时候调用
```
```lua
UPar.SeqHookAdd('UParExtendMenu', 'GmodLegs3Compat', function(panel)
	panel:CheckBox('#upext.gmodlegs3_compat', 'upext_gmodlegs3_compat')
	panel:ControlHelp('#upext.gmodlegs3_compat.help')
end, 1)
```

![shared](./materials/upgui/shared.jpg)
**@名字:** UParVersionCompat
```note
尽量将代码放在 version_compat 目录下, 这是用来处理不同版本的数据兼容, 最好优先级设为 版本号 例如: 210
```

![client](./materials/upgui/client.jpg)
**@名字:** **UParActCVarWidget** + **actName**  
**@参数:** cvCfg **table**, panel **DForm**  
**@返回:** created **bool**
```note
这是局部的, 只针对指定的动作的面板。
可以用来自定义动作的参数编辑器。
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
**@名字:** **UParActCVarWidget**   
**@参数:** actName **string**, cvCfg **table**, panel **DForm**  
**@返回:** created **bool**
```note
这是全局的, 当局部的没有返回值时生效。
可以用来自定义动作的参数编辑器。
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
**@名字:** **UParActSundryPanels** + **actName**  
**@参数:** editor **UParActEditor**

```note
这是局部的。
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
**@名字:** **UParActSundryPanels**    
**@参数:** actName **string**, editor **UParActEditor**

```note
这是全局的。

内部使用了此来添加描述面板。
```


![server](./materials/upgui/server.jpg)
**@名字:** **UParActAllowInterrupt** + **actName**  
**@参数:** ply **Player**, playingData **table**, interruptSource **string**  
**@返回:** allowInterrupt **bool**
```note
这是局部的。

interruptSource 为中断者 (UPAction) 的名字。
playingData 是一个引用, 注意数据安全。
```
```lua
UPar.SeqHookAdd('UParActAllowInterrupt_test_lifecycle', 'example.interrupt', function(ply, playingData, interruptSource)
  if interruptSource == 'test_interrupt' then
    return true
  end
end)
```

![server](./materials/upgui/server.jpg)
**@名字:** **UParActAllowInterrupt**  
**@参数:** playingName **string**, ply **Player**, playingData **table**, interruptSource **string**  
**@返回:** allowInterrupt **bool**
```note
这是全局的。

playingName 为被中断的动作的名字。
interruptSource 为中断者 (UPAction) 的名字。
playingData 是一个引用, 注意数据安全。
```

```lua
UPar.SeqHookAdd('UParActAllowInterrupt', 'example.interrupt', function(playingName, ply, playingData, interruptSource)
	if playingName == 'test_lifecycle' and interruptSource == 'test_interrupt' then
		return true
	end
end)
```

![shared](./materials/upgui/shared.jpg)
**@名字:** **UParActPreStartValidate** + **actName**  
**@参数:** ply **Player**, checkResult **table**  
**@返回:** invalid **bool**
```note
这是局部的。

checkResult 是一个引用, 注意数据安全。
```
```lua
-- 随机停止
UPar.SeqHookAdd('UParActPreStartValidate_test_lifecycle', 'example.prestart.validate', function(ply, checkResult)
	return math.random() > 0.5
end)
```

![shared](./materials/upgui/shared.jpg)
**@名字:** **UParActPreStartValidate**  
**@参数:** actName **string**, ply **Player**, checkResult **table**  
**@返回:** invalid **bool**
```note
这是全局的。

checkResult 是一个引用, 注意数据安全。
```
```lua
-- 随机停止所有
UPar.SeqHookAdd('UParActPreStartValidate', 'example.prestart.validate', function(actName, ply, checkResult)
	return math.random() > 0.5
end)
```

![client](./materials/upgui/client.jpg)
**@名字:** **UParEffVarPreviewColor** + **actName** + **effName**  
**@参数:** key **string**, val **any**  
**@返回:** color **Color** or **nil** or **bool**
```note
这是局部的。

返回一个颜色, 或者 nil, 或者 false 来取消预览。
```
```lua
local red = Color(255, 0, 0)
UPar.SeqHookAdd('UParEffVarPreviewColor_test_lifecycle_default', 'example.red', function(key, val)
  if key == 'rhythm_sound' then return red end
end, 1)
```


![client](./materials/upgui/client.jpg)
**@名字:** **UParEffVarPreviewColor**   
**@参数:** actName **string**, effName **string**, key **string**, val **any**  
**@返回:** color **Color** or **nil** or **bool**
```note
这是全局的。

返回一个颜色, 或者 nil, 或者 false 来取消预览。
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
**@名字:** **UParEffVarEditorColor** + **actName** + **effName**  
**@参数:** key **string**, val **any**  
**@返回:** color **Color** or **nil** or **bool**


![client](./materials/upgui/client.jpg)
**@名字:** **UParEffVarEditorColor**   
**@参数:** actName **string**, effName **string**, key **string**, val **any**  
**@返回:** color **Color** or **nil** or **bool**


![client](./materials/upgui/client.jpg)
**@名字:** **UParEffVarEditorWidget** + **actName** + **effName**  
**@参数:** key **string**, val **any**, editor **DForm**, keyColor **Color**  
**@返回:** created **bool**
```note
这是局部的。

keyColor 是来自 UParEffVarEditorColor 的颜色。
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
**@名字:** **UParEffVarEditorWidget**   
**@参数:** actName **string**, effName **string**, key **string**, val **any**, editor **DForm**, keyColor **Color**  
**@返回:** created **bool**


![client](./materials/upgui/client.jpg)
**@名字:** **UParEffVarPreviewWidget** + **actName** + **effName**  
**@参数:** key **string**, val **any**, editor **DForm**, keyColor **Color**  
**@返回:** created **bool**


![client](./materials/upgui/client.jpg)
**@名字:** **UParEffVarPreviewWidget**   
**@参数:** actName **string**, effName **string**, key **string**, val **any**, editor **DForm**, keyColor **Color**  
**@返回:** created **bool**
