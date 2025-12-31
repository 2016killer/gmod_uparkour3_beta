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

# UPEffect Class
```note
We should treat UPEffect as a static container and must not store any runtime results in it.
It's structure should preferably be flat, which makes it easy for users to edit when creating custom effects.
```

## Optional Parameters  

![client](./materials/upgui/client.jpg)
**UPEffect**.icon: ***string*** Icon  
![client](./materials/upgui/client.jpg)
**UPEffect**.label: ***string*** Name  
![client](./materials/upgui/client.jpg)
**UPEffect**.AAAACreat: ***string*** Creator  
![client](./materials/upgui/client.jpg)
**UPEffect**.AAADesc: ***string*** Description  
![client](./materials/upgui/client.jpg)
**UPEffect**.AAAContrib: ***string*** Contributor  

## Methods to Implement

![shared](./materials/upgui/shared.jpg)
**UPEffect**:Start(**Player** ply, **table** checkResult)
```note
Automatically called after UPAction:Start. checkResult should be treated as read-only, but in reality, it's not—due to my limited coding skills.
```

![shared](./materials/upgui/shared.jpg)
**UPEffect** UPar.RegisterEffectEasy(**string** actName, **string** tarName, **string** name, **table** initData)
```note
Finds the corresponding effect from registered ones, automatically clones and overwrites it.
Set the console variable `developer` to 1 to disable translation and view the actual key names.

This method internally uses `UPar.DeepClone` for cloning before merging data.
```
```lua
-- Example:
local example = UPar.RegisterEffectEasy('test_lifecycle', 'default', 'example', {
	AAAACreat = 'Miss DouBao',
	AAADesc = '#upgui.dev.example',
	label = '#upgui.dev.example'
})
```