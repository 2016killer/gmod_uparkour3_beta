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

# UPManip 骨骼操纵
```note
注意: 这是一个测试性模块, 不建议在生产环境中使用。

这些都很难用, 简直一坨屎。

此方法的使用门槛极高, 首先 ManipulateBonePosition 有距离限制, 限制为 128 个单位,
所以如果想完成正确插值的话, 则必须在位置更新完成的那一帧, 
所以想要完成正确插值, 最好单独加一个标志 + 回调来处理, 这样不容易导致混乱。

```


## 简介
使用 `upmanip_test` 控制台指令可以测试 UPManip 的功能。

这是一个**纯客户端**的API, 通过 **ent:ManipulateBonexxx** 等方法对骨骼进行直接的控制。  

优点: 
1. 直接操作骨骼, 无需通过 **ent:AddEffects(EF_BONEMERGE)** 、 **BuildBonePositions** 、 **ResetSequence** 等方法。
2. 相比 **VMLeg** , 它拥有淡出动画 并且 淡出动画不需要快照。  

缺点:
1. 运算量较大, 每次都需通过 **lua** 进行几次矩阵运算。
2. 需要每帧更新。
3. 无法处理奇异的矩阵, 这通常发生在骨骼缩放为0时。
4. 可能会和使用了 **ent:ManipulateBonexxx** 的方法冲突, 导致动画异常。
## 可用方法

![client](./materials/upgui/client.jpg)
**vec**, **ang** UPManip.SetBonePosition(**entity** ent, **int** boneId, **vector** posw, **angle** angw)
```note
控制指定实体的指定骨骼的位置和角度, 新的位置不能距离旧位置太远 (128个单位)
最好在调用之前使用 ent:SetupBones(), 因为计算中需要当前骨骼矩阵。

这已经是最好用的, 其他更是一坨答辩
```