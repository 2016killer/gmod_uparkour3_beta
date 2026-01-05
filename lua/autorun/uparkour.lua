--[[
	作者:白狼
	2025 12 09

	不再使用UltiPar来管理所有的方法, 因为这会导致代码十分混乱、难以维护
    对于Action、 Effect, 使用UPAction、UPEffect类而不是直接使用表
	
	UPar表的功能将集中在最基础的一些方法, 例如翻译、打印数据、调试框、通用检测等

	/class/*.lua: 类(包括控件)的定义
	/core/*.lua: UPar核心方法
	/actions/*.lua: UPAction实例
	/effects/*.lua: UPEffect实例
	/effectseasy/*.lua: UPEffect实例的简单拓展
	/gui/*.lua: 控件的实现(q菜单等)

	文档:
		https://github.com/2016killer/gmod_uparkour3/blob/main/README.md
		https://github.com/2016killer/gmod_uparkour3/blob/main/README_en.md

--]]

UPar = UPar or {}
UPar.Version = '3.0.0 alpha'

UPar.emptyfunc = function() end
UPar.anypass = setmetatable({}, {__index = function() return true end})
UPar.emptyTable = setmetatable({}, {
	__index = UPar.emptyfunc,
    __newindex = function()
        error('UPar.emptyTable is readonly table, can not write')
    end
})
UPar.zerovec = Vector(0, 0, 0)
UPar.zeroang = Angle(0, 0, 0)
UPar.unitxvec = Vector(1, 0, 0)
UPar.unityvec = Vector(0, 1, 0)
UPar.unitzvec = Vector(0, 0, 1)
UPar.diagonalvec = Vector(1, 1, 1)

UPar.IsInstance = function(obj, class)
	-- 仅对静态类有效
    if not istable(obj) or not istable(class) then
        return false
    end

	local cached = {[obj] = true}
    local curMt = getmetatable(obj)

    while istable(curMt) do
		if cached[curMt] then
			return false
		end
		cached[curMt] = true

        if curMt.__index == class then
            return true
        end

        curMt = getmetatable(curMt.__index)
    end

    return false
end

if CLIENT then
	UPar.SnakeTranslate = function(key, prefix, sep, joint)
		-- 在树编辑器中所有的键名使用此翻译, 分隔符采用 '_'
		-- 'vec_punch' --> '#upgui.vec' + '.' + '#upgui.punch'
		local dev = GetConVar('developer')
		if dev and dev:GetBool() then 
			return key
		end

		prefix = prefix or 'upgui'
		sep = sep or '_'
		joint = joint or '.'

		local split = string.Split(key, sep)
		
		for i, v in ipairs(split) do
			split[i] = language.GetPhrase(string.format('#%s.%s', prefix, v))
		end

		return table.concat(split, joint, 1, #split)
	end

	UPar.SnakeTranslate_2 = function(key, prefix, sep, joint)
		prefix = prefix or 'upgui'
		sep = sep or '_'
		joint = joint or '.'

		local split = string.Split(key, sep)
		
		for i, v in ipairs(split) do
			split[i] = language.GetPhrase(string.format('#%s.%s', prefix, v))
		end

		return table.concat(split, joint, 1, #split)
	end

	UPar.GetConVarPhrase = function(name)
		-- 替换第一个下划线为点号
		local start, ending, phrase = string.find(name, "_", 1)

		if start == nil then
			return name
		else
			return '#' .. name:sub(1, start - 1) .. '.' .. name:sub(ending + 1)
		end
	end
end

UPar.debugwireframebox = function(pos, mins, maxs, lifetime, color, ignoreZ)
	if not GetConVar('developer') or not GetConVar('developer'):GetBool() then
		return
	end

	lifetime = lifetime or 1
	color = color or Color(255, 255, 255)
	ignoreZ = ignoreZ or false

	local ref = mins + pos

	local temp = maxs - mins
	local axes = {Vector(0, 0, temp.z), Vector(0, temp.y, 0), Vector(temp.x, 0, 0)}

	for i = 1, 3 do
		for j = 0, 3 do
			local pos1 = ref
			if bit.band(j, 0x01) ~= 0 then pos1 = pos1 + axes[1] end
			if bit.band(j, 0x02) ~= 0 then pos1 = pos1 + axes[2] end

			debugoverlay.Line(pos1, pos1 + axes[3], lifetime, color, ignoreZ)
		end
		axes[i], axes[3] = axes[3], axes[i]
	end
end

UPar.printinputs = function(flag, ...)
	local total = select('#', ...)
	local inputs = {...}

	print(string.format('==========%s==========', flag))
	print('total', total)
	for i = 1, total do
		local v = inputs[i]
		print(string.format('%s: %s', i, v))
		if istable(v) then PrintTable(v) end
	end
end

if CLIENT then
	UPar.LoadUserDataFromDisk = function(path)
		-- 从磁盘加载用户数据, 返回 表 或 nil
		local content = file.Read(path, 'DATA')
		local data = util.JSONToTable(content or '')
		data = istable(data) and data or nil

		if data == nil then
			print(string.format('[UPar]: try load user data from disk %s, failed', path))
		else
			print(string.format('[UPar]: try load user data from disk %s, success', path))
		end
		
		return data
	end

	UPar.SaveUserDataToDisk = function(data, path, noMetadata)
		-- 保存用户数据到磁盘, 返回 是否成功
		-- 此操作会自动添加元数据 AAAMetadata

		if not istable(data) then
			ErrorNoHaltWithStack('data must be a table, but got ', type(data))
			return
		end

		if noMetadata then
			data.AAAMetadata = nil
		else
			data.AAAMetadata = {
				version = UPar.Version,
				date = os.date('%Y-%m-%d %H:%M:%S'),
			}
		end

		local content = util.TableToJSON(data, true) or '{}'
		local succ = file.Write(path, content)
		if succ then
			print(string.format('[UPar]: save user data to disk %s, success', path))	
		else
			ErrorNoHaltWithStack('save user data to disk ', path, ' failed')
		end
		
		return succ
	end
end

local function DeepClone(obj, cache)
    cache = cache or {}

    if cache[obj] then
        return cache[obj]
    end

    -- userdata
    if isvector(obj) then
        local cloned = Vector(obj)
        cache[obj] = cloned
        return cloned
    elseif isangle(obj) then
        local cloned = Angle(obj)
        cache[obj] = cloned
        return cloned
    elseif ismatrix(obj) then
        local cloned = Matrix(obj)
        cache[obj] = cloned
        return cloned
    elseif IsColor(obj) then
        local cloned = Color(obj.r, obj.g, obj.b, obj.a)
        cache[obj] = cloned
        return cloned
	elseif not istable(obj) then
        return obj
    end


	local cloned = {}
	cache[obj] = cloned


	for k, v in pairs(obj) do
		cloned[DeepClone(k, cache)] = DeepClone(v, cache)
	end

	local mt = getmetatable(obj)
	if mt then
		setmetatable(cloned, mt)
	end

	return cloned
end

local function DeepInject(container, injector, cache)
    if not istable(container) then
        error(string.format('DeepInject: container must be a table, got %s', type(container)))
    end

    if not istable(injector) then
        error(string.format('DeepInject: injector must be a table, got %s', type(injector)))
    end

    cache = cache or {}
    local cacheKey = tostring(container) .. '|' .. tostring(injector)
    if cache[cacheKey] then
        return container
    end
    cache[cacheKey] = true

    for k, v in pairs(injector) do
        if container[k] == nil then
            container[k] = v
        elseif istable(container[k]) and istable(v) then
            DeepInject(container[k], v, cache)
        end
    end

    local mtContainer = getmetatable(container)
    local mtInjector = getmetatable(injector)
    if not mtContainer and mtInjector then
        setmetatable(container, mtInjector)
    end

    return container
end

local function generateRandHex()
	return string.format('%x', math.random(0,15))
end

UPar.MiniUUID = function()
    return string.gsub('xxxxxxxxxxxxxxxx', 'x', generateRandHex)
end

UPar.DeepClone = DeepClone
UPar.DeepInject = DeepInject

local function ReloadAll(ply)
	if SERVER and ply and not (isentity(ply) and IsValid(ply) and ply:IsPlayer() and ply:IsSuperAdmin()) then
		PrintMessage(HUD_PRINTTALK, 'You are not super admin, can not reload all lua files')
		return
	end

	local function tempInclude(subDir)
		local dir = string.format('uparkour/%s/', subDir)
		local files = file.Find(dir .. '*.lua', 'LUA')

		
		for _, filename in pairs(files) do
			local luaFile = dir .. filename
			include(luaFile)
			print('[UPar]: Include: ' .. luaFile)
		end
	end

	local function tempAddCSLuaFile(subDir)
		if CLIENT then return end
		local dir = string.format('uparkour/%s/', subDir)
		local files = file.Find(dir .. '*.lua', 'LUA')

		
		for _, filename in pairs(files) do
			local luaFile = dir .. filename
			AddCSLuaFile(luaFile)
			print('[UPar]: AddCSLuaFile: ' .. luaFile)
		end
	end

	local function tempHandle(tarDir, side)
		if SERVER and side == 'SERVER' then
			tempInclude(tarDir)
			tempInclude(tarDir .. '/server')
		elseif SERVER and side == 'SHARED' then
			tempInclude(tarDir)
			tempInclude(tarDir .. '/server')
			tempAddCSLuaFile(tarDir)
			tempAddCSLuaFile(tarDir .. '/client')
		elseif SERVER and side == 'CLIENT' then
			tempAddCSLuaFile(tarDir)
			tempAddCSLuaFile(tarDir .. '/client')
		elseif CLIENT and (side == 'CLIENT' or side == 'SHARED') then
			tempInclude(tarDir)
			tempInclude(tarDir .. '/client')
		end
	end

	tempHandle('class', 'SHARED')
	tempHandle('core', 'SHARED')
	tempHandle('extend', 'SHARED')
	tempHandle('actions', 'SHARED')
	tempHandle('effects', 'SHARED')
	tempHandle('effectseasy', 'SHARED')
	tempHandle('widget', 'CLIENT')
	tempHandle('gui', 'CLIENT')
	tempHandle('version_compat', 'SHARED')
	UPar.SeqHookRunAllSafe('UParVersionCompat', UPar.Version)

end

local function Debug(ply, cmd, args)
	if SERVER and not ply:IsAdmin() then
		PrintMessage(HUD_PRINTTALK, 'Only super admin can use this command')
		return
	end
	
	local target = _G
	local total = #args
	local lastKey = args[total] or 'UPar'

	for i = 1, total - 1 do
		local key = args[i]
		target = target[key]
		if not istable(target) then
			return 
		end
	end
	target = target[lastKey]
	
	print(target)
	if istable(target) then PrintTable(target) end
end

concommand.Add('up_reload_' .. (SERVER and 'sv' or 'cl'), ReloadAll)
concommand.Add('up_debug_' .. (SERVER and 'sv' or 'cl'), Debug)

ReloadAll()
AddCSLuaFile()

ReloadAll = nil
Debug = nil

timer.Simple(3, function() hook.Run('UParkourInitialized') end)
