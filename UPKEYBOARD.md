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

# UPKeyboard 键盘事件
```note
注意: 这是一个测试性模块, 不建议在生产环境中使用。
```


## 简介
在客户端运行, 使用 Think 钩子每隔 0.03 秒检查一次按键状态。

它可以处理简单的组合按键, 但是并没有对按键的顺序进行检查, 例如 **W + A**, **先按 A 再按 W** 和 **先按 W 再按 A** 是一样的。



## 可用方法

![client](./materials/upgui/client.jpg)
UPKeyboard.Register(**string** flag, **string** default, **string** label=flag)
```note
注册一个按键绑定, 当按键被按下时, 会触发 UParKeyPress 钩子。
注册后能在 Q 菜单找到。
```
```lua
-- W + Space
UPKeyboard.Register('example', '[33,65]')
```

## SeqHook
![client](./materials/upgui/client.jpg)
**@名字:** **UParKeyPress**  
**@参数:** eventflags **table**  
```note
一个或多个被按下时会触发此钩子, 也就是说所有按下事件都在这里处理。

eventflags 是一个表, 按键组的标志作为键, 处理标志作为值。

处理标志:
UPKeyboard.KEY_EVENT_FLAGS.UNHANDLED
UPKeyboard.KEY_EVENT_FLAGS.HANDLED
UPKeyboard.KEY_EVENT_FLAGS.SKIPPED

这些标记毫无用处, 仅用于协调开发者之间的处理。
```
```lua
local VAULTDL_FLAG = 0x01
local LOW_CLIMB_FLAG = 0x02
local VAULTDH_FLAG = 0x04
local HIGH_CLIMB_FLAG = 0x08

UPar.SeqHookAdd('UParKeyPress', 'upctrl', function(eventflags)
  local actFlag = 0
  actFlag = bit.bor(actFlag, eventflags['upctrl_lowclimb'] and LOW_CLIMB_FLAG or 0)
  actFlag = bit.bor(actFlag, eventflags['upctrl_highclimb'] and HIGH_CLIMB_FLAG or 0)
  actFlag = bit.bor(actFlag, eventflags['upctrl_vaultdl'] and VAULTDL_FLAG or 0)
  actFlag = bit.bor(actFlag, eventflags['upctrl_vaultdh'] and VAULTDH_FLAG or 0)

  if actFlag == 0 then
    return
  end

  RunConsoleCommand('upctrl_add_sv', actFlag)

  eventflags['upctrl_lowclimb'] = FLAGS_HANDLED
  eventflags['upctrl_highclimb'] = FLAGS_HANDLED
  eventflags['upctrl_vaultdl'] = FLAGS_HANDLED
  eventflags['upctrl_vaultdh'] = FLAGS_HANDLED
end)
```


![client](./materials/upgui/client.jpg)
**@名字:** **UParKeyRelease**  
**@参数:** eventflags **table**  
```
和 UParKeyPress 钩子一样, 但是是在按键被释放时触发。
```