# UPManip Bone Manipulation
Use the console commands `upmanip_test_world` or `upmanip_test_local` to view the demo effects.

```note
Note: This is a test module and is not recommended for use in production environments.

These are all very hard to use; they're basically a piece of shit.

The threshold for using this method is extremely high. First, `ManipulateBonePosition` has a distance limit of 128 units.
Therefore, to achieve correct interpolation, the operation must be performed in the frame where the position update is completed.
For accurate interpolation, it is best to use a separate flag plus callback for handling, which reduces the chance of confusion.

Since these functions are often executed in the frame loop and the calculations are relatively intensive (serial execution), many errors are silent, which greatly
increases debugging difficulty—it's a bit like GPU programming, damn it. I do not recommend using these functions.

Interpolation requires specifying a bone iterator and its sorting order. The method `ent:UPMaGetEntBonesFamilyLevel()` can assist with sorting,
after which manual coding is required. Why not implement automatic sorting? Because some skeletons share the same bone names but have chaotic node
hierarchies, such as the `c_hand` in CW2.

There are two types of interpolation here: World-Space Interpolation (`CALL_FLAG_LERP_WORLD`) and Local-Space Interpolation (`CALL_FLAG_LERP_LOCAL`).
Essentially, world-space interpolation can be regarded as a special type of local-space interpolation, with the parent of all bones treated as the World.

Additionally, the APIs here use bone names (instead of boneIds) to target bones for manipulation. This simplifies writing and debugging, but the downside
is that it cannot efficiently recursively process external bones (such as the parent of the entity itself) like numeric indices can. Of course, this is unnecessary here—
we're not manipulating mecha skeletons, after all.

Entity self-manipulation is not supported here. Once enabled, maintaining logical consistency would require handling external bones, which is inefficient
and would severely reduce code readability and maintainability. It is better to handle this scenario manually or add an extension to UPManip in the future.
If temporary support is needed, you can pass a custom processor in the bone iterator.

For all methods involving bone manipulation, it is recommended to execute `ent:SetupBones()` before calling to ensure access to the latest bone matrix data and avoid calculation anomalies.
```

## Introduction
This is a **pure client-side** API that directly controls bones via native methods such as `ent:ManipulateBoneXXX`. Core interfaces are encapsulated as `Entity` metatable methods (prefixed with `UPMa`) for more intuitive calls.

### Advantages:
1. Directly manipulates bones without relying on methods like `ent:AddEffects(EF_BONEMERGE)`, `BuildBonePositions`, or `ResetSequence`.
2. Supports dual inputs (entity/snapshot, referred to as `snapshotOrEnt`). The snapshot feature reduces redundant bone matrix retrieval operations and improves frame loop performance.
3. Configurable bone iterators enable efficient batch bone operations, with support for personalized configurations such as bone offsets (angle/position/scale) and custom parent bones.
4. Bit flag-based error handling mechanism (no string concatenation overhead) efficiently captures all exception scenarios (e.g., non-existent bones, singular matrices).
5. Recursive error printing functionality outputs all bone exception information with one click, significantly reducing debugging effort.
6. Granular manipulation flags (`MANIP_FLAG`) support combined operations (position-only, angle-only, scale-only, etc.) for maximum flexibility.
7. Automatic root node adaptation: Automatically identifies root nodes during local-space interpolation and forces a switch to world-space interpolation without manual intervention.
8. Supports insertable custom callbacks to dynamically modify interpolation behavior and targets, providing extremely strong extensibility.

### Disadvantages:
1. High computational overhead: Each call requires multiple matrix inverse and multiplication operations via Lua.
2. Requires per-frame updates, which consumes certain client-side performance resources.
3. Cannot handle singular matrices, which typically occur when bone scaling is set to 0.
4. May conflict with other methods that use `ent:ManipulateBoneXXX`, leading to abnormal animations.
5. Strict requirements for bone sorting: Bone iterators must be configured in the "parent first, child second" order; otherwise, child bone postures will be abnormal.
6. `ManipulateBonePosition` has a 128-unit distance limit—exceeding this limit will cause bone manipulation to fail.

