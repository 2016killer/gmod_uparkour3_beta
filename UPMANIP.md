# UPManip 骨骼操纵
使用控制台指令 `upmanip_test_world` 或 `upmanip_test_local` 可以看到演示效果。

```note
注意: 这是一个测试性模块, 不建议在生产环境中使用。

这些都很难用, 简直一坨屎。

此方法的使用门槛极高, 首先 ManipulateBonePosition 有距离限制, 限制为 128 个单位,
所以如果想完成正确插值的话, 则必须在位置更新完成的那一帧, 
所以想要完成正确插值, 最好单独加一个标志 + 回调来处理, 这样不容易导致混乱。

由于这些函数常常在帧循环中, 加上计算略显密集 (串行), 所以很多的错误都是无声的, 这极大
地增加了调试难度, 有点像GPU编程, 操, 我并不推荐使用这些。

插值需要指定骨骼映射和其排序, GetEntBonesFamilyLevel(ent, useLRU2) 可以辅助排序,
完成后再手动编码。

这里的插值分为两种 LerpBoneWorld 和 LerpBoneLocal
如果从本质来看, 世界空间的插值可以看做一种特殊的局部空间插值, 只是将所有骨骼的父级都看作是 World,
同时这里的 api 都是用骨骼名来指向操作的骨骼, 而不是 boneId, 这样的好处就是我可以将骨骼操纵拓展到
操作实体本身, 我们用 'self' 来表示实体本身, 同时我们还能将 'self' 映射到另一个实体的骨骼上来实现
骨架嫁接。 

关于操纵与获取
这里开放的其他底层包括 GetBoneMatrixLocal, GetBoneMatrixWorld, SetBonePositionLocal, SetBonePositionWorld
因为操纵是通过 ManipulateBonexxx 来实现的, 所以 SetBonePositionWorld 和 GetBoneMatrixWorld 有着必然的耦合。 (除了 'self')

所有涉及日志输出的函数均新增 silentlog 参数, 用于控制是否打印错误/提示日志, 调试时关闭该参数可获得详细信息, 上线后开启可减少冗余输出。
```

## 简介
这是一个**纯客户端**的API, 通过 **ent:ManipulateBonexxx** 等方法对骨骼进行直接的控制。  

优点: 
1.  直接操作骨骼, 无需通过 **ent:AddEffects(EF_BONEMERGE)** 、 **BuildBonePositions** 、 **ResetSequence** 等方法。
2.  相比 **VMLeg** , 它拥有淡出动画 并且 淡出动画不需要快照。  
3.  支持实体/快照双输入（entOrSnapshot）, 快照功能可减少重复骨骼矩阵获取操作, 提升性能。
4.  新增全局/局部回调机制, 支持自定义骨骼插值、快照处理逻辑, 灵活性拉满。
5.  骨骼映射表配置化, 批量操作骨骼更高效, 支持骨骼偏移、父级自定义等个性化配置。

缺点:
1.  运算量较大, 每次都需通过 **lua** 进行几次矩阵运算。
2.  需要每帧更新。
3.  无法处理奇异的矩阵, 这通常发生在骨骼缩放为0时。
4.  可能会和使用了 **ent:ManipulateBonexxx** 的方法冲突, 导致动画异常。
5.  对骨骼排序要求较高, 需按"先父后子"顺序配置, 否则子骨骼姿态会异常。

## 可用方法

![client](./materials/upgui/client.jpg)
**angle**, **vector** UPManip.SetBonePositionWorld(**entity** ent, **string** boneName, **vector** posw, **angle** angw, **bool** silentlog)
```note
控制指定实体的指定骨骼的位置和角度, 新的位置不能距离旧位置太远 (128个单位)
最好在调用之前使用 ent:SetupBones(), 因为计算中需要当前骨骼矩阵。
支持 'self' 关键字表示实体本身, 此时直接设置实体世界位置和角度。

内部会自动获取骨骼当前变换矩阵、父骨骼变换矩阵, 并进行矩阵逆运算转换操纵空间, 规避原生API限制。
矩阵奇异/父骨骼不存在时会打印错误日志（silentlog=false时）并返回nil。
这已经是最好用的, 其他更是一坨答辩
```

