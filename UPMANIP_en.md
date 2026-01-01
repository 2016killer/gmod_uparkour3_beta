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

# UPManip - Bone Manipulation

example command `upmanip_test`

```note
Note: This is a test module and is not recommended for use in a production environment.

These are all very difficult to use. They are simply a pile of crap.

The usage threshold of this method is extremely high. Firstly, ManipulateBonePosition has a distance limit, which is set at 128 units.
Therefore, if one wants to achieve correct interpolation, it is necessary to do so at the frame where the position update is completed.
So, to achieve correct interpolation, it is best to add an additional flag + callback to handle it. This way, it is less likely to cause confusion.

Interpolation requires specifying the bone mapping and its order. The function GetEntBonesFamilyLevel(ent, useLRU2) can assist in sorting. After the process is completed, manual coding is required.

Since these functions are often used in frame loops and are somewhat computationally intensive, many errors are silent — which greatly increases debugging difficulty. fuck, it's a bit like GPU programming, so I don't recommend using them.

I decided to add a "silentlog" parameter at the end of some functions, which is used to control whether to print logs. This will make debugging much more convenient.
```


## Overview
The `upmanip_test` console command can be used to test the functionality of UPManip.

This is a **client-side only** API that provides direct control over bones via methods such as **ent:ManipulateBonexxx**.

### Advantages:
1. Directly manipulates bones without the need for methods like **ent:AddEffects(EF_BONEMERGE)**, **BuildBonePositions**, or **ResetSequence**.
2. Compared to **VMLeg**, it supports fade-out animations, and no snapshots are required for these fade-out animations.

### Disadvantages:
1. High computational overhead, as several matrix operations need to be performed via **Lua** each time.
2. Requires per-frame updates.
3. Cannot handle singular matrices, which typically occur when a bone's scale is set to 0.
4. May conflict with other methods that use **ent:ManipulateBonexxx**, resulting in abnormal animations.

## Available Methods

![client](./materials/upgui/client.jpg)
**vec, ang** UPManip.SetBonePosition(**entity** ent, **int** boneId, **vector** posw, **angle** angw, **bool** silentlog)
```note
Controls the position and angle of the specified bone of the target entity.
The new position cannot be too far from the old position (128 units maximum).
It is recommended to call ent:SetupBones() before using this function, as the current bone matrix is required for calculations.

This is already the most convenient one. The others are just a bunch of feces.
```