## Core Concepts
### 1. Bit Flags
Three categories of flags are supported, combined via `bit.bor` and checked via `bit.band` for efficient state information transmission:
- Error Flags (`ERR_FLAG_*`): Identify exception scenarios (e.g., `ERR_FLAG_BONEID` for non-existent bones, `ERR_FLAG_SINGULAR` for singular matrices).
- Call Flags (`CALL_FLAG_*`): Identify method call types (e.g., `CALL_FLAG_SET_POSITION` for bone position setting, `CALL_FLAG_SNAPSHOT` for snapshot generation).
- Manipulation Flags (`MANIP_FLAG_*`): Identify bone manipulation types (e.g., `MANIP_POS` for position-only setting, `MANIP_MATRIX` for full position/angle/scale setting), corresponding to the global `UPManip.MANIP_FLAG` table.

### 2. Bone Iterator
A pure array-based configuration table for batch bone configuration. Each array element is a single bone configuration table, as shown in the example below:
```lua
local boneIterator = {
    {
        bone = "ValveBiped.Bip01_Head1", -- Required: Target bone name
        tarBone = "ValveBiped.Bip01_Head1", -- Optional: Corresponding bone name in target entity (defaults to `bone` if not specified)
        parent = "ValveBiped.Bip01_Neck1", -- Optional: Custom parent bone name (defaults to the bone's native parent if not specified)
        tarParent = "ValveBiped.Bip01_Neck1", -- Optional: Custom parent bone name for target bone (defaults to `parent` if not specified)
        ang = Angle(90, 0, 0), -- Optional: Angle offset
        pos = Vector(0, 0, 10), -- Optional: Position offset
        scale = Vector(2, 2, 2), -- Optional: Scale offset
        lerpMethod = CALL_FLAG_LERP_WORLD -- Optional: Interpolation type (defaults to `CALL_FLAG_LERP_LOCAL` if not specified)
    },
    -- Additional bone configurations...
    -- Top-level callback fields (globally effective, optional)
    UnpackMappingData = nil, -- Optional: Callback for dynamically unpacking bone configuration
    LerpRangeHandler = nil, -- Optional: Callback for redirecting interpolation targets
}
```
- Required Field: `bone` (target bone name)
- Optional Fields: `tarBone`, `parent`, `tarParent`, `ang`, `pos`, `scale`, `lerpMethod`
- Top-Level Callback Fields: `UnpackMappingData`, `LerpRangeHandler` (globally effective for the iterator, optional)
- Initialization: Must be initialized via `UPManip.InitBoneIterator(boneIterator)` to validate types and generate offset matrices.

### 3. Snapshot
A table structure that caches bone transformation matrices, with bone names as keys and bone matrices as values. Generated via `ent:UPMaSnapshot(boneIterator)`, it reduces redundant `GetBoneMatrix` calls in the frame loop to improve performance.

### 4. Insertable Callbacks
The bone iterator supports two top-level custom callbacks for dynamically extending interpolation behavior without modifying the core UPManip logic, providing strong extensibility.

#### 4.1 UnpackMappingData: Add Dynamic Features to Interpolation Behavior
```note
Purpose: Dynamically unpack/modify the configuration data (`mappingData`) of a single bone before interpolation execution, supporting adjustments to bone offsets, parent nodes, interpolation types, etc., based on runtime states.
Scope: Top-level field of the bone iterator, globally effective.
Parameter List:
1.  self: The entity currently executing interpolation (Entity)
2.  t: Interpolation factor (number, consistent with the `t` parameter of `UPMaLerpBoneBatch`)
3.  snapshot: Bone snapshot of the current entity (table, optional, may be `nil`)
4.  tarSnapshotOrEnt: Target entity or target bone snapshot (Entity/table)
5.  mappingData: Original configuration data of the current bone (table)
Return Value: Modified bone configuration data (table). If `nil` is returned, the original configuration will be used.
Use Cases:
-  Dynamically adjust bone offsets in the frame loop (e.g., modify angle offset based on entity state)
-  Switch interpolation types at runtime (e.g., temporarily switch from local interpolation to world interpolation in certain scenarios)
-  Dynamically specify custom parent bones to achieve more flexible bone hierarchy control
```
Example:
```lua
local boneIterator = {
    { bone = "ValveBiped.Bip01_Head1" },
    -- Dynamically modify bone configuration
    UnpackMappingData = function(self, t, snapshot, tarSnapshotOrEnt, mappingData)
        -- Dynamically adjust angle offset based on interpolation factor
        mappingData.ang = Angle(90 * t, 0, 0)
        -- Switch interpolation type at runtime based on entity velocity
        if self:GetVelocity():Length() > 0 then
            mappingData.lerpMethod = CALL_FLAG_LERP_WORLD
        else
            mappingData.lerpMethod = CALL_FLAG_LERP_LOCAL
        end
        return mappingData
    end
}
```