![client](./materials/upgui/client.jpg)
**angle**, **vector** UPManip.SetBonePositionLocal(**entity** ent, **string** boneName, **string** parentName, **vector** posl, **angle** angl, **bool** silentlog)
```note
按局部空间（相对自定义父骨骼/实体）控制指定骨骼的位置和角度，需每帧更新。
参数 parentName: 自定义父骨骼名，支持 'self' 关键字，默认为 nil（使用骨骼默认父级），用于指定局部空间的参考系。
支持 'self' 关键字表示实体本身，此时直接设置实体世界位置和角度。
内部分支逻辑：
1.  当骨骼默认父级与传入的自定义父级一致时，直接通过`ent:ManipulateBonexxx`操作骨骼姿态（针对性优化，减少矩阵运算）；
2.  当父级不一致时，通过父级世界矩阵与目标局部矩阵计算出世界变换矩阵，调用`SetBonePositionWorld`完成设置。
调用前建议执行 ent:SetupBones()，避免获取错误骨骼矩阵；父矩阵无效/矩阵奇异时打印日志并返回nil。
```

![client](./materials/upgui/client.jpg)
**void** UPManip.SetBoneScale(**entity** ent, **string** boneName, **vector** scale)
```note
设置指定实体的指定骨骼缩放比例，不支持实体本身（'self'关键字直接返回，无缩放效果）。
骨骼不存在时直接返回，不打印日志；调用前建议校验骨骼有效性。
需与骨骼位置/角度操纵配合使用，单独使用可能导致骨骼姿态异常。
```

![client](./materials/upgui/client.jpg)
**matrix**, **int** UPManip.GetBoneMatrixWorld(**entity** ent, **string** boneName)
```note
获取指定骨骼的世界空间变换矩阵, 返回骨骼矩阵和对应的boneId（非'self'时）。
支持 'self' 关键字, 此时返回实体自身的世界变换矩阵，boneId返回-1。
骨骼不存在时返回nil, 需提前校验实体有效性和骨骼名正确性。
```

![client](./materials/upgui/client.jpg)
**matrix**, **int**, **int** UPManip.GetBoneMatrixLocal(**entity** ent, **string** boneName, **string** parentName, **bool** invert)
```note
获取指定骨骼相对自定义父级的局部空间变换矩阵。
参数 parentName: 自定义父骨骼名, 支持 'self' 关键字, 不指定则使用骨骼默认父级。
参数 invert: 控制矩阵计算方向（正向/反向）, 用于不同空间转换场景：
  - invert=false（默认）：计算骨骼相对父级的局部矩阵（父级→骨骼）；
  - invert=true：计算父级相对骨骼的局部矩阵（骨骼→父级）。
返回值: 局部变换矩阵、当前骨骼Id、父骨骼Id（非'invert'模式且非'self'时）, 失败返回nil。
矩阵奇异时直接返回nil, 不打印日志，需自行通过IsMatrixSingular校验。
```

![client](./materials/upgui/client.jpg)
**table** UPManip.GetEntBonesFamilyLevel(**entity** ent, **bool** useLRU2)
```note
获取实体骨骼的父子层级深度表, 键为boneId, 值为层级深度（根骨骼层级为0）。
参数 useLRU2: 是否启用LRU2缓存, 按模型名缓存结果, 提升重复调用性能。
调用前会自动执行 ent:SetupBones(), 确保骨骼数据最新；实体无效/无模型/无根骨骼时打印错误日志并返回nil。
可用于骨骼插值时的排序辅助（先父后子）, 避免子骨骼姿态异常。
```

![client](./materials/upgui/client.jpg)
**bool** UPManip.IsMatrixSingular(**matrix** mat)
```note
工程化判断矩阵是否为奇异矩阵（无法求逆）, 非严谨数学方法, 性能优于行列式计算。
通过检查矩阵前向（Forward）、向上（Up）、右向（Right）向量的长度平方是否小于阈值（1e-2）来判断。
返回true表示矩阵奇异, 无法用于后续逆变换计算; 返回false表示矩阵可用。
常用于骨骼矩阵运算前的前置校验, 避免运行时错误。
```

![client](./materials/upgui/client.jpg)
**vector**, **angle**, **vector** UPManip.LerpBoneWorld(**number** t, **entity/table** entOrSnapshot, **entity/table** tarEntOrSnapshot, **string** boneName, **string** tarBoneName, **matrix** offsetMatrix, **bool** silentlog)
```note
世界空间下骨骼姿态线性插值, 实现当前骨骼向目标骨骼的平滑过渡, 仅返回插值结果, 不直接设置骨骼状态。
参数 t: 插值因子（建议0-1, 超出范围会出现过度插值）, 0为当前状态, 1为目标状态。
参数 entOrSnapshot/tarEntOrSnapshot: 支持实体（entity）或快照（table, 由SnapshotWorld生成）, 快照可提升批量操作性能。
参数 tarBoneName: 目标实体/快照的对应骨骼名, 不指定则与boneName一致（恒等映射）。
参数 offsetMatrix: 目标骨骼矩阵的偏移矩阵, 用于额外的位置/角度/缩放调整, 不指定则无偏移。
需每帧更新, 调用前建议执行 ent:SetupBones() 和 tarEnt:SetupBones()（传入实体时）, 骨骼矩阵不存在时打印日志并返回nil。
返回值: 插值后的世界位置（vector）、世界角度（angle）、缩放比例（vector）, 任一数据无效则返回nil。
```

