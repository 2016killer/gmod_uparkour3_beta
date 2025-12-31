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


## 简介

```
由于提交记录过于臃肿, 所以此仓库弃用, 后续所有更新都将在新仓库进行。
```


### 示例
使用指令 `developer 1;up_reload_sv;up_reload_cl` 来加载示例。
可以在所有带有 test 的 lua 文件中找到示例代码。

### 共识
```note
对于 UPAction 和 UPEffect, 我们应当将他们视为静态容器, 不应该将任何运行的结果存储在他们的中。

UPAction 、 UPEffect 生命周期的同步永远是一次性的。 因为同步的数据是表, 如果需要多次同步, 可以自行标记并发送。

并不支持在 Start 或Clear 中操作轨道, 这可能导致生命周期混乱, 因为他们通常在 net.Start 上下文中运行, 而那是只读的, 可以使用定时器在下一帧操作轨道 或在 Think 中操作。
```

### 数据安全
```note
为了节省开发时间以及本人对lua和框架设计的理解有限, 我并没有对表加入保护, 所以hook中的所有表都是可以直接操作的, 这提供了便利也造成一些安全隐患, 操作表的时候需要小心, 你也可以按需为输出的表加入保护。

最好的方法是不要放入在Start和Clear初始化或操作有上下文依赖的数据以确保在极端情况下的安全。
```
### 变化
```note
关于中断等的写法, 现在改用序列钩子的写法, 如果动作"test_lifecycle"在轨道中运行, 同时你触发了动作, 则会运行序列"UParUParActAllowInterrupt_test_lifecycle" 和 "UParUParActInterrupt", 其他所有可以拓展的都按照此规律。

1. 增加动作编辑器自定义面板支持。
2. 重构生命周期, 删去大部分小概率用到的参数, 动作可以多轨道并行。
3. 新增帧循环支持。
4. 新增 UPManip API, 可以直接操纵骨骼, 但运算量较大。
5. 新增按键绑定与事件支持。
6. 可以创建更多的自定义特效
```

### 贡献者

名字: 22050hz amen break sample  
链接: https://steamcommunity.com/id/laboratorymember001  
贡献: **mighty foot engaged** 动画  
(可能是他? 我不知道, 因为原插件被隐藏了, 所以我无法追溯)

名字: 白狼
链接: https://steamcommunity.com/id/whitewolfking/
贡献: 大部分代码以及中文文档

名字: 豆小姐
链接: 豆包AI
贡献: 部分代码以及英文文档


- 作者：白狼 2322012547@qq.com
- 翻译: 豆小姐
- 日期：2025 12 10
- 版本: 3.0.0 Alpha
