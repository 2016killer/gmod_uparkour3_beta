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

## Introduction

### Example
Use the command `developer 1;up_reload_sv;up_reload_cl` to load examples.  
Sample code can be found in all Lua files containing the keyword "test".

### Consensus
```note
For UPAction and UPEffect, we should treat them as static containers and must not store any runtime results in them.

The lifecycle synchronization of UPAction and UPEffect is always one-time-only. Since the synchronized data is a table, developers can add custom markers and send it independently if multiple synchronizations are required.

It is not supported to operate the track in Start or Clear. This may cause confusion in the lifecycle, as they usually run within the net.Start context, which is read-only. One can operate the track either in the next frame using a timer or in act's Think.
```

### Data Security
```note
To save development time and due to my limited understanding of Lua and framework design, I have not added protection to tables. Therefore, all tables in hooks can be directly manipulated—this provides convenience but also poses potential security risks. Exercise caution when operating on tables, or you can add protection to output tables as needed.

The best practice is to avoid initializing or manipulating context-dependent data in Start and Clear to ensure safety under extreme conditions.
```

### Changes
```note
Regarding the implementation of interrupts and similar features, **sequence hooks are now used instead**.
If the action *"test_lifecycle"* is running in a track **and you trigger an interrupt**, the sequences *"UParUParActAllowInterrupt_test_lifecycle"* and *"UParUParActInterrupt"* will be executed.
All other extensible features follow this same pattern.

1. Add support for **custom panels in the Action Editor**.
2. **Refactor the lifecycle**: remove most rarely used parameters, and enable **multi-track parallel execution of actions**.
3. Add new **FrameLoop support**.
4. Add the new **UPManip API** for direct bone manipulation (note: this has relatively high computational overhead).
5. Add new **key binding and event support**.
6. Enable the creation of **more custom special effects**.
```

### Contributors

Name: 22050hz amen break sample  
Link: https://steamcommunity.com/id/laboratorymember001  
Contribution: **Mighty Foot Engaged** animation  
(Maybe him? I’m not sure — the original plugin has been hidden, so I can’t trace it back.)

Name: Bai Lang  
Link: https://steamcommunity.com/id/whitewolfking/  
Contribution: Most of the code and Chinese documentation

Name: YuRaNnNzZZ
Link: https://steamcommunity.com/id/yurannnzzz
Contribution: hm500 animation

Name: Miss Dou  
Link: Doubao AI  
Contribution: Part of the code and English documentation


- Author: 白狼 2322012547@qq.com
- Translator: Miss DouBao
- Date: December 10, 2025
- Version: 3.0.0 Beta