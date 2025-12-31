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

# UPKeyboard - Keyboard Events
```note
Note: This is a test module and is not recommended for use in a production environment.
```


## Overview
Runs on the client-side and uses the Think hook to check the key state every 0.03 seconds.

It can handle simple key combinations but does not verify the order of key presses. For example, **W + A** is treated the same regardless of whether you press **A first then W** or **W first then A**.

## Available Methods

![client](./materials/upgui/client.jpg)
UPKeyboard.Register(**string** flag, **string** default, **string** label=flag)
```note
Registers a key binding. When the bound keys are pressed, the UParKeyPress hook will be triggered.
The registered key binding can be found in the Q menu.
```
```lua
-- W + Space
UPKeyboard.Register('example', '[33,65]')
```

## SeqHook
![client](./materials/upgui/client.jpg)
**@Name:** **UParKeyPress**  
**@Parameters:** eventflags **table**  
```note
This hook is triggered when one or more bound key groups are pressed, meaning all key press events are handled here.

eventflags is a table where the keys are the flags of the key groups, and the corresponding values are the handling flags.

Handling Flags:
UPKeyboard.KEY_EVENT_FLAGS.UNHANDLED
UPKeyboard.KEY_EVENT_FLAGS.HANDLED
UPKeyboard.KEY_EVENT_FLAGS.SKIPPED

These flags have no functional impact and are only used for coordination between developers.
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
**@Name:** **UParKeyRelease**  
**@Parameters:** eventflags **table**  
```
Identical to the UParKeyPress hook, but triggered when the bound keys are released.
```