#### 4.2 LerpRangeHandler: Allow Redirecting Interpolation Targets
```note
Purpose: Redirect/modify the initial matrix (`initMatrix`) and target matrix (`finalMatrix`) before interpolation calculation, supporting custom interpolation ranges, target posture correction, and other operations.
Scope: Top-level field of the bone iterator, globally effective.
Parameter List:
1.  self: The entity currently executing interpolation (Entity)
2.  t: Interpolation factor (number, consistent with the `t` parameter of `UPMaLerpBoneBatch`)
3.  snapshot: Bone snapshot of the current entity (table, optional, may be `nil`)
4.  tarSnapshotOrEnt: Target entity or target bone snapshot (Entity/table)
5.  initMatrix: Initial transformation matrix of the current bone (matrix)
6.  finalMatrix: Target transformation matrix of the current bone (matrix)
7.  mappingData: Configuration data of the current bone (table, already processed by `UnpackMappingData`)
Return Value: Modified initial matrix (`initMatrix`) and target matrix (`finalMatrix`). If `nil` is returned, the original matrices will be used.
Use Cases:
-  Redirect interpolation targets (e.g., limit bone rotation angle range to avoid excessive deformation)
-  Correct target bone postures (e.g., compensate for abnormal matrices to solve clipping issues)
-  Custom interpolation logic (e.g., add ease-in/ease-out effects to replace linear interpolation)
```
Example:
```lua
local boneIterator = {
    { bone = "ValveBiped.Bip01_Head1" },
    -- Redirect interpolation targets and limit rotation range
    LerpRangeHandler = function(self, t, snapshot, tarSnapshotOrEnt, initMatrix, finalMatrix, mappingData)
        -- Get initial and target angles
        local initAng = initMatrix:GetAngles()
        local finalAng = finalMatrix:GetAngles()
        -- Limit X-axis rotation between -90 and 90 degrees
        finalAng.p = math.Clamp(finalAng.p, -90, 90)
        -- Update target matrix
        finalMatrix:SetAngles(finalAng)
        -- Return modified matrices
        return initMatrix, finalMatrix
    end
}
```

## Available Methods
### Bone Hierarchy Related
![client](./materials/upgui/client.jpg)
**table** ent:UPMaGetEntBonesFamilyLevel()
```note
Retrieves the parent-child hierarchy depth table of the entity's bones. Keys are boneIds, and values are hierarchy depths (root bones have a depth of 0).
Automatically executes `ent:SetupBones()` before calling to ensure the latest bone data is used.
Exception Scenarios: Prints an error log and returns `nil` if the entity is invalid, has no model, or no root bone.
Use Case: Assists with bone iterator sorting (parent first, child second) to avoid abnormal child bone postures.
```

### Bone Matrix Related
![client](./materials/upgui/client.jpg)
**bool** UPManip.IsMatrixSingular(**matrix** mat)
```note
Engineered method to determine if a matrix is singular (non-invertible). Not a rigorous mathematical method, but more performant than determinant calculation.
Judgment Logic: Checks if the squared length of the matrix's Forward, Up, or Right vectors is less than the threshold (1e-2).
Return Value: `true` indicates the matrix is singular (unusable); `false` indicates the matrix is valid.
Use Case: Pre-validation before bone matrix operations to avoid runtime errors.
```

