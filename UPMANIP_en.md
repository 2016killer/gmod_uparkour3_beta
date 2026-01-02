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

# UPManip Bone Manipulation

Use the console command `upmanip_test_world` or `upmanip_test_local` to see the demo effect.

```note

Note: This is a test module and is not recommended for use in production environments.

These are all very hard to use; they're basically a piece of shit.

The threshold for using this method is extremely high. First, ManipulateBonePosition has a distance limit of 128 units.
Therefore, to achieve correct interpolation, it must be done in the frame where the position update is completed.
To perform correct interpolation, it's best to add a separate flag + callback to handle it, which is less likely to cause confusion.

Since these functions are often in the frame loop and the calculations are somewhat intensive (serial), many errors are silent, which greatly
increases the difficulty of debugging—it's a bit like GPU programming, damn it. So I don't recommend using these.

Interpolation requires specifying bone mapping and its sorting. GetEntBonesFamilyLevel(ent, useLRU2) can assist in sorting,
and then manual coding is required after completion.

There are two types of interpolation here: LerpBoneWorld and LerpBoneLocal.
Essentially, world-space interpolation can be seen as a special type of local-space interpolation, except that the parent of all bones is regarded as the World.
At the same time, the APIs here use bone names to point to the bones to be manipulated instead of boneIds. This has the advantage that I can extend bone manipulation to
the entity itself—we use 'self' to represent the entity itself. Additionally, we can map 'self' to the bone of another entity to achieve
skeleton grafting.

Regarding Manipulation and Retrieval
Other underlying functions exposed here include GetBoneMatrixLocal, GetBoneMatrix, SetBonePositionLocal, and SetBonePosition.
Since manipulation is implemented through ManipulateBonexxx, there is an inevitable coupling between SetBonePosition and GetBoneMatrix. (Except for 'self')

I decided to add a silentlog parameter at the end of some functions to control whether to print logs, which will make debugging
more convenient.

```

## Introduction

This is a **pure client-side** API that directly controls bones through methods such as **ent:ManipulateBonexxx**.

### Advantages:

1. Directly manipulates bones without using methods like **ent:AddEffects(EF_BONEMERGE)**, **BuildBonePositions**, or **ResetSequence**.

2. Compared to **VMLeg**, it has fade-out animations, and fade-out animations do not require snapshots.

### Disadvantages:

1. High computational load; each call requires several matrix operations via **lua**.

2. Requires updating every frame.

3. Cannot handle singular matrices, which usually occur when bone scaling is 0.

4. May conflict with methods that use**ent:ManipulateBonexxx**, leading to abnormal animations.

## Available Methods

![client](./materials/upgui/client.jpg)

**angle**, **vector** UPManip.SetBonePosition(**entity** ent, **string** boneName, **vector** posw, **angle** angw, **bool** silentlog)

```note

Controls the position and angle of the specified bone of the specified entity. The new position cannot be too far from the old position (128 units).
It's best to use ent:SetupBones() before calling, as the current bone matrix is needed for calculations.
Supports the 'self' keyword to represent the entity itself, in which case it directly sets the entity's world position and angle.

This is already the easiest to use; the others are even bigger pieces of shit.

```

![client](./materials/upgui/client.jpg)

**angle**, **vector** UPManip.SetBonePositionLocal(**entity** ent, **string** boneName, **vector** posl, **angle** angl, **bool** silentlog)

```note

Controls the position and angle of the specified bone in local space (relative to the parent bone/entity). Requires updating every frame.
Supports the 'self' keyword to represent the entity itself, in which case it directly sets the entity's world position and angle.
It's recommended to execute ent:SetupBones() before calling to avoid obtaining incorrect bone matrices.

```

![client](./materials/upgui/client.jpg)

**matrix**, **int** UPManip.GetBoneMatrix(**entity** ent, **string** boneName)

```note

Gets the world-space transformation matrix of the specified bone. Returns the bone matrix and the corresponding boneId (when not 'self').
Supports the 'self' keyword, in which case it returns the entity's own world transformation matrix.
Returns nil if the bone does not exist; the validity of the entity needs to be verified in advance.

```

![client](./materials/upgui/client.jpg)

**matrix**, **int**, **int** UPManip.GetBoneMatrixLocal(**entity** ent, **string** boneName, **string** parentName, **bool** invert)

```note

Gets the local-space transformation matrix of the specified bone relative to a custom parent.
Parameter parentName: Custom parent bone name, supports the 'self' keyword. If not specified, the bone's default parent is used.
Parameter invert: Controls the direction of matrix calculation (forward/reverse) for different space transformation scenarios.
Return values: Local transformation matrix, current boneId, parent boneId (in non-invert mode). Returns nil on failure.

```

