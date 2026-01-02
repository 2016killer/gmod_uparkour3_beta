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

使用控制台指令 `upmanip_test_world` 或 `upmanip_test_local` 可以看到演示效果。

```note
注意: 这是一个测试性模块, 不建议在生产环境中使用。

这些都很难用, 简直一坨屎。

此方法的使用门槛极高, 首先 ManipulateBonePosition 有距离限制, 限制为 128 个单位,
所以如果想完成正确插值的话, 则必须在位置更新完成的那一帧, 
所以想要完成正确插值, 最好单独加一个标志 + 回调来处理, 这样不容易导致混乱。

由于这些函数常常在帧循环中, 加上计算略显密集 (串行), 所以很多的错误都是无声的, 这极大
地增加了调试难度, 有点像GPU编程, 操, 所以我并不推荐使用这些。

插值需要指定骨骼映射和其排序, GetEntBonesFamilyLevel(ent, useLRU2) 可以辅助排序,
完成后再手动编码。

这里的插值分为两种 LerpBoneWorld 和 LerpBoneLocal
如果从本质来看, 世界空间的插值可以看做一种特殊的局部空间插值, 只是将所有骨骼的父级都看作是 World,
同时这里的 api 都是用骨骼名来指向操作的骨骼, 而不是 boneId, 这样的好处就是我可以将骨骼操纵拓展到
操作实体本身, 我们用 'self' 来表示实体本身, 同时我们还能将 'self' 映射到另一个实体的骨骼上来实现
骨架嫁接。 

关于操纵与获取
这里开放的其他底层包括 GetBoneMatrixLocal, GetBoneMatrix, SetBonePositionLocal, SetBonePosition
因为操纵是通过 ManipulateBonexxx 来实现的, 所以 SetBonePosition 和 GetBoneMatrix 有着必然的耦合。 (除了 'self')

我决定在一些函数末尾加上一个 silentlog 参数, 用于控制是否打印日志, 这会让调试
起来更加方便。
```

## 简介
这是一个**纯客户端**的API, 通过 **ent:ManipulateBonexxx** 等方法对骨骼进行直接的控制。  

优点: 
1.  直接操作骨骼, 无需通过 **ent:AddEffects(EF_BONEMERGE)** 、 **BuildBonePositions** 、 **ResetSequence** 等方法。
2.  相比 **VMLeg** , 它拥有淡出动画 并且 淡出动画不需要快照。  

缺点:
1.  运算量较大, 每次都需通过 **lua** 进行几次矩阵运算。
2.  需要每帧更新。
3.  无法处理奇异的矩阵, 这通常发生在骨骼缩放为0时。
4.  可能会和使用了 **ent:ManipulateBonexxx** 的方法冲突, 导致动画异常。

## 可用方法

![client](./materials/upgui/client.jpg)
**angle**, **vector** UPManip.SetBonePosition(**entity** ent, **string** boneName, **vector** posw, **angle** angw, **bool** silentlog)
```note
控制指定实体的指定骨骼的位置和角度, 新的位置不能距离旧位置太远 (128个单位)
最好在调用之前使用 ent:SetupBones(), 因为计算中需要当前骨骼矩阵。
支持 'self' 关键字表示实体本身, 此时直接设置实体世界位置和角度。

这已经是最好用的, 其他更是一坨答辩
```

![client](./materials/upgui/client.jpg)
**angle**, **vector** UPManip.SetBonePositionLocal(**entity** ent, **string** boneName, **vector** posl, **angle** angl, **bool** silentlog)
```note
按局部空间（相对父骨骼/实体）控制指定骨骼的位置和角度, 需每帧更新。
支持 'self' 关键字表示实体本身, 此时直接设置实体世界位置和角度。
调用前建议执行 ent:SetupBones(), 避免获取错误骨骼矩阵。
```

![client](./materials/upgui/client.jpg)
**matrix**, **int** UPManip.GetBoneMatrix(**entity** ent, **string** boneName)
```note
获取指定骨骼的世界空间变换矩阵, 返回骨骼矩阵和对应的boneId（非'self'时）。
支持 'self' 关键字, 此时返回实体自身的世界变换矩阵。
骨骼不存在时返回nil, 需提前校验实体有效性。
```

![client](./materials/upgui/client.jpg)
**matrix**, **int**, **int** UPManip.GetBoneMatrixLocal(**entity** ent, **string** boneName, **string** parentName, **bool** invert)
```note
获取指定骨骼相对自定义父级的局部空间变换矩阵。
参数 parentName: 自定义父骨骼名, 支持 'self' 关键字, 不指定则使用骨骼默认父级。
参数 invert: 控制矩阵计算方向（正向/反向）, 用于不同空间转换场景。
返回值: 局部变换矩阵、当前骨骼Id、父骨骼Id（非invert模式下）, 失败返回nil。
```

