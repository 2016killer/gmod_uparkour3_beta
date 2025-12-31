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

## Custom Effects

The key difference between custom effects and **UPEffect** is the addition of two keys: **linkName** and **linkAct**. Both keys are of **string** type, corresponding to the names of a specific **UPEffect** and a specific **UPAction** respectively.

## Working Principle

### Saving
Path: /data/uparkour_effects/custom/**%linkAct%**/**%name%**.json  

Data is serialized using `util.TableToJSON`.  
Data after saving will lose internal reference relationships. For effects that rely on this mechanism, it is not recommended to create custom effects.  
Alternatively, use the hooks **UParLoadUserCustomEffectFromDisk** and **UParSaveUserCustomEffectToDisk** for loading and saving operations.

### Initialization
Initialization is triggered every time data is saved. Internally, **UPar.DeepClone** is used for deep copy—unlike the original deep copy method `table.Copy`, which does not support userdata types such as `vector`, `angle`, and `matrix`.  

Subsequently, **UPar.DeepInject** is used to populate custom objects (e.g., non-serializable types like **function**).