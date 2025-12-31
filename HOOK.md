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

# Hook

![shared](./materials/upgui/shared.jpg)
**@Name** UParRegisterAction  
***@Params*** 
- actName **string**  
- action **UPAction**  

```note
注册动作时触发
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParRegisterEffect  
***@Params*** 
- actName **string**  
- effName **string**  
- effect **UPEffect**  

```note
注册特效时触发
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParSaveUserEffCacheToDisk  
***@Params*** 
- cache **table**  

***@Return***  
- **any** 

```note
保存用户特效缓存时触发, 返回真值将覆盖默认值
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParSaveUserEffCfgToDisk  
***@Params*** 
- cfg **table**  

***@Return***  
- **any** 

```note
保存用户特效配置时触发, 返回真值将覆盖默认值
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParLoadUserEffCacheFromDisk  
***@Params*** 
- cache **table**  

***@Return***  
- **any** 

```note
加载用户特效缓存时触发, 返回真值将覆盖默认值
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParLoadUserEffCfgFromDisk  
***@Params*** 
- cfg **table**  

***@Return***  
- **any** 

```note
加载用户特效配置时触发, 返回真值将覆盖默认值
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParSaveUserCustomEffectToDisk  
***@Params*** 
- custom **table**  

***@Return***  
- **any** 

```note
保存用户自定义特效配置时触发, 返回真值将覆盖默认值
```

![shared](./materials/upgui/shared.jpg)
**@Name** UParLoadUserCustomEffectFromDisk  
***@Params*** 
- custom **table**  

***@Return***  
- **any** 

```note
加载用户自定义特效配置时触发, 返回真值将覆盖默认值
```