![client](./materials/upgui/client.jpg)
**table** UPManip.GetEntBonesFamilyLevel(**entity** ent, **bool** useLRU2)
```note
获取实体骨骼的父子层级深度表, 键为boneId, 值为层级深度（根骨骼层级为0）。
参数 useLRU2: 是否启用LRU2缓存, 按模型名缓存结果, 提升重复调用性能。
调用前会自动执行 ent:SetupBones(), 实体无效/无模型/无根骨骼时打印错误日志并返回nil。
可用于骨骼插值时的排序辅助（先父后子）。
```

![client](./materials/upgui/client.jpg)
**bool** UPManip.IsMatrixSingular(**matrix** mat)
```note
工程化判断矩阵是否为奇异矩阵（无法求逆）, 非严谨数学方法, 性能优于行列式计算。
通过检查矩阵前向、向上、右向向量的长度平方是否小于阈值（1e-2）来判断。
返回true表示矩阵奇异, 无法用于后续逆变换计算; 返回false表示矩阵可用。
```

![client](./materials/upgui/client.jpg)
**angle**, **vector**, **vector** UPManip.LerpBoneWorld(**number** t, **entity** ent, **entity** tarEnt, **string** boneName, **string** tarBoneName, **matrix** offsetMatrix, **bool** silentlog)
```note
世界空间下骨骼姿态线性插值, 实现当前骨骼向目标骨骼的平滑过渡。
参数 t: 插值因子（建议0-1, 超出范围会出现过度插值）, 0为当前状态, 1为目标状态。
参数 tarBoneName: 目标实体的对应骨骼名, 不指定则与boneName一致（恒等映射）。
参数 offsetMatrix: 目标骨骼矩阵的偏移矩阵, 用于额外的位置/角度/缩放调整。
需每帧更新, 调用前建议执行 ent:SetupBones() 和 tarEnt:SetupBones(), 失败返回nil。
```

![client](./materials/upgui/client.jpg)
**angle**, **vector**, **vector** UPManip.LerpBoneLocal(**number** t, **entity** ent, **entity** tarEnt, **string** boneName, **string** tarBoneName, **string** parentName, **string** tarParentName, **matrix** offsetMatrix, **bool** silentlog)
```note
局部空间下骨骼姿态线性插值, 相对自定义父级进行平滑过渡, 灵活性更高。
参数 tarBoneName: 目标实体对应骨骼名, 不指定则与boneName一致。
参数 parentName: 当前骨骼的自定义父级名, 不指定则使用默认父级。
参数 tarParentName: 目标骨骼的自定义父级名, 不指定则与parentName一致。
需每帧更新, 调用前建议执行 ent:SetupBones() 和 tarEnt:SetupBones(), 失败返回nil。
```

![client](./materials/upgui/client.jpg)
**void** UPManip.InitBoneMappingOffset(**table** boneMapping)
```note
验证骨骼映射表的有效性, 并将配置中的角度/位置/缩放转换为偏移矩阵（offset）。
骨骼映射表 boneMapping 必须包含 main （骨骼配置）和 keySort （执行顺序）两个子表。
main 表键为骨骼名（string/'self'）, 值为true（无偏移）或包含ang/pos/scale等字段的表。
custParent 和 tarParent 字段仅对局部空间插值有效, 指定custParent时建议同步指定tarParent。
参数无效时会触发assert断言报错, 用于提前规避运行时错误。
```

![client](./materials/upgui/client.jpg)
**void** UPManip.LerpBoneWorldByMapping(**number** t, **entity** ent, **entity** tarEnt, **table** boneMapping, **bool** silentlog)
```note
按骨骼映射表批量执行世界空间骨骼插值, 无需逐个调用LerpBoneWorld。
boneMapping 需先通过 UPManip.InitBoneMappingOffset 初始化验证。
keySort 数组决定骨骼插值顺序, 需按"先父后子"排序, 否则子骨骼姿态异常。
需每帧更新, 调用前建议执行 ent:SetupBones() 和 tarEnt:SetupBones()。
```

![client](./materials/upgui/client.jpg)
**void** UPManip.LerpBoneLocalByMapping(**number** t, **entity** ent, **entity** tarEnt, **table** boneMapping, **bool** silentlog)
```note
按骨骼映射表批量执行局部空间骨骼插值, 无需逐个调用LerpBoneLocal。
boneMapping 需先通过 UPManip.InitBoneMappingOffset 初始化验证。
keySort 数组决定骨骼插值顺序, 需按"先父后子"排序, 否则子骨骼姿态异常。
支持自定义父骨骼配置（custParent/tarParent）, 需每帧更新。
```