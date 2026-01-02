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
Other underlying functions exposed here include GetBoneMatrixLocal, GetBoneMatrixWorld, SetBonePositionLocal, and SetBonePositionWorld.
Since manipulation is implemented through ManipulateBonexxx, there is an inevitable coupling between SetBonePositionWorld and GetBoneMatrixWorld. (Except for 'self')

All functions involving log output have added a `silentlog` parameter to control whether to print error/prompt logs. Disabling this parameter during debugging provides detailed information,
while enabling it in production reduces redundant output.
```

## Introduction
This is a **pure client-side** API that directly controls bones through methods such as **ent:ManipulateBonexxx**.

### Advantages:
1. Directly manipulates bones without using methods like **ent:AddEffects(EF_BONEMERGE)**, **BuildBonePositions**, or **ResetSequence**.
2. Compared to **VMLeg**, it has fade-out animations, and fade-out animations do not require snapshots.
3. Supports dual inputs of entity and snapshot (entOrSnapshot); the snapshot function reduces redundant bone matrix retrieval operations and improves performance.
4. New global and local callback mechanisms are added, supporting custom bone interpolation and snapshot processing logic with high flexibility.
5. Bone mapping table is configurable, making batch bone operations more efficient, and supporting personalized configurations such as bone offset and custom parent.
6. Optimized internal logic for partial scenarios (e.g., direct bone manipulation when parent is consistent) to reduce unnecessary matrix calculations.

### Disadvantages:
1. High computational load; each call requires several matrix operations via **lua**.
2. Requires updating every frame.
3. Cannot handle singular matrices, which usually occur when bone scaling is 0.
4. May conflict with methods that use **ent:ManipulateBonexxx**, leading to abnormal animations.
5. High requirements for bone sorting; the configuration must follow the "parent bones first, then child bones" order, otherwise child bone postures will be abnormal.

## Available Methods

![client](./materials/upgui/client.jpg)
**angle**, **vector** UPManip.SetBonePositionWorld(**entity** ent, **string** boneName, **vector** posw, **angle** angw, **bool** silentlog)
```note
Controls the position and angle of the specified bone of the specified entity. The new position cannot be too far from the old position (128 units).
It's best to use ent:SetupBones() before calling, as the current bone matrix is needed for calculations.
Supports the 'self' keyword to represent the entity itself, in which case it directly sets the entity's world position and angle.

Internally, it automatically obtains the current bone transformation matrix and parent bone transformation matrix, and performs matrix inverse transformation to convert the manipulation space, avoiding native API limitations.
Prints an error log (when silentlog=false) and returns nil if the matrix is singular or the parent bone does not exist.

This is already the easiest to use; the others are even bigger pieces of shit.
```

![client](./materials/upgui/client.jpg)
**angle**, **vector** UPManip.SetBonePositionLocal(**entity** ent, **string** boneName, **string** parentName, **vector** posl, **angle** angl, **bool** silentlog)
```note
Controls the position and angle of the specified bone in local space (relative to the custom parent bone/entity). Requires updating every frame.
Parameter parentName: Custom parent bone name, supports the 'self' keyword, default is nil (uses the bone's default parent), which is used to specify the reference frame of the local space.
Supports the 'self' keyword to represent the entity itself, in which case it directly sets the entity's world position and angle.
Internal branch logic:
1. When the bone's default parent is consistent with the incoming custom parent, directly manipulates the bone posture through `ent:ManipulateBonexxx` (targeted optimization to reduce matrix operations);
2. When the parents are inconsistent, calculates the world transformation matrix through the parent's world matrix and the target local matrix, and calls `SetBonePositionWorld` to complete the setting.

It's recommended to execute ent:SetupBones() before calling to avoid obtaining incorrect bone matrices. Prints a log and returns nil if the parent matrix is invalid or the matrix is singular.
```

![client](./materials/upgui/client.jpg)
**void** UPManip.SetBoneScale(**entity** ent, **string** boneName, **vector** scale)
```note
Sets the scaling ratio of the specified bone of the specified entity. Does not support the entity itself (the 'self' keyword returns directly with no scaling effect).
Returns directly without printing logs if the bone does not exist; it's recommended to verify bone validity before calling.
Should be used in conjunction with bone position/angle manipulation; using it alone may cause abnormal bone postures.
```

![client](./materials/upgui/client.jpg)
**matrix**, **int** UPManip.GetBoneMatrixWorld(**entity** ent, **string** boneName)
```note
Gets the world-space transformation matrix of the specified bone. Returns the bone matrix and the corresponding boneId (when not 'self').
Supports the 'self' keyword, in which case it returns the entity's own world transformation matrix and boneId returns -1.
Returns nil if the bone does not exist; the validity of the entity and the correctness of the bone name need to be verified in advance.
```

![client](./materials/upgui/client.jpg)
**matrix**, **int**, **int** UPManip.GetBoneMatrixLocal(**entity** ent, **string** boneName, **string** parentName, **bool** invert)
```note
Gets the local-space transformation matrix of the specified bone relative to a custom parent.
Parameter parentName: Custom parent bone name, supports the 'self' keyword. If not specified, the bone's default parent is used.
Parameter invert: Controls the direction of matrix calculation (forward/reverse) for different space transformation scenarios:
  - invert=false (default): Calculates the local matrix of the bone relative to the parent (parent → bone);
  - invert=true: Calculates the local matrix of the parent relative to the bone (bone → parent).

Return values: Local transformation matrix, current boneId, parent boneId (in non-invert mode and not 'self'). Returns nil on failure.
Returns nil directly without printing logs if the matrix is singular; you need to verify it in advance with IsMatrixSingular.
```

![client](./materials/upgui/client.jpg)
**table** UPManip.GetEntBonesFamilyLevel(**entity** ent, **bool** useLRU2)
```note
Gets the parent-child hierarchy depth table of the entity's bones. The key is boneId, and the value is the hierarchy depth (root bone level is 0).
Parameter useLRU2: Whether to enable LRU2 caching. Caches results by model name to improve repeated call performance.
Automatically executes ent:SetupBones() before calling to ensure the latest bone data. Prints an error log and returns nil if the entity is invalid/no model/no root bone.
Can be used to assist in sorting during bone interpolation (parent bones first, then child bones) to avoid abnormal child bone postures.
```

![client](./materials/upgui/client.jpg)
**bool** UPManip.IsMatrixSingular(**matrix** mat)
```note
Engineered method to determine if a matrix is singular (non-invertible). Not a rigorous mathematical method, but more performant than determinant calculation.
Judges by checking if the squared length of the matrix's forward, up, or right vectors is less than the threshold (1e-2).
Returns true if the matrix is singular and cannot be used for subsequent inverse transformation calculations; returns false if the matrix is usable.
Often used for pre-validation before bone matrix operations to avoid runtime errors.
```

![client](./materials/upgui/client.jpg)
**vector**, **angle**, **vector** UPManip.LerpBoneWorld(**number** t, **entity/table** entOrSnapshot, **entity/table** tarEntOrSnapshot, **string** boneName, **string** tarBoneName, **matrix** offsetMatrix, **bool** silentlog)
```note
Linear interpolation of bone posture in world space, achieving smooth transition from the current bone to the target bone. Only returns interpolation results, does not directly set bone states.
Parameter t: Interpolation factor (recommended 0-1; values outside this range will cause over-interpolation). 0 is the current state, 1 is the target state.
Parameter entOrSnapshot/tarEntOrSnapshot: Supports entity (entity) or snapshot (table, generated by SnapshotWorld), which can improve batch operation performance.
Parameter tarBoneName: Corresponding bone name of the target entity/snapshot. If not specified, it is consistent with boneName (identity mapping).
Parameter offsetMatrix: Offset matrix of the target bone matrix, used for additional position/angle/scale adjustments. No offset if not specified.

Requires updating every frame. It's recommended to execute ent:SetupBones() and tarEnt:SetupBones() (when passing entities) before calling. Prints a log and returns nil if the bone matrix does not exist.
Return values: Interpolated world position (vector), world angle (angle), scaling ratio (vector). Returns nil if any data is invalid.
```

![client](./materials/upgui/client.jpg)
**vector**, **angle**, **vector** UPManip.LerpBoneLocal(**number** t, **entity/table** entOrSnapshot, **entity/table** tarEntOrSnapshot, **string** boneName, **string** tarBoneName, **string** parentName, **string** tarParentName, **matrix** offsetMatrix, **bool** silentlog)
```note
Linear interpolation of bone posture in local space, achieving smooth transition relative to a custom parent with higher flexibility. Only returns interpolation results, does not directly set bone states.
Parameter entOrSnapshot/tarEntOrSnapshot: Supports entity (entity) or snapshot (table, generated by SnapshotLocal).
Parameter tarBoneName: Corresponding bone name of the target entity/snapshot. If not specified, it is consistent with boneName.
Parameter parentName: Custom parent name of the current bone. If not specified, the default parent is used.
Parameter tarParentName: Custom parent name of the target bone. If not specified, it is consistent with parentName.

Requires updating every frame. It's recommended to execute ent:SetupBones() and tarEnt:SetupBones() (when passing entities) before calling. Prints a log and returns nil if the bone matrix does not exist.
Return values: Interpolated local position (vector), local angle (angle), scaling ratio (vector). Returns nil if any data is invalid.
```

![client](./materials/upgui/client.jpg)
**table** UPManip.SnapshotWorld(**entity** ent, **table** boneMapping)
```note
Generates a world-space snapshot of the entity's bones, caches the bone world transformation matrix for subsequent batch interpolation operations, and reduces redundant matrix retrieval.
Parameter boneMapping: Bone mapping table, which must contain keySort (bone execution order) and main (bone configuration) sub-tables, and supports the OnSnapshot callback.
Internally traverses keySort with ipairs to ensure the snapshot order is consistent with the interpolation order; the matrix data of each bone is stored in the matTbl field of the snapshot.
Parameter OnSnapshot: Snapshot callback function, in the format of handler(boneMapping, ent, boneName, data, 'world'), which can be used to custom process bone matrix data.
Snapshot structure: {ent = Target Entity, matTbl = Bone Matrix Table, type = 'world'}
It's recommended to execute ent:SetupBones() before calling. Triggers an assert error if the entity is invalid.
```

![client](./materials/upgui/client.jpg)
**table** UPManip.SnapshotLocal(**entity** ent, **table** boneMapping)
```note
Generates a local-space snapshot of the entity's bones, caches the bone local transformation matrix relative to the custom parent for subsequent batch interpolation operations.
Parameter boneMapping: Bone mapping table, which must contain keySort (bone execution order) and main (bone configuration) sub-tables, and supports the OnSnapshot callback.
Internally traverses keySort with ipairs, automatically reads the custParent configuration in the main table, calculates and caches the bone local matrix.
Parameter OnSnapshot: Snapshot callback function, in the format of handler(boneMapping, ent, boneName, data, 'local'), which can be used to custom process bone matrix data.
Snapshot structure: {ent = Target Entity, matTbl = Bone Matrix Table, type = 'local'}
It's recommended to execute ent:SetupBones() before calling. Triggers an assert error if the entity is invalid.
```

![client](./materials/upgui/client.jpg)
**matrix**, **int**, **entity** UPManip.UnpackSnapshotWorld(**entity/table** entOrSnapshot, **string** boneName, **bool** silentlog)
```note
Extracts the world transformation matrix, boneId, and corresponding entity of the specified bone from the world-space snapshot or entity.
Parameter entOrSnapshot: Supports entity (entity) or world-space snapshot (table, generated by SnapshotWorld).
Prints an error log (when silentlog=false) and returns nil if the bone does not exist or the snapshot type does not match.
Return values: Bone world transformation matrix, boneId (when not 'self'), target entity. Returns nil if any data is invalid.
```

![client](./materials/upgui/client.jpg)
**matrix**, **int**, **entity** UPManip.UnpackSnapshotLocal(**entity/table** entOrSnapshot, **string** boneName, **string** parentName, **bool** silentlog)
```note
Extracts the local transformation matrix, boneId, and corresponding entity of the specified bone from the local-space snapshot or entity.
Parameter entOrSnapshot: Supports entity (entity) or local-space snapshot (table, generated by SnapshotLocal).
Parameter parentName: Custom parent bone name, which only takes effect when passing an entity and is ignored when passing a snapshot (uses the parent configuration when the snapshot was generated).
Prints an error log (when silentlog=false) and returns nil if the bone does not exist or the snapshot type does not match.
Return values: Bone local transformation matrix, boneId (when not 'self'), target entity. Returns nil if any data is invalid.
```

![client](./materials/upgui/client.jpg)
**entity** UPManip.GetEntFromSnapshot(**entity/table** entOrSnapshot)
```note
Quickly extracts the target entity from the snapshot or entity to simplify redundant code logic.
Parameter entOrSnapshot: Supports entity (entity) or snapshot (table, generated by SnapshotWorld/SnapshotLocal).
Returns the entity directly when passing an entity, returns the ent field of the snapshot when passing a snapshot, and returns nil for invalid input.
```

![client](./materials/upgui/client.jpg)
**void** UPManip.InitBoneMappingOffset(**table** boneMapping)
```note
Verifies the validity of the bone mapping table and converts the angle/position/scale in the configuration into an offset matrix (offset) to prepare for batch interpolation.
The bone mapping table (boneMapping) must contain the following fields:
  1. main: Bone configuration table, where keys are bone names (string/'self'), and values are either true (no offset) or a table containing ang/pos/scale/custParent/tarParent;
  2. keySort: Bone execution order array, which must follow the "parent bones first, then child bones" order to avoid abnormal child bone postures;
  3. Optional fields: WorldLerpHandler (global world-space interpolation callback), LocalLerpHandler (global local-space interpolation callback), OnSnapshot (snapshot callback).

Validation rules: Triggers an assert error if the type of any configuration item is incorrect, avoiding runtime errors in advance; custParent and tarParent are only valid for local-space interpolation.
Conversion rules: Automatically merges ang (angle), pos (position), and scale (scaling) into an offset matrix for additional adjustments during bone interpolation.
```

![client](./materials/upgui/client.jpg)
**void** UPManip.LerpBoneWorldByMapping(**number** t, **entity/table** entOrSnapshot, **entity/table** tarEntOrSnapshot, **table** boneMapping, **bool** scaling, **bool** silentlog)
```note
Batch executes world-space bone interpolation according to the bone mapping table, and automatically sets bone position, angle, and scaling (optional), without calling LerpBoneWorld one by one.
Parameter entOrSnapshot/tarEntOrSnapshot: Supports entity (entity) or world-space snapshot (table, generated by SnapshotWorld).
Parameter boneMapping: Must be initialized and verified through UPManip.InitBoneMappingOffset first, containing main, keySort, and optional WorldLerpHandler.
Parameter scaling: Whether to enable bone scaling synchronization; if true, automatically calls SetBoneScale to set the interpolated scaling ratio.
Parameter WorldLerpHandler: Global callback function, in the format of handler(boneMapping, entOrSnapshot, tarEntOrSnapshot, boneName, newPos, newAng, newScale, t), which can custom modify interpolation results and must return three values (pos/ang/scale).

Internally traverses keySort with ipairs, automatically handles bone offset and identity mapping, and skips the current bone if interpolation fails without affecting the execution of other bones.
Requires updating every frame. It's recommended to execute ent:SetupBones() and tarEnt:SetupBones() (when passing entities) before calling.
```

![client](./materials/upgui/client.jpg)
**void** UPManip.LerpBoneLocalByMapping(**number** t, **entity/table** entOrSnapshot, **entity/table** tarEntOrSnapshot, **table** boneMapping, **bool** scaling, **bool** silentlog)
```note
Batch executes local-space bone interpolation according to the bone mapping table, and automatically sets bone position, angle, and scaling (optional), without calling LerpBoneLocal one by one.
Parameter entOrSnapshot/tarEntOrSnapshot: Supports entity (entity) or local-space snapshot (table, generated by SnapshotLocal).
Parameter boneMapping: Must be initialized and verified through UPManip.InitBoneMappingOffset first, containing main, keySort, and optional LocalLerpHandler.
Parameter scaling: Whether to enable bone scaling synchronization; if true, automatically calls SetBoneScale to set the interpolated scaling ratio.
Parameter LocalLerpHandler: Global callback function, in the format of handler(boneMapping, entOrSnapshot, tarEntOrSnapshot, boneName, newPos, newAng, newScale, t), which can custom modify interpolation results and must return three values (pos/ang/scale).

Internally traverses keySort with ipairs, automatically reads custParent/tarParent configuration and offset matrix, and skips the current bone if interpolation fails without affecting the execution of other bones.
Supports custom parent bone configuration with higher flexibility and requires updating every frame.
```