![client](./materials/upgui/client.jpg)

**table** UPManip.GetEntBonesFamilyLevel(**entity** ent, **bool** useLRU2)

```note

Gets the parent-child hierarchy depth table of the entity's bones. The key is boneId, and the value is the hierarchy depth (root bone level is 0).
Parameter useLRU2: Whether to enable LRU2 caching. Caches results by model name to improve repeated call performance.
Automatically executes ent:SetupBones() before calling. Prints an error log and returns nil if the entity is invalid/no model/no root bone.
Can be used to assist in sorting during bone interpolation (parent bones first, then child bones).

```

![client](./materials/upgui/client.jpg)

**bool** UPManip.IsMatrixSingular(**matrix** mat)

```note

Engineered method to determine if a matrix is singular (non-invertible). Not a rigorous mathematical method, but more performant than determinant calculation.
Judges by checking if the squared length of the matrix's forward, up, or right vectors is less than the threshold (1e-2).
Returns true if the matrix is singular and cannot be used for subsequent inverse transformation calculations; returns false if the matrix is usable.

```

![client](./materials/upgui/client.jpg)

**angle**, **vector**, **vector** UPManip.LerpBoneWorld(**number** t, **entity** ent, **entity** tarEnt, **string** boneName, **string** tarBoneName,**matrix** offsetMatrix, **bool** silentlog)

```note

Linear interpolation of bone posture in world space, achieving smooth transition from the current bone to the target bone.
Parameter t: Interpolation factor (recommended 0-1; values outside this range will cause over-interpolation). 0 is the current state, 1 is the target state.
Parameter tarBoneName: Corresponding bone name of the target entity. If not specified, it is consistent with boneName (identity mapping).
Parameter offsetMatrix: Offset matrix of the target bone matrix, used for additional position/angle/scale adjustments.
Requires updating every frame. It's recommended to execute ent:SetupBones() and tarEnt:SetupBones() before calling. Returns nil on failure.

```

![client](./materials/upgui/client.jpg)

**angle**, **vector**, **vector** UPManip.LerpBoneLocal(**number** t, **entity** ent, **entity** tarEnt, **string** boneName, **string** tarBoneName, **string** parentName, **string** tarParentName, **matrix** offsetMatrix, **bool** silentlog)

```note

Linear interpolation of bone posture in local space, achieving smooth transition relative to a custom parent with higher flexibility.
Parameter tarBoneName: Corresponding bone name of the target entity. If not specified, it is consistent with boneName.
Parameter parentName: Custom parent name of the current bone. If not specified, the default parent is used.
Parameter tarParentName: Custom parent name of the target bone. If not specified, it is consistent with parentName.
Requires updating every frame. It's recommended to execute ent:SetupBones() and tarEnt:SetupBones() before calling. Returns nil on failure.

```

![client](./materials/upgui/client.jpg)

**void** UPManip.InitBoneMappingOffset(**table** boneMapping)

```note

Verifies the validity of the bone mapping table and converts the angle/position/scale in the configuration into an offset matrix (offset).
The bone mapping table (boneMapping) must contain two sub-tables: main (bone configuration) and keySort (execution order).
The keys of the main table are bone names (string/'self'), and the values are either true (no offset) or a table containing fields such as ang/pos/scale.
The custParent and tarParent fields are only valid for local-space interpolation. It's recommended to specify tarParent when specifying custParent.
Triggers an assert error if parameters are invalid, used to avoid runtime errors in advance.

```

![client](./materials/upgui/client.jpg)

**void** UPManip.LerpBoneWorldByMapping(**number** t, **entity** ent, **entity** tarEnt, **table** boneMapping, **bool** silentlog)

```note

Batch executes world-space bone interpolation according to the bone mapping table, without calling LerpBoneWorld one by one.
boneMapping must be initialized and verified through UPManip.InitBoneMappingOffset first.
The keySort array determines the bone interpolation order, which must be "parent bones first, then child bones"; otherwise, child bone postures will be abnormal.
Requires updating every frame. It's recommended to execute ent:SetupBones() and tarEnt:SetupBones() before calling.

```

![client](./materials/upgui/client.jpg)

**void** UPManip.LerpBoneLocalByMapping(**number** t, **entity** ent, **entity** tarEnt, **table** boneMapping, **bool** silentlog)

```note

Batch executes local-space bone interpolation according to the bone mapping table, without calling LerpBoneLocal one by one.
boneMapping must be initialized and verified through UPManip.InitBoneMappingOffset first.
The keySort array determines the bone interpolation order, which must be "parent bones first, then child bones"; otherwise, child bone postures will be abnormal.
Supports custom parent bone configuration (custParent/tarParent) and requires updating every frame.

```