![client](./materials/upgui/client.jpg)
**matrix** UPManip.GetMatrixLocal(**matrix** mat, **matrix** parentMat, **bool** invert)
```note
Calculates the local transformation matrix of a bone relative to its parent, supporting forward and reverse calculations.
Parameter Descriptions:
- mat: Target bone matrix
- parentMat: Parent bone matrix
- invert: Whether to perform reverse calculation (`false` = bone relative to parent; `true` = parent relative to bone)
Exception Scenario: Returns `nil` if the matrix is singular.
Use Case: Core auxiliary method for local-space interpolation to convert coordinate systems.
```

![client](./materials/upgui/client.jpg)
**matrix** UPManip.GetBoneMatrixFromSnapshot(**string** boneName, **entity/table** snapshotOrEnt)
```note
Extracts the transformation matrix of the specified bone from an entity or snapshot, without requiring distinction between entity and snapshot types.
Parameter Descriptions:
- boneName: Target bone name
- snapshotOrEnt: Entity (entity) or snapshot (table)
Return Value: Bone transformation matrix (returns `nil` if the bone does not exist).
Use Case: Quickly retrieve bone matrices during batch interpolation to simplify code logic.
```

### Bone Manipulation Related
![client](./materials/upgui/client.jpg)
**int** ent:UPMaSetBonePosition(**string** boneName, **vector** posw, **angle** angw)
```note
Controls the world position and angle of the specified bone. Returns a bit flag (`SUCC_FLAG` for success; corresponding `ERR_FLAG` + `CALL_FLAG_SET_POSITION` for failure).
Limit: The distance between the new and old positions cannot exceed 128 units (otherwise, manipulation will fail).
Internal Logic: Automatically retrieves the current bone matrix and parent bone matrix, performs matrix inverse transformation to convert the manipulation space, and bypasses native API limitations.
It is recommended to execute `ent:SetupBones()` before calling to ensure up-to-date matrix data.
```

![client](./materials/upgui/client.jpg)
**int** ent:UPMaSetBonePos(**string** boneName, **vector** posw)
```note
Controls only the world position of the specified bone. Returns a bit flag (`SUCC_FLAG` for success; corresponding `ERR_FLAG` + `CALL_FLAG_SET_POS` for failure).
Limit: The distance between the new and old positions cannot exceed 128 units.
It is recommended to execute `ent:SetupBones()` before calling.
```

![client](./materials/upgui/client.jpg)
**int** ent:UPMaSetBoneAng(**string** boneName, **angle** angw)
```note
Controls only the world angle of the specified bone. Returns a bit flag (`SUCC_FLAG` for success; corresponding `ERR_FLAG` + `CALL_FLAG_SET_ANG` for failure).
It is recommended to execute `ent:SetupBones()` before calling.
```

![client](./materials/upgui/client.jpg)
**int** ent:UPMaSetBoneScale(**string** boneName, **vector** scale)
```note
Sets only the scale ratio of the specified bone. Returns a bit flag (`SUCC_FLAG` for success; corresponding `ERR_FLAG` + `CALL_FLAG_SET_SCALE` for failure).
Does not support entity self-manipulation (returns an error flag directly if the bone does not exist).
Should be used in conjunction with bone position/angle manipulation (using it alone may cause abnormal postures).
```

![client](./materials/upgui/client.jpg)
**int** ent:UPManipBoneBatch(**table** snapshot, **table** boneIterator, **int** manipflag)
```note
Batch manipulates bones via a bone iterator, with snapshot data derived from the interpolation results of `ent:UPMaLerpBoneBatch()`.
Parameter Descriptions:
- snapshot: Interpolated bone data snapshot (keys = bone names, values = {pos, ang, scale})
- boneIterator: Pre-initialized bone iterator
- manipflag: Manipulation flag (from `UPManip.MANIP_FLAG`), supporting combined usage
Return Value: Bone manipulation status table (keys = bone names, values = bit flags)
Internal Logic: Iterates over bones in iterator order, calls corresponding manipulation methods based on `manipflag`, and skips bones with invalid interpolation data.
```

