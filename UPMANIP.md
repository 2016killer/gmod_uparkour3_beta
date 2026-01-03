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

插值需要指定骨骼迭代器和其排序, ent:UPMaGetEntBonesFamilyLevel() 可以辅助排序,
完成后再手动编码。为什么不写自动排序? 因为有些骨架虽然骨骼名相同, 但是节点关系混乱,
比如 cw2 的 c_hand。

这里的插值分为两种 世界空间插值（CALL_FLAG_LERP_WORLD） 和 局部空间插值（CALL_FLAG_LERP_LOCAL）
如果从本质来看, 世界空间的插值可以看做一种特殊的局部空间插值, 只是将所有骨骼的父级都看作是 World,

同时这里的 API 都是用骨骼名来指向操作的骨骼, 而不是 boneId, 这对编写、调试都有好处, 缺点是不能像
数字索引那样高效地递归处理外部骨骼 (实体本身的父级等), 当然这里不需要, 又不是要操作机甲...

所以这里不处理实体本身, 因为一旦处理, 为了保证逻辑的一致性就必须要处理外部骨骼, 而这太低效了, 代码
的可读性和可维护性都要差很多, 还不如自行处理, 或者以后给UPManip加个拓展,
如果临时需要, 则在骨骼迭代器中传入自定义处理器。

