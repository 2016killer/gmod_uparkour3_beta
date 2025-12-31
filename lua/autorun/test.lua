print('test')

// local FCVAR_FLAGS = {
//     [FCVAR_NONE] = "无任何标志位",
//     [FCVAR_UNREGISTERED] = "设置该标志后，该ConVar会变为匿名状态，不会出现在'find'指令的查询结果中",
//     [FCVAR_ARCHIVE] = "将ConVar的值保存到client.vdf或server.vdf中（Lua创建的ConVar除外，cvarlist中显示为\"a\"）",
//     [FCVAR_GAMEDLL] = "该ConVar由游戏DLL定义（此标志会自动设置，cvarlist中显示为\"sv\"）",
//     [FCVAR_CLIENTDLL] = "该ConVar由客户端DLL定义（此标志会自动设置，cvarlist中显示为\"cl\"）",
//     [FCVAR_PROTECTED] = "对所有客户端隐藏该ConVar的值（例如sv_password，cvarlist中显示为\"prot\"）",
//     [FCVAR_SPONLY] = "仅允许在单人模式下执行该指令或修改该ConVar的值（cvarlist中显示为\"sp\"）",
//     [FCVAR_NOTIFY] = "针对服务器端ConVar，其值变更时会以蓝色聊天文本通知所有玩家，且该ConVar会出现在A2S_RULES查询结果中（cvarlist中显示为\"nf\"）",
//     [FCVAR_USERINFO] = "针对客户端指令，会将其值发送到服务器（cvarlist中显示为\"user\"）",
//     [FCVAR_PRINTABLEONLY] = "强制该ConVar的值仅包含可打印字符（无控制字符，cvarlist中显示为\"print\"）",
//     [FCVAR_UNLOGGED] = "不将该ConVar的变更记录到控制台/日志文件/用户日志中（cvarlist中显示为\"log\"）",
//     [FCVAR_NEVER_AS_STRING] = "告知引擎永远不要将该变量以字符串形式打印（用于可能包含控制字符的变量，cvarlist中显示为\"numeric\"）",
//     [FCVAR_REPLICATED] = "针对服务器端ConVar，会将其值同步到所有客户端（客户端必须存在同名的ConVar，cvarlist中显示为\"rep\"）",
//     [FCVAR_CHEAT] = "需要启用sv_cheats才能修改该ConVar或执行该指令（cvarlist中显示为\"cheat\"）",
//     [FCVAR_DEMO] = "强制该ConVar的值被录制到演示录像（demo）中（cvarlist中显示为\"demo\"）",
//     [FCVAR_DONTRECORD] = "与FCVAR_DEMO相反，确保该ConVar的值不会被录制到演示录像（demo）中（cvarlist中显示为\"norecord\"）",
//     [FCVAR_LUA_CLIENT] = "自动应用于所有由客户端Lua环境创建的ConVar和控制台指令（cvarlist中显示为\"lua_client\"）",
//     [FCVAR_LUA_SERVER] = "自动应用于所有由服务器Lua环境创建的ConVar和控制台指令（cvarlist中显示为\"lua_server\"）",
//     [FCVAR_NOT_CONNECTED] = "连接到服务器或处于单人模式时，该ConVar的值不可修改",
//     [FCVAR_SERVER_CAN_EXECUTE] = "允许服务器在客户端上执行该指令（cvarlist中显示为\"server_can_execute\"）",
//     [FCVAR_SERVER_CANNOT_QUERY] = "阻止服务器查询该ConVar的值",
//     [FCVAR_ARCHIVE_XBOX] = "将ConVar的值保存到Xbox端的config.vdf中",
//     [FCVAR_CLIENTCMD_CAN_EXECUTE] = "允许IVEngineClient::ClientCmd执行该指令（cvarlist中显示为\"clientcmd_can_execute\"）"
// }

// local function CVarFlagsDesc(cvName)
//     local cv = GetConVar(cvName)
//     if not cv then
//         print('ConVar', cvName, '不存在')
//         return
//     end

//     local hasflag = false
//     for flag, desc in pairs(FCVAR_FLAGS) do
//         if bit.band(cv:GetFlags(), flag) ~= 0 then
//             print(flag, desc)
//             hasflag = true
//         end
//     end

//     if not hasflag then
//         print('ConVar', cvName, '没有任何标志位')
//     end
// end

// CVarFlagsDesc('upctrl_remove')