![client](./materials/upgui/client.jpg)
**vector**, **angle**, **vector** UPManip.LerpBoneLocal(**number** t, **entity/table** entOrSnapshot, **entity/table** tarEntOrSnapshot, **string** boneName, **string** tarBoneName, **string** parentName, **string** tarParentName, **matrix** offsetMatrix, **bool** silentlog)
```note
局部空间下骨骼姿态线性插值, 相对自定义父级进行平滑过渡, 仅返回插值结果, 不直接设置骨骼状态, 灵活性更高。
参数 entOrSnapshot/tarEntOrSnapshot: 支持实体（entity）或快照（table, 由SnapshotLocal生成）。
参数 tarBoneName: 目标实体/快照对应骨骼名, 不指定则与boneName一致。
参数 parentName: 当前骨骼的自定义父级名, 不指定则使用默认父级。
参数 tarParentName: 目标骨骼的自定义父级名, 不指定则与parentName一致。
需每帧更新, 调用前建议执行 ent:SetupBones() 和 tarEnt:SetupBones()（传入实体时）, 骨骼矩阵不存在时打印日志并返回nil。
返回值: 插值后的局部位置（vector）、局部角度（angle）、缩放比例（vector）, 任一数据无效则返回nil。
```

![client](./materials/upgui/client.jpg)
**table** UPManip.SnapshotWorld(**entity** ent, **table** boneMapping)
```note
生成实体骨骼的世界空间快照, 缓存骨骼世界变换矩阵, 用于后续批量插值操作, 减少重复矩阵获取。
参数 boneMapping: 骨骼映射表, 必须包含 keySort（骨骼执行顺序）和 main（骨骼配置）子表, 支持 OnSnapshot 回调。
内部按 ipairs 遍历 keySort, 保证快照顺序与插值顺序一致；每根骨骼的矩阵数据会存入快照的 matTbl 字段。
参数 OnSnapshot: 快照回调函数, 格式为 handler(boneMapping, ent, boneName, data, 'world'), 可自定义处理骨骼矩阵数据。
快照结构: {ent = 目标实体, matTbl = 骨骼矩阵表, type = 'world'}
调用前建议执行 ent:SetupBones(), 实体无效时会触发assert断言报错。
```

![client](./materials/upgui/client.jpg)
**table** UPManip.SnapshotLocal(**entity** ent, **table** boneMapping)
```note
生成实体骨骼的局部空间快照, 缓存骨骼相对自定义父级的局部变换矩阵, 用于后续批量插值操作。
参数 boneMapping: 骨骼映射表, 必须包含 keySort（骨骼执行顺序）、main（骨骼配置）子表, 支持 OnSnapshot 回调。
内部按 ipairs 遍历 keySort, 自动读取 main 表中的 custParent 配置, 计算骨骼局部矩阵并缓存。
参数 OnSnapshot: 快照回调函数, 格式为 handler(boneMapping, ent, boneName, data, 'local'), 可自定义处理骨骼矩阵数据。
快照结构: {ent = 目标实体, matTbl = 骨骼矩阵表, type = 'local'}
调用前建议执行 ent:SetupBones(), 实体无效时会触发assert断言报错。
```

![client](./materials/upgui/client.jpg)
**matrix**, **int**, **entity** UPManip.UnpackSnapshotWorld(**entity/table** entOrSnapshot, **string** boneName, **bool** silentlog)
```note
从世界空间快照/实体中提取指定骨骼的世界变换矩阵、骨骼Id和对应实体。
参数 entOrSnapshot: 支持实体（entity）或世界空间快照（table, 由SnapshotWorld生成）。
骨骼不存在/快照类型不匹配时, 打印错误日志（silentlog=false时）并返回nil。
返回值: 骨骼世界变换矩阵、骨骼Id（非'self'时）、目标实体, 任一数据无效则返回nil。
```

![client](./materials/upgui/client.jpg)
**matrix**, **int**, **entity** UPManip.UnpackSnapshotLocal(**entity/table** entOrSnapshot, **string** boneName, **string** parentName, **bool** silentlog)
```note
从局部空间快照/实体中提取指定骨骼的局部变换矩阵、骨骼Id和对应实体。
参数 entOrSnapshot: 支持实体（entity）或局部空间快照（table, 由SnapshotLocal生成）。
参数 parentName: 自定义父骨骼名, 仅在传入实体时生效, 传入快照时忽略该参数（使用快照生成时的父级配置）。
骨骼不存在/快照类型不匹配时, 打印错误日志（silentlog=false时）并返回nil。
返回值: 骨骼局部变换矩阵、骨骼Id（非'self'时）、目标实体, 任一数据无效则返回nil。
```

