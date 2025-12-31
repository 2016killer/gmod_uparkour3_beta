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

# LRU
```note
总共有三个LRU, 其方法名几乎相同, 区别在于加了标识符
例如: LRUSet, LRU2Set, LRU3Set
三个LRU默认大小为30, 客户端的第一个LRU已经被面板数据占用, 尽量避免使用。
```

![shared](./materials/upgui/shared.jpg)
**any** UPar.LRUGet(**string** key)

![shared](./materials/upgui/shared.jpg)
**any** UPar.LRUSet(**string** key, **any** val)

![shared](./materials/upgui/shared.jpg)
**any** UPar.LRUGetOrSet(**string** key, **any** default)

![shared](./materials/upgui/shared.jpg)
UPar.LRUDelete(**string** key)