所有涉及骨骼操纵的方法, 调用前建议执行 ent:SetupBones(), 确保获取到最新的骨骼矩阵数据, 避免计算异常。
```

## 简介
这是一个**纯客户端**的API, 通过 `ent:ManipulateBoneXXX` 等原生方法对骨骼进行直接控制，核心接口封装为 `Entity` 元表方法（前缀 `UPMa`），调用更直观。

优点: 
1.  直接操作骨骼, 无需通过 `ent:AddEffects(EF_BONEMERGE)`、`BuildBonePositions`、`ResetSequence` 等方法。
2.  支持实体/快照双输入（snapshotOrEnt）, 快照功能可减少重复骨骼矩阵获取操作, 提升帧循环运行性能。
3.  骨骼迭代器（boneIterator）配置化, 批量操作骨骼更高效, 支持骨骼偏移（角度/位置/缩放）、父级自定义等个性化配置。
4.  位标志（FLAG）错误处理机制, 无字符串拼接开销, 高效捕获所有异常场景（骨骼不存在、矩阵奇异等）。
5.  递归错误打印功能, 一键输出所有骨骼的异常信息, 大幅降低排错难度。
6.  精细化操纵标志（MANIP_FLAG）, 支持仅位置、仅角度、仅缩放等组合操纵, 灵活性拉满。
7.  根节点自动适配: 局部插值中自动识别根节点, 并强制切换为世界空间插值, 无需手动干预。

缺点:
1.  运算量较大, 每次都需通过 Lua 进行多次矩阵逆运算和乘法运算。
2.  需要每帧更新, 对客户端性能有一定消耗。
3.  无法处理奇异矩阵, 这通常发生在骨骼缩放为0时。
4.  可能会和使用了 `ent:ManipulateBoneXXX` 的其他方法冲突, 导致动画异常。
5.  对骨骼排序要求较高, 需按"先父后子"顺序配置骨骼迭代器, 否则子骨骼姿态会异常。
6.  `ManipulateBonePosition` 有128单位距离限制, 超出限制会导致骨骼操纵失效。

## 核心概念
### 1.  位标志（FLAG）
分为三类标志，通过 `bit.bor` 组合、`bit.band` 判断，高效传递状态信息：
-  错误标志（ERR_FLAG_*）：标识异常场景（如 `ERR_FLAG_BONEID` 表示骨骼不存在、`ERR_FLAG_SINGULAR` 表示矩阵奇异）。
-  调用标志（CALL_FLAG_*）：标识方法调用类型（如 `CALL_FLAG_SET_POSITION` 表示调用骨骼位置设置方法、`CALL_FLAG_SNAPSHOT` 表示调用快照生成方法）。
-  操纵标志（MANIP_FLAG_*）：标识骨骼操纵类型（如 `MANIP_POS` 表示仅设置位置、`MANIP_MATRIX` 表示位置+角度+缩放全量设置），对应 `UPManip.MANIP_FLAG` 全局表。

### 2.  骨骼迭代器（boneIterator）
纯数组格式的配置表，用于批量配置骨骼信息，每个数组元素为单骨骼配置表，示例如下：
```lua
local boneIterator = {
    {
        bone = "ValveBiped.Bip01_Head1", -- 必选：目标骨骼名
        tarBone = "ValveBiped.Bip01_Head1", -- 可选：目标实体对应骨骼名，默认与bone一致
        parent = "ValveBiped.Bip01_Neck1", -- 可选：自定义父骨骼名，默认使用骨骼原生父级
        tarParent = "ValveBiped.Bip01_Neck1", -- 可选：目标骨骼自定义父骨骼名，默认与parent一致
        ang = Angle(90, 0, 0), -- 可选：角度偏移
        pos = Vector(0, 0, 10), -- 可选：位置偏移
        scale = Vector(2, 2, 2), -- 可选：缩放偏移
        lerpMethod = CALL_FLAG_LERP_WORLD -- 可选：插值类型，默认 CALL_FLAG_LERP_LOCAL
    },
    -- 其他骨骼配置...
}
```
-  必选字段：`bone`（目标骨骼名）
-  可选字段：`tarBone`、`parent`、`tarParent`、`ang`、`pos`、`scale`、`lerpMethod`
-  初始化：需通过 `UPManip.InitBoneIterator(boneIterator)` 验证类型并生成偏移矩阵（offset）

### 3.  快照（Snapshot）
缓存骨骼变换矩阵的表结构，键为骨骼名，值为骨骼矩阵，由 `ent:UPMaSnapshot(boneIterator)` 生成，用于减少帧循环中重复的 `GetBoneMatrix` 调用，提升性能。

## 可用方法
### 骨骼层级相关
![client](./materials/upgui/client.jpg)
**table** ent:UPMaGetEntBonesFamilyLevel()
```note
获取实体骨骼的父子层级深度表, 键为 boneId, 值为层级深度（根骨骼层级为0）。
调用前会自动执行 ent:SetupBones(), 确保骨骼数据最新。
异常场景：实体无效、无模型、无根骨骼时，打印错误日志并返回 nil。
用途：辅助骨骼迭代器排序（按"先父后子"顺序），避免子骨骼姿态异常。
```

### 骨骼矩阵相关
![client](./materials/upgui/client.jpg)
**bool** UPManip.IsMatrixSingular(**matrix** mat)
```note
工程化判断矩阵是否为奇异矩阵（无法求逆）, 非严谨数学方法, 性能优于行列式计算。
判断逻辑：检查矩阵前向（Forward）、向上（Up）、右向（Right）向量的长度平方是否小于阈值（1e-2）。
返回值：true 表示矩阵奇异（无法使用），false 表示矩阵可用。
用途：骨骼矩阵运算前的前置校验，避免运行时错误。
```

![client](./materials/upgui/client.jpg)
**matrix** UPManip.GetMatrixLocal(**matrix** mat, **matrix** parentMat, **bool** invert)
```note
计算骨骼相对父级的局部变换矩阵，支持正向/反向计算。
参数说明：
- mat：目标骨骼矩阵
- parentMat：父骨骼矩阵
- invert：是否反向计算（false=骨骼相对父级，true=父级相对骨骼）
异常场景：矩阵奇异时返回 nil。
用途：局部空间插值的核心辅助方法，用于转换空间坐标系。
```

![client](./materials/upgui/client.jpg)
**matrix** UPManip.GetBoneMatrixFromSnapshot(**string** boneName, **entity/table** snapshotOrEnt)
```note
从实体或快照中提取指定骨骼的变换矩阵，无需区分实体/快照类型。
参数说明：
- boneName：目标骨骼名
- snapshotOrEnt：实体（entity）或快照（table）
返回值：骨骼变换矩阵，骨骼不存在时返回 nil。
用途：批量插值中快速获取骨骼矩阵，简化代码逻辑。
```

### 骨骼操纵相关
![client](./materials/upgui/client.jpg)
**int** ent:UPMaSetBonePosition(**string** boneName, **vector** posw, **angle** angw)
```note
控制指定骨骼的世界位置和角度，返回位标志（成功返回 SUCC_FLAG，失败返回对应 ERR_FLAG + CALL_FLAG_SET_POSITION）。
限制：新位置与旧位置的距离不能超过128个单位，否则操纵失效。
内部逻辑：自动获取骨骼当前矩阵、父骨骼矩阵，进行矩阵逆运算转换操纵空间，规避原生 API 限制。
调用前建议执行 ent:SetupBones()，确保矩阵数据最新。
```

![client](./materials/upgui/client.jpg)
**int** ent:UPMaSetBonePos(**string** boneName, **vector** posw)
```note
仅控制指定骨骼的世界位置，返回位标志（成功返回 SUCC_FLAG，失败返回对应 ERR_FLAG + CALL_FLAG_SET_POS）。
限制：新位置与旧位置的距离不能超过128个单位。
调用前建议执行 ent:SetupBones()。
```

![client](./materials/upgui/client.jpg)
**int** ent:UPMaSetBoneAng(**string** boneName, **angle** angw)
```note
仅控制指定骨骼的世界角度，返回位标志（成功返回 SUCC_FLAG，失败返回对应 ERR_FLAG + CALL_FLAG_SET_ANG）。
调用前建议执行 ent:SetupBones()。
```

![client](./materials/upgui/client.jpg)
**int** ent:UPMaSetBoneScale(**string** boneName, **vector** scale)
```note
仅设置指定骨骼的缩放比例，返回位标志（成功返回 SUCC_FLAG，失败返回对应 ERR_FLAG + CALL_FLAG_SET_SCALE）。
不支持实体本身，骨骼不存在时直接返回错误标志。
需与骨骼位置/角度操纵配合使用，单独使用可能导致姿态异常。
```

![client](./materials/upgui/client.jpg)
**int** ent:UPManipBoneBatch(**table** snapshot, **table** boneIterator, **int** manipflag)
```note
按骨骼迭代器批量操纵骨骼，快照数据来自 ent:UPMaLerpBoneBatch() 的插值结果。
参数说明：
- snapshot：插值后的骨骼数据快照（key=骨骼名，value={pos, ang, scale}）
- boneIterator：骨骼迭代器（需提前初始化）
- manipflag：操纵标志（来自 UPManip.MANIP_FLAG），支持组合使用
返回值：骨骼操纵状态表（key=骨骼名，value=位标志）
内部逻辑：按迭代器顺序遍历骨骼，根据 manipflag 调用对应操纵方法，插值数据无效时跳过当前骨骼。
```

### 快照相关
![client](./materials/upgui/client.jpg)
**table, table** ent:UPMaSnapshot(**table** boneIterator)
```note
生成实体骨骼的快照，缓存骨骼变换矩阵，返回快照表和状态标志表。
参数说明：
- boneIterator：骨骼迭代器（需提前初始化）
返回值：
- snapshot：快照表（key=骨骼名，value=骨骼矩阵）
- flags：状态标志表（key=骨骼名，value=位标志）
内部逻辑：按迭代器顺序遍历骨骼，获取矩阵并缓存，骨骼不存在/矩阵无效时记录错误标志。
用途：减少帧循环中重复获取骨骼矩阵的开销，提升性能。
```

### 骨骼插值相关
![client](./materials/upgui/client.jpg)
**table, table** ent:UPMaLerpBoneBatch(**number** t, **table** snapshot, **entity/table** tarSnapshotOrEnt, **table** boneIterator)
```note
批量执行骨骼姿态线性插值，仅返回插值结果，不直接设置骨骼状态，返回插值快照和状态标志表。
参数说明：
- t：插值因子（建议 0-1，超出范围会过度插值）
- snapshot：当前实体的骨骼快照（可选，不传则直接从实体获取骨骼矩阵）
- tarSnapshotOrEnt：目标实体或目标骨骼快照
- boneIterator：骨骼迭代器（需提前初始化）
返回值：
- lerpSnapshot：插值快照（key=骨骼名，value={pos, ang, scale}）
- flags：状态标志表（key=骨骼名，value=位标志）
内部逻辑：
1.  自动识别根节点，强制切换为世界空间插值
2.  支持世界空间（CALL_FLAG_LERP_WORLD）和局部空间（CALL_FLAG_LERP_LOCAL）两种插值模式
3.  自动应用骨骼偏移矩阵（offset），处理父级自定义配置
4.  插值失败时记录错误标志，跳过当前骨骼，不影响其他骨骼执行
调用前建议执行 ent:SetupBones() 和 目标实体:SetupBones()（传入实体时）。
```

### 错误处理相关
![client](./materials/upgui/client.jpg)
**void** ent:UPMaPrintErr(**int/table** runtimeflag, **string** boneName, **number** depth)
```note
递归打印骨骼操纵/插值过程中的错误信息，支持单个位标志和标志表两种输入。
参数说明：
- runtimeflag：位标志（number）或标志表（table，key=骨骼名，value=位标志）
- boneName：骨骼名（仅单个标志时有效，可选）
- depth：递归深度（内部使用，默认 0，最大 10）
用途：调试时一键输出所有异常信息，快速定位问题（如骨骼不存在、矩阵奇异等）。
```

### 初始化相关
![client](./materials/upgui/client.jpg)
**void** UPManip.InitBoneIterator(**table** boneIterator)
```note
验证骨骼迭代器的有效性，并将配置中的角度/位置/缩放偏移转换为偏移矩阵（offset）。
校验规则：
1.  骨骼迭代器必须是表类型
2.  迭代器元素必须是表类型，且包含 `bone` 字段（字符串类型）
3.  偏移配置（ang/pos/scale）必须是 angle/vector 类型或 nil
类型错误时触发 assert 断言报错，提前规避运行时错误。
转换规则：自动将 ang、pos、scale 合并为 offset 矩阵，用于插值时的额外调整。
```

## 全局常量与表
### 1.  位标志消息表
```lua
UPManip.RUNTIME_FLAG_MSG -- 位标志与错误信息的映射表，key=位标志，value=错误描述
```

### 2.  操纵标志表
```lua
UPManip.MANIP_FLAG = {
    MANIP_POS = 0x01, -- 仅设置位置
    MANIP_ANG = 0x02, -- 仅设置角度
    MANIP_SCALE = 0x04, -- 仅设置缩放
    MANIP_POSITION = 0x03, -- 设置位置+角度
    MANIP_MATRIX = 0x07, -- 设置位置+角度+缩放
}
```

### 3.  插值/调用标志
```lua
-- 插值类型
CALL_FLAG_LERP_WORLD = 0x1000 -- 世界空间插值
CALL_FLAG_LERP_LOCAL = 0x2000 -- 局部空间插值

