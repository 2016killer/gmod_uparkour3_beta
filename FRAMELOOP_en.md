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


# FrameLoop 

## 1. Push FrameLoop
**boolean** UPar.PushFrameLoop(**any** identity, **function** iterator, **any** addition, **number** timeout, **function** clear=nil, **string** hookName="Think")
```note
Used to push a new frameloop into the frameloop manager. If an frameloop with the specified identity already exists, it will first trigger the UParPopFrameLoop hook for the old frameloop (marked with reason "OVERRIDE") and override the old frameloop. Uses the Think frame loop hook by default, automatically starts the corresponding frame loop listening logic, and the timeout must be a value greater than 0.
```

## 2. Pop FrameLoop
**boolean** UPar.PopFrameLoop(**any** identity, **boolean** silent=false)
```note
Used to manually remove the frameloop with the specified identity. Before removal, it will first execute the frameloop's clear callback function (if it exists). In non-silent mode (silent=false), it will trigger the UParPopFrameLoop hook (marked with reason "MANUAL"). Returns false if the frameloop does not exist.
```

## 3. Get FrameLoop Data
**table** UPar.GetFrameLoop(**any** identity)
```note
Used to retrieve the complete stored data of the frameloop with the specified identity. The returned table includes fields: f (frameloop function), et (absolute timeout time), add (additional data), clear (cleanup callback), hn (bound hook name), and pt (pause time, optional). Returns nil if the frameloop does not exist.
```

## 4. Check FrameLoop Existence
**boolean** UPar.IsFrameLoopExist(**any** identity)
```note
Used to quickly check if the frameloop with the specified identity exists in the frameloop manager. Returns true if it exists, false otherwise.
```

## 5. Pause FrameLoop
**boolean** UPar.PauseFrameLoop(**any** identity, **boolean** silent=false)
```note
Used to pause the frameloop with the specified identity. Paused frameloop will not execute logic in the frame loop, and the pause time will be recorded. In non-silent mode (silent=false), it will trigger the UParPauseFrameLoop hook. Returns false if the frameloop does not exist.
```

## 6. Resume FrameLoop
**boolean** UPar.ResumeFrameLoop(**any** identity, **boolean** silent=false)
```note
Used to resume the paused frameloop with the specified identity. It will automatically compensate for the pause duration (update the frameloop's absolute timeout time) and restart the corresponding frame loop listening. In non-silent mode (silent=false), it will trigger the UParResumeFrameLoop hook. Returns false if the frameloop does not exist or is not in a paused state.
```

## 7. Set Nested KV in FrameLoop Additional Data
**boolean** UPar.SetFrameLoopAddiKV(**any** identity, **any** ...)
```note
Used to set multi-level nested key-value pairs in the frameloop's additional data. At least 2 parameters are required (supports multi-level table indexing; the last two parameters are the target key and corresponding value respectively). Returns false if the frameloop does not exist or the nested table path is invalid.
```

## 8. Get Nested KV from FrameLoop Additional Data
**any** UPar.GetFrameLoopAddiKV(**any** identity, **any** ...)
```note
Used to retrieve multi-level nested key-value pairs from the frameloop's additional data. At least 2 parameters are required (supports multi-level table indexing; the last parameter is the target key). Returns nil if the frameloop does not exist or the nested table path is invalid.
```

## 9. Set FrameLoop Timeout Time
**boolean** UPar.SetFrameLoopEndTime(**any** identity, **number** endTime, **boolean** silent=false)
```note
Used to modify the absolute timeout time of the frameloop with the specified identity (endTime must be a numeric absolute time, not a relative duration). In non-silent mode (silent=false), it will trigger the UParFrameLoopEndTimeChanged hook. Returns false if the frameloop does not exist.
```

## 10. Merge FrameLoop Additional Data
**boolean** UPar.MergeFrameLoopAddiKV(**any** identity, **table** data)
```note
Used to merge the frameloop's additional data, implemented based on the GLua table.Merge method (shallow merge: only merges top-level key-value pairs, no recursive merging for deep tables). Returns false if the frameloop does not exist or the incoming merge data is not a table.
```