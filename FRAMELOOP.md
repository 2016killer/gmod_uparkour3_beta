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


# 帧循环

## 1.  推入帧循环
**boolean** UPar.PushFrameLoop(**any** identity, **function** iterator, **any** addition, **number** timeout, **function** clear=nil, **string** hookName="Think")
```note
用于向帧循环管理器中推入一个新帧循环，若指定标识（identity）的帧循环已存在，会先触发旧帧循环的 UParPopFrameLoop 钩子（原因标记为OVERRIDE）并覆盖旧帧循环。默认使用Think帧循环钩子，会自动启动对应帧循环监听逻辑，超时时间（timeout）需传入大于0的数值。
```

## 2.  弹出帧循环
**boolean** UPar.PopFrameLoop(**any** identity, **boolean** silent=false)
```note
用于手动删除指定标识的帧循环，删除前会优先执行帧循环的clear回调函数（若存在）。非静默模式（silent=false）下会触发 UParPopFrameLoop 钩子（原因标记为MANUAL），若帧循环不存在则返回false。
```

## 3.  获取帧循环数据
**table** UPar.GetFrameLoop(**any** identity)
```note
用于获取指定标识帧循环的完整存储数据，返回表包含f（帧循环函数）、et（超时绝对时间）、add（附加数据）、clear（清理回调）、hn（绑定钩子名）、pt（暂停时间，可选）字段。若帧循环不存在，返回nil。
```

## 4.  判断帧循环是否存在
**boolean** UPar.IsFrameLoopExist(**any** identity)
```note
用于快速判断指定标识的帧循环是否存在于帧循环管理器中，存在则返回true，不存在则返回false。
```

## 5.  暂停帧循环
**boolean** UPar.PauseFrameLoop(**any** identity, **boolean** silent=false)
```note
用于暂停指定标识的帧循环，暂停后的帧循环不会在帧循环中执行逻辑，同时会记录暂停时间。非静默模式（silent=false）下会触发 UParPauseFrameLoop 钩子，若帧循环不存在则返回false。
```

## 6.  恢复帧循环
**boolean** UPar.ResumeFrameLoop(**any** identity, **boolean** silent=false)
```note
用于恢复已暂停的指定标识帧循环，会自动补偿暂停时长（更新帧循环超时绝对时间），并重新启动对应帧循环监听。非静默模式（silent=false）下会触发 UParResumeFrameLoop  钩子，若帧循环不存在或未处于暂停状态，返回false。
```

## 7.  设置帧循环附加数据嵌套KV
**boolean** UPar.SetFrameLoopAddiKV(**any** identity, **any** ...)
```note
用于设置帧循环附加数据中的多层嵌套键值对，传入参数需不少于2个（支持多层表索引，最后两个参数分别为目标键和对应值）。若帧循环不存在、嵌套表路径无效，则返回false。
```

## 8.  获取帧循环附加数据嵌套KV
**any** UPar.GetFrameLoopAddiKV(**any** identity, **any** ...)
```note
用于获取帧循环附加数据中的多层嵌套键值对，传入参数需不少于2个（支持多层表索引，最后一个参数为目标键）。若帧循环不存在、嵌套表路径无效，则返回nil。
```

## 9.  设置帧循环超时时间
**boolean** UPar.SetFrameLoopEndTime(**any** identity, **number** endTime, **boolean** silent=false)
```note
用于修改指定标识帧循环的超时绝对时间（endTime需传入数字类型的绝对时间，非相对时长）。非静默模式（silent=false）下会触发 UParFrameLoopEndTimeChanged 钩子，若帧循环不存在则返回false。
```

## 10. 合并帧循环附加数据
**boolean** UPar.MergeFrameLoopAddiKV(**any** identity, **table** data)
```note
用于合并帧循环的附加数据，基于GLua table.Merge方法实现浅合并（仅合并顶层键值对，深层表不会递归合并）。若帧循环不存在或传入的合并数据非表类型，返回false。
```