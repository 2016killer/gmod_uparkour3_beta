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

# UPEffect类
```note
我们应当将UPAction视为静态容器, 不应该将任何运行的结果存储在其中。
```

## 关于UPAction接口实现
这里不再采用2.1.0版本的参数对齐写法, 虽然序列表在网络传输中表现良好, 但是高频地unpack也很难受，代码也不好维护, 所以退回1.0.0版本的方法。
当然, 这样也有很多好处, 比如某些需要持久的数据可以直接放表中, 或者需要继承的数据也可以直接扔进去, 这使开发难度大大滴降低。
但是坏处也很多, 比如数据不安全, 最好在一开始确定要保护哪些, 否则后来的开发者在钩子中乱来的话, 就会导致一些未知的问题。


## 可选参数
![client](./materials/upgui/client.jpg)
**UPAction**.icon: ***string*** 图标  
![client](./materials/upgui/client.jpg)
**UPAction**.label: ***string*** 名称  
![client](./materials/upgui/client.jpg)
**UPAction**.AAAACreat: ***string*** 创建者  
![client](./materials/upgui/client.jpg)
**UPAction**.AAADesc: ***string*** 描述  
![client](./materials/upgui/client.jpg)
**UPAction**.AAAContrib: ***string*** 贡献者  
![shared](./materials/upgui/shared.jpg)
**UPAction**.TrackId: ***int*** or ***string*** 轨道ID  
```note
默认为0, 相同TrackId的动作同时触发时会触发中断判断。
```

## 需要实现的方法
![shared](./materials/upgui/shared.jpg) 
***table*** **UPAction**:Check(**Player** ply, **any** data)  
```note
返回表后将会触发 "UParActPreStartValidate_" + "actName" "和UParActStartValidate", 验证通过后进入Start。

"UParActPreStartValidate" 是 后来者为动作添加额外触发条件的钩子。
```

![shared](./materials/upgui/shared.jpg)
**UPAction**:Start(**Player** ply, **table** checkResult)
```note
在启动时执行一次, 然后进入Think。
在这里初始化所需要的资源, 资源的载入和释放最好不要有上下文依赖，也就是任何情况都能载入和释放。
```

![server](./materials/upgui/server.jpg)
***any*** **UPAction**:Think(**Player** ply, **table** checkResult, **CMoveData** mv, **CUserCmd** cmd)
```note
返回真值进入Clear, 否则维持当前状态
```

![shared](./materials/upgui/shared.jpg)
**UPAction**:Clear(**Player** ply, **table** checkResult, **CMoveData** mv, **CUserCmd** cmd, **bool** or **string** interruptSource)
```note
在Think返回真值、强制结束、 中断 等情况下调用
强制结束时, interruptSource为true, 其他情况为中断名称

在这里清理资源, 资源的载入和释放最好不要有上下文依赖，也就是任何情况都能载入和释放。
```

![server](./materials/upgui/server.jpg)
**bool** **UPAction**:OnValCltPredRes(**Player** ply, **table** checkResult)
```note
在客户端调用UPar.Trigger通过时会向服务器端发送数据, 服务器端可以在校验数据。
一般情况用不上, 主要是防止客户端非法修改数据。
```
```lua
-- 验证 checkResult.endpos 与 玩家的位置是否相差太远
-- 限制速度不能为负数
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

## 可用方法
![shared](./materials/upgui/shared.jpg)
**UPAction**:InitCVarPredictionMode(**string** default)
```note
在初始化后会出现在Q菜单中

false: 使用服务端计算
true: 使用客户端预测

参数本身无作用，需要自行处理。
```

![shared](./materials/upgui/shared.jpg)
**UPAction**:InitConVars(**table** config)
```lua
-- 例:
-- 初始化后会出现在动作编辑器中
-- 使用 self.ConVars 可访问
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