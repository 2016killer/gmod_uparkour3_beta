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

# LRU
```note
There are three LRU caches in total, with almost identical method names—the only difference is the added identifiers.
For example: LRUSet, LRU2Set, LRU3Set.
The default size of all three LRU caches is 30. The first LRU cache on the client side is already occupied by panel data, so its use should be avoided as much as possible.
```

![shared](./materials/upgui/shared.jpg)
**any** UPar.LRUGet(**string** key)

![shared](./materials/upgui/shared.jpg)
**any** UPar.LRUSet(**string** key, **any** val)

![shared](./materials/upgui/shared.jpg)
**any** UPar.LRUGetOrSet(**string** key, **any** default)

![shared](./materials/upgui/shared.jpg)
UPar.LRUDelete(**string** key)