### Snapshot Related
![client](./materials/upgui/client.jpg)
**table, table** ent:UPMaSnapshot(**table** boneIterator)
```note
Generates a snapshot of the entity's bones, caches bone transformation matrices, and returns a snapshot table and status flag table.
Parameter Description:
- boneIterator: Pre-initialized bone iterator
Return Values:
- snapshot: Snapshot table (keys = bone names, values = bone matrices)
- flags: Status flag table (keys = bone names, values = bit flags)
Internal Logic: Iterates over bones in iterator order, caches matrices, and records error flags for non-existent bones or invalid matrices.
Use Case: Reduces redundant bone matrix retrieval overhead in the frame loop to improve performance.
```

### Bone Interpolation Related
![client](./materials/upgui/client.jpg)
**table, table** ent:UPMaLerpBoneBatch(**number** t, **table** snapshot, **entity/table** tarSnapshotOrEnt, **table** boneIterator)
```note
Batch executes linear bone posture interpolation, returning only interpolation results (no direct bone state changes) along with an interpolation snapshot and status flag table.
Parameter Descriptions:
- t: Interpolation factor (recommended 0-1; values outside this range cause over-interpolation)
- snapshot: Current entity's bone snapshot (optional; if not specified, bone matrices are retrieved directly from the entity)
- tarSnapshotOrEnt: Target entity or target bone snapshot
- boneIterator: Pre-initialized bone iterator (supports `UnpackMappingData` and `LerpRangeHandler` callbacks)
Return Values:
- lerpSnapshot: Interpolation snapshot (keys = bone names, values = {pos, ang, scale})
- flags: Status flag table (keys = bone names, values = bit flags)
Internal Logic:
1.  Automatically identifies root nodes and forces a switch to world-space interpolation
2.  Supports two interpolation modes: World-Space (`CALL_FLAG_LERP_WORLD`) and Local-Space (`CALL_FLAG_LERP_LOCAL`)
3.  First executes the `UnpackMappingData` callback to dynamically process bone configuration data
4.  Automatically applies bone offset matrices and processes custom parent configurations
5.  Executes the `LerpRangeHandler` callback to redirect/correct interpolation matrices
6.  Records error flags for failed interpolation and skips the current bone without affecting other bones
It is recommended to execute `ent:SetupBones()` and `targetEntity:SetupBones()` (when passing an entity) before calling.
```

### Error Handling Related
![client](./materials/upgui/client.jpg)
**void** ent:UPMaPrintErr(**int/table** runtimeflag, **string** boneName, **number** depth)
```note
Recursively prints error information from bone manipulation/interpolation, supporting both single bit flags and flag tables as input.
Parameter Descriptions:
- runtimeflag: Bit flag (number) or flag table (keys = bone names, values = bit flags)
- boneName: Bone name (only valid for single flags; optional)
- depth: Recursion depth (internal use; default 0, maximum 10)
Use Case: Output all exception information with one click during debugging to quickly locate issues (e.g., non-existent bones, singular matrices).
```

### Initialization Related
![client](./materials/upgui/client.jpg)
**void** UPManip.InitBoneIterator(**table** boneIterator)
```note
Validates the validity of the bone iterator and converts angle/position/scale offsets in the configuration into an offset matrix (`offset`).
Validation Rules:
1.  The bone iterator must be a table
2.  Iterator elements must be tables containing the `bone` field (string type)
3.  Offset configurations (`ang`/`pos`/`scale`) must be `angle`/`vector` types or `nil`
4.  Top-level callbacks (`UnpackMappingData`/`LerpRangeHandler`) must be `function` types or `nil`
5.  Other custom fields (`tarBone`/`parent`/`tarParent`/`lerpMethod`) must have valid types
Triggers an `assert` error for type mismatches to avoid runtime errors in advance.
Conversion Rule: Automatically merges `ang`, `pos`, and `scale` into an `offset` matrix for additional adjustments during interpolation.
```