-- 调用类型
CALL_FLAG_SET_POSITION = 0x4000 -- 调用 UP MaSetBonePosition
CALL_FLAG_SNAPSHOT = 0x8000 -- 调用 UPMaSnapshot
CALL_FLAG_SET_POS = 0x20000 -- 调用 UPMaSetBonePos
CALL_FLAG_SET_ANG = 0x40000 -- 调用 UPMaSetBoneAng
CALL_FLAG_SET_SCALE = 0x80000 -- 调用 UPMaSetBoneScale

-- 错误类型
ERR_FLAG_BONEID = 0x01 -- 骨骼不存在
ERR_FLAG_MATRIX = 0x02 -- 骨骼矩阵不存在
ERR_FLAG_SINGULAR = 0x04 -- 矩阵奇异
-- 更多错误标志详见代码内部定义
```

## 完整工作流示例
```lua
-- 1.  创建并初始化骨骼迭代器
local boneIterator = {
    {
        bone = "ValveBiped.Bip01_Head1",
        ang = Angle(90, 0, 0),
        scale = Vector(2, 2, 2),
        lerpMethod = CALL_FLAG_LERP_WORLD
    }
}
UPManip.InitBoneIterator(boneIterator)

-- 2.  获取目标实体
local ent = ClientsideModel("models/mossman.mdl", RENDERGROUP_OTHER)
local tarEnt = ClientsideModel("models/mossman.mdl", RENDERGROUP_OTHER)
ent:SetupBones()
tarEnt:SetupBones()

-- 3.  帧循环中执行插值与操纵
timer.Create("upmanip_demo", 0, 0, function()
    if not IsValid(ent) or not IsValid(tarEnt) then
        timer.Remove("upmanip_demo")
        return
    end

    -- 3.1  更新骨骼状态
    ent:SetupBones()
    tarEnt:SetupBones()

    -- 3.2  批量插值
    local lerpSnapshot, lerpFlags = ent:UPMaLerpBoneBatch(0.1, nil, tarEnt, boneIterator)
    ent:UPMaPrintErr(lerpFlags) -- 打印插值错误

    -- 3.3  批量操纵骨骼
    local manipFlags = ent:UPManipBoneBatch(lerpSnapshot, boneIterator, UPManip.MANIP_FLAG.MANIP_MATRIX)
    ent:UPMaPrintErr(manipFlags) -- 打印操纵错误
end)
```