![client](./materials/upgui/client.jpg)
**entity** UPManip.GetEntFromSnapshot(**entity/table** entOrSnapshot)
```note
快速从快照/实体中提取目标实体, 简化代码冗余逻辑。
参数 entOrSnapshot: 支持实体（entity）或快照（table, 由SnapshotWorld/SnapshotLocal生成）。
传入实体时直接返回该实体, 传入快照时返回快照的 ent 字段, 无效输入返回nil。
```

![client](./materials/upgui/client.jpg)
**void** UPManip.InitBoneMappingOffset(**table** boneMapping)
```note
验证骨骼映射表的有效性, 并将配置中的角度/位置/缩放转换为偏移矩阵（offset）, 为批量插值做准备。
骨骼映射表 boneMapping 必须包含以下字段：
  1.  main: 骨骼配置表, 键为骨骼名（string/'self'）, 值为true（无偏移）或包含ang/pos/scale/custParent/tarParent的表；
  2.  keySort: 骨骼执行顺序数组, 需按"先父后子"排序, 避免子骨骼姿态异常；
  3.  可选字段: WorldLerpHandler（全局世界空间插值回调）、LocalLerpHandler（全局局部空间插值回调）、OnSnapshot（快照回调）。
校验规则: 所有配置项类型错误时会触发assert断言报错, 提前规避运行时错误；custParent 和 tarParent 仅对局部空间插值有效。
转换规则: 自动将 ang（角度）、pos（位置）、scale（缩放）合并为 offset 偏移矩阵, 用于骨骼插值时的额外调整。
```

![client](./materials/upgui/client.jpg)
**void** UPManip.LerpBoneWorldByMapping(**number** t, **entity/table** entOrSnapshot, **entity/table** tarEntOrSnapshot, **table** boneMapping, **bool** scaling, **bool** silentlog)
```note
按骨骼映射表批量执行世界空间骨骼插值, 并自动设置骨骼位置、角度和缩放（可选）, 无需逐个调用LerpBoneWorld。
参数 entOrSnapshot/tarEntOrSnapshot: 支持实体（entity）或世界空间快照（table, 由SnapshotWorld生成）。
参数 boneMapping: 需先通过 UPManip.InitBoneMappingOffset 初始化验证, 包含 main、keySort 和可选 WorldLerpHandler。
参数 scaling: 是否启用骨骼缩放同步, true时自动调用 SetBoneScale 设置插值后的缩放比例。
参数 WorldLerpHandler: 全局回调函数, 格式为 handler(boneMapping, entOrSnapshot, tarEntOrSnapshot, boneName, newPos, newAng, newScale), 可自定义修改插值结果, 需返回三个值（pos/ang/scale）。
内部按 ipairs 遍历 keySort, 自动处理骨骼偏移和恒等映射, 插值失败时跳过当前骨骼, 不影响其他骨骼执行。
需每帧更新, 调用前建议执行 ent:SetupBones() 和 tarEnt:SetupBones()（传入实体时）。
```

![client](./materials/upgui/client.jpg)
**void** UPManip.LerpBoneLocalByMapping(**number** t, **entity/table** entOrSnapshot, **entity/table** tarEntOrSnapshot, **table** boneMapping, **bool** scaling, **bool** silentlog)
```note
按骨骼映射表批量执行局部空间骨骼插值, 并自动设置骨骼位置、角度和缩放（可选）, 无需逐个调用LerpBoneLocal。
参数 entOrSnapshot/tarEntOrSnapshot: 支持实体（entity）或局部空间快照（table, 由SnapshotLocal生成）。
参数 boneMapping: 需先通过 UPManip.InitBoneMappingOffset 初始化验证, 包含 main、keySort 和可选 LocalLerpHandler。
参数 scaling: 是否启用骨骼缩放同步, true时自动调用 SetBoneScale 设置插值后的缩放比例。
参数 LocalLerpHandler: 全局回调函数, 格式为 handler(boneMapping, entOrSnapshot, tarEntOrSnapshot, boneName, newPos, newAng, newScale), 可自定义修改插值结果, 需返回三个值（pos/ang/scale）。
内部按 ipairs 遍历 keySort, 自动读取 custParent/tarParent 配置和偏移矩阵, 插值失败时跳过当前骨骼, 不影响其他骨骼执行。
支持自定义父骨骼配置, 灵活性更高, 需每帧更新。
```