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

# Hook

![shared](./materials/upgui/shared.jpg)
**@Name** UParRegisterAction  
***@Params*** 
- actName **string**  
- action **UPAction**  

```note
Triggered when registering an action.
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParRegisterEffect  
***@Params*** 
- actName **string**  
- effName **string**  
- effect **UPEffect**  

```note
Triggered when registering an effect.
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParSaveUserEffCacheToDisk  
***@Params*** 
- cache **table**  

***@Return***  
- **any** 

```note
Triggered when saving the user effect cache to disk. Returning a truthy value will override the default value.
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParSaveUserEffCfgToDisk  
***@Params*** 
- cfg **table**  

***@Return***  
- **any** 

```note
Triggered when saving the user effect configuration to disk. Returning a truthy value will override the default value.
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParLoadUserEffCacheFromDisk  
***@Params*** 
- cache **table**  

***@Return***  
- **any** 

```note
Triggered when loading the user effect cache from disk. Returning a truthy value will override the default value.
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParLoadUserEffCfgFromDisk  
***@Params*** 
- cfg **table**  

***@Return***  
- **any** 

```note
Triggered when loading the user effect configuration from disk. Returning a truthy value will override the default value.
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParSaveUserCustomEffectToDisk  
***@Params*** 
- custom **table**  

***@Return***  
- **any** 

```note
Triggered when saving the user custom effect configuration to disk. Returning a truthy value will override the default value.
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParLoadUserCustomEffectFromDisk  
***@Params*** 
- custom **table**  

***@Return***  
- **any** 

```note
Triggered when loading the user custom effect configuration from disk. Returning a truthy value will override the default value.
```