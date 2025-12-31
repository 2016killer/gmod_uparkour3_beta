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
我们应当将UPEffect视为静态容器, 不应该将任何运行的结果存储在其中。
表的结构最好是扁平的, 这样的话在用户创建自定义特效时可以很方便的编辑。
```

## 可选参数  

![client](./materials/upgui/client.jpg)
**UPEffect**.icon: ***string*** 图标  
![client](./materials/upgui/client.jpg)
**UPEffect**.label: ***string*** 名称  
![client](./materials/upgui/client.jpg)
**UPEffect**.AAAACreat: ***string*** 创建者  
![client](./materials/upgui/client.jpg)
**UPEffect**.AAADesc: ***string*** 描述  
![client](./materials/upgui/client.jpg)
**UPEffect**.AAAContrib: ***string*** 贡献者  

## 需要实现的方法

![shared](./materials/upgui/shared.jpg)
**UPEffect**:Start(**Player** ply, **table** checkResult)
```note
会在UPAction:Start后自动调用, 应当把checkResult视为只读, 但是实际上不是, 因为我的水平不够。
```



![shared](./materials/upgui/shared.jpg)
**UPEffect** UPar.RegisterEffectEasy(**string** actName, **string** tarName, **string** name, **table** initData)
```note
这会从已注册的当中找到对应的特效, 自动克隆并覆盖。
将控制台变量 developer 设为 1 可以阻止翻译行为以便查看真实键名。

此方法内部会使用 UPar.DeepClone 来克隆, 然后来合并。
```
```lua
-- 例:
local example = UPar.RegisterEffectEasy('test_lifecycle', 'default', 'example', {
	AAAACreat = 'Miss DouBao',
	AAADesc = '#upgui.dev.example',
	label = '#upgui.dev.example'
})
```