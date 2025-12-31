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


## 自定义特效

自定义特效相比**UPEffect**的最大区别在于多了**linkName**和**linkAct**键, 这两个键分别是**string**类型, 是某个**UPEffect**和某个**UPAction**的名称。


## 工作原理

### 保存
路径: /data/uparkour_effects/custom/**%linkAct%**/**%name%**.json  

使用 util.TableToJSON 来序列化数据。  
保存后的数据将会丢失内部引用关系, 对于依赖此工作的特效, 不建议创建自定义特效。
或者使用钩子**UParLoadUserCustomEffectFromDisk**和**UParSaveUserCustomEffectToDisk**来加载和保存。

### 初始化
每次保存都触发初始化, 内部使用**UPar.DeepClone**来深拷贝, 原版的深拷贝**table.Copy**对 vector, angle, matrix 等 userdata 类型不支持。

然后使用**UPar.DeepInject**来补全自定义对象, 例如**function**等无法序列化的类型。