## Global Constants and Tables
### 1. Bit Flag Message Table
```lua
UPManip.RUNTIME_FLAG_MSG -- Mapping table between bit flags and error descriptions (keys = bit flags, values = error messages)
```

### 2. Manipulation Flag Table
```lua
UPManip.MANIP_FLAG = {
    MANIP_POS = 0x01, -- Position-only manipulation
    MANIP_ANG = 0x02, -- Angle-only manipulation
    MANIP_SCALE = 0x04, -- Scale-only manipulation
    MANIP_POSITION = 0x03, -- Position + angle manipulation
    MANIP_MATRIX = 0x07, -- Position + angle + scale manipulation
}
```

### 3. Interpolation/Call Flags
```lua
-- Interpolation Types
CALL_FLAG_LERP_WORLD = 0x1000 -- World-Space Interpolation
CALL_FLAG_LERP_LOCAL = 0x2000 -- Local-Space Interpolation

-- Call Types
CALL_FLAG_SET_POSITION = 0x4000 -- Call UPMaSetBonePosition
CALL_FLAG_SNAPSHOT = 0x8000 -- Call UPMaSnapshot
CALL_FLAG_SET_POS = 0x20000 -- Call UPMaSetBonePos
CALL_FLAG_SET_ANG = 0x40000 -- Call UPMaSetBoneAng
CALL_FLAG_SET_SCALE = 0x80000 -- Call UPMaSetBoneScale

-- Error Types
ERR_FLAG_BONEID = 0x01 -- Bone does not exist
ERR_FLAG_MATRIX = 0x02 -- Bone matrix does not exist
ERR_FLAG_SINGULAR = 0x04 -- Singular matrix
-- Additional error flags are defined in the code
```

## Complete Workflow Example
```lua
-- 1. Create and initialize the bone iterator (with custom callbacks)
local boneIterator = {
    {
        bone = "ValveBiped.Bip01_Head1",
        lerpMethod = CALL_FLAG_LERP_WORLD
    },
    -- Dynamically modify bone configuration
    UnpackMappingData = function(self, t, snapshot, tarSnapshotOrEnt, mappingData)
        -- Dynamically adjust angle offset based on interpolation factor
        mappingData.ang = Angle(90 * t, 0, 0)
        return mappingData
    end,
    -- Redirect interpolation targets and limit rotation range
    LerpRangeHandler = function(self, t, snapshot, tarSnapshotOrEnt, initMatrix, finalMatrix, mappingData)
        local finalAng = finalMatrix:GetAngles()
        finalAng.p = math.Clamp(finalAng.p, -90, 90) -- Limit X-axis rotation
        finalMatrix:SetAngles(finalAng)
        return initMatrix, finalMatrix
    end
}
UPManip.InitBoneIterator(boneIterator)

-- 2. Obtain target entities
local ent = ClientsideModel("models/mossman.mdl", RENDERGROUP_OTHER)
local tarEnt = ClientsideModel("models/mossman.mdl", RENDERGROUP_OTHER)
ent:SetupBones()
tarEnt:SetupBones()

-- 3. Execute interpolation and manipulation in the frame loop
timer.Create("upmanip_demo", 0, 0, function()
    if not IsValid(ent) or not IsValid(tarEnt) then
        timer.Remove("upmanip_demo")
        return
    end

    -- 3.1 Update bone states
    ent:SetupBones()
    tarEnt:SetupBones()

    -- 3.2 Batch interpolation (automatically executes custom callbacks)
    local lerpSnapshot, lerpFlags = ent:UPMaLerpBoneBatch(0.1, nil, tarEnt, boneIterator)
    ent:UPMaPrintErr(lerpFlags) -- Print interpolation errors

    -- 3.3 Batch bone manipulation
    local manipFlags = ent:UPManipBoneBatch(lerpSnapshot, boneIterator, UPManip.MANIP_FLAG.MANIP_MATRIX)
    ent:UPMaPrintErr(manipFlags) -- Print manipulation errors
end)
```