--[[
	作者:白狼
	2025 11 1
--]]

UPar.RegisterEffectEasy = function(actName, tarName, name, initData)
	assert(isstring(actName), string.format('actName "%s" is not string', actName))
	assert(isstring(tarName), string.format('tarName "%s" is not string', tarName))
	assert(isstring(name), string.format('name "%s" is not string', name))
	assert(tarName ~= name, string.format('effect name "%s" is same as target name "%s"', name, tarName))
	assert(istable(initData), string.format('initData "%s" is not table', initData))

	local targetEffect = UPar.GetEffect(actName, tarName)

	if not targetEffect then
		print(string.format('can not find effect named "%s" from act "%s"', tarName, actName))
		return
	end

	if not UPar.isupeffect(targetEffect) then
		print(string.format('effect named "%s" from act "%s" is not upeffect', tarName, actName))
		return
	end

	local effect = UPEffect:Register(
		actName, 
		name, 
		table.Merge(UPar.DeepClone(targetEffect), initData)
	)

	return effect
end

UPar.IsCustomEffect = function(custom) 
	if not istable(custom) then 
		return false 
	end

	return isstring(custom.Name) and isstring(custom.linkName) and isstring(custom.linkAct)
end

UPar.InitCustomEffect = function(custom)
	if not UPar.IsCustomEffect(custom) then 
		print(string.format('init custom effect failed, "%s" is not custom effect', istable(custom) and util.TableToJSON(custom, true) or custom))
		return false
	end

    local actName = custom.linkAct
    local tarName = custom.linkName

	local targetEffect = UPar.GetEffect(actName, tarName)
	if not targetEffect then
		print(string.format('init custom effect failed, can not find effect named "%s" from act "%s"', tarName, actName))
		return false
	end

	UPar.DeepInject(custom, UPar.DeepClone(targetEffect))

	return true
end

UPar.PushPlyEffCache = function(ply, custom)
	if not UPar.IsCustomEffect(custom) then 
		print(string.format('push eff cache failed, "%s" is not custom effect', istable(custom) and util.TableToJSON(custom, true) or custom))
		return false
	end

    ply.upeff_cache[custom.linkAct] = custom

	return true
end

UPar.PushPlyEffCfg = function(ply, actName, effName)
    if not isstring(actName) then
        print(string.format('push eff config failed, invalid actName "%s" (not string)', actName))
        return false
    end

    if not isstring(effName) then
        print(string.format('push eff config failed, invalid effName "%s" (not string)', effName))
		return false
    end

    ply.upeff_cfg[actName] = effName

	return true
end

UPar.InitPlyEffSetting = function(ply)
	ply.upeff_cfg = {}
	ply.upeff_cache = {}
end

UPar.PushPlyEffSetting = function(ply, cfg, cache)
	if istable(cfg) then
		for actName, effName in pairs(cfg) do
			if actName == 'AAAMetadata' then continue end
			UPar.PushPlyEffCfg(ply, actName, effName)
		end
		// PrintTable(cfg)
	end

	if istable(cache) then
		for actName, cache in pairs(cache) do
			if actName == 'AAAMetadata' then continue end
			UPar.InitCustomEffect(cache)
			UPar.PushPlyEffCache(ply, cache)
		end
		// PrintTable(cache)
	end
end
 

UPar.GetPlyEffCache = function(ply, actName)
	if not isstring(actName) then
		ErrorNoHaltWithStack(string.format('Invalid actName "%s" (not string)', actName))
		return nil
	end

	return ply.upeff_cache[actName]
end

UPar.GetPlyUsingEffName = function(ply, actName)
	if not isstring(actName) then
		ErrorNoHaltWithStack(string.format('Invalid actName "%s" (not string)', actName))
		return nil
	end

	return ply.upeff_cfg[actName] or 'default'
end

if SERVER then
	util.AddNetworkString('PushPlyEffSetting')

	net.Receive('PushPlyEffSetting', function(len, ply)
		local content = net.ReadString()
		// content = util.Decompress(content)

		local data = util.JSONToTable(content or '')
		if not istable(data) then
			print('[UPar]: receive data is not table')
			return
		end

		local cfg, cache = unpack(data)
		UPar.PushPlyEffSetting(ply, cfg, cache)
	end)

	hook.Add('PlayerInitialSpawn', 'upar.init.effect', UPar.InitPlyEffSetting)
elseif CLIENT then
	file.CreateDir('uparkour_effect')
	file.CreateDir('uparkour_effect/custom')

	UPar.SaveUserCustEffToDisk = function(custom, noMeta)
		if not UPar.IsCustomEffect(custom) then 
			ErrorNoHaltWithStack(string.format('save custom effect failed, "%s" is not custom effect', istable(custom) and util.TableToJSON(custom, true) or custom))
			return false
		end

		local dir = string.format('uparkour_effect/custom/%s', custom.linkAct)
		if not file.Exists(dir, 'DATA') then 
			file.CreateDir(dir) 
		end

		local path = string.format('uparkour_effect/custom/%s/%s.json', custom.linkAct, custom.Name)

		local dataOverride = hook.Run('UParSaveUserCustomEffectToDisk', custom)
		return UPar.SaveUserDataToDisk(dataOverride or custom, path, noMeta)
	end

	UPar.GetCustEffPath = function(actName, name)
		return string.format('uparkour_effect/custom/%s/%s.json', actName, name)
	end

	UPar.CreateUserCustEff = function(actName, tarName, name, noMeta)
		name = string.lower(name)
		local path = string.format('uparkour_effect/custom/%s/%s.json', actName, name)

		local custom = {
			Name = name,
			linkAct = actName,
			linkName = tarName,
			icon = 'icon64/tool.png',
			label = name,

			AAAACreat = LocalPlayer():Nick(),
			AAAContrib = '',
			AAADesc = '',
		}

		local succ = UPar.SaveUserCustEffToDisk(custom, noMeta)

		return custom, succ
	end

	UPar.DeleteUserCustEff = function(actName, name)
		local path = string.format('uparkour_effect/custom/%s/%s.json', actName, name)
		local succ = file.Delete(path)
		print(string.format('delete custom effect "%s", success: %s', path, succ))
		return succ
	end

	UPar.GetUserCustEffFiles = function(actName)
		local files = file.Find(string.format('uparkour_effect/custom/%s/*.json', actName), 'DATA')
		
		if istable(files) then
			for k, v in pairs(files) do
				files[k] = string.sub(v, 1, -6)
			end
		end
		
		return files, actName
	end

	UPar.LoadUserCustEffFromDisk = function(actName, name)
		local data = UPar.LoadUserDataFromDisk(string.format('uparkour_effect/custom/%s/%s.json', actName, name))
		local override = hook.Run('UParLoadUserCustomEffectFromDisk', data)
		return override or data
	end

	UPar.CallServerPushPlyEffSetting = function(cfg, cache)
		local data = {cfg, cache}

		if not istable(data[1]) then data[1] = false end
		if not istable(data[2]) then data[2] = false end

		-- 为了过滤掉一些不能序列化的数据
		local content = util.TableToJSON(data)
		if not content then
			print('[UPar]: push player effect failed, content is not valid json')
			return
		end
		// content = util.Compress(content)

		net.Start('PushPlyEffSetting')
			net.WriteString(content)
		net.SendToServer()
	end

	UPar.SaveUserEffCacheToDisk = function(data, noMeta)
		data = data or LocalPlayer().upeff_cache
		local override = hook.Run('UParSaveUserEffCacheToDisk', data)
		UPar.SaveUserDataToDisk(override or data, 'uparkour_effect/cache.json', noMeta)
	end

	UPar.SaveUserEffCfgToDisk = function(data, noMeta)
		data = data or LocalPlayer().upeff_cfg
		local override = hook.Run('UParSaveUserEffCfgToDisk', data)
		UPar.SaveUserDataToDisk(override or data, 'uparkour_effect/config.json', noMeta)
	end

	UPar.LoadUserEffCacheFromDisk = function()
		local data = UPar.LoadUserDataFromDisk('uparkour_effect/cache.json')
		local override = hook.Run('UParLoadUserEffCacheFromDisk', data)
		return override or data
	end

	UPar.LoadUserEffCfgFromDisk = function()
		local data = UPar.LoadUserDataFromDisk('uparkour_effect/config.json')
		local override = hook.Run('UParLoadUserEffCfgFromDisk', data)
		return override or data
	end

	hook.Add('KeyPress', 'upar.init.effect', function(ply, key)
		hook.Remove('KeyPress', 'upar.init.effect')
		UPar.InitPlyEffSetting(ply)
		
		local cfg = UPar.LoadUserEffCfgFromDisk()
		local cache = UPar.LoadUserEffCacheFromDisk()

		UPar.PushPlyEffSetting(ply, cfg, cache)
		UPar.CallServerPushPlyEffSetting(cfg, cache)
	end)
end


concommand.Add('up_debug_effsetting_' .. (SERVER and 'sv' or 'cl'), function()
	print('====================upeff_cache==================')
	PrintTable(LocalPlayer().upeff_cache)

	print('====================upeff_cfg====================')
	PrintTable(LocalPlayer().upeff_cfg)
end)
