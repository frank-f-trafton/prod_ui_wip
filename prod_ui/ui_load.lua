local uiLoad = {}


-- To toggle debug printing, add or remove the spaces between `--` and `[[DBG]]`.


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local uiRes = require(REQ_PATH .. "ui_res")
local uiShared = require(REQ_PATH .. "ui_shared")


local _mt_cache = {}
_mt_cache.__index = _mt_cache


local function checkArrayOfStrings(arr)
	for i, str in ipairs(arr) do
		if type(str) ~= "string" then
			return i
		end
	end

	return true
end


local function checkFile(path, file_types)
	-- [[DBG]] print("checkFile: start")
	local info = love.filesystem.getInfo(path)

	if not info then
		-- [[DBG]] print("checkFile: not found: " .. tostring(path))
		return false

	elseif file_types and not file_types[info.type] then
		-- [[DBG]] print("checkFile: info.type (" .. info.type .. ") not in FileTypes filter: " .. tostring(path))
		return false

	elseif not file_types and info.type ~= "file" then
		-- [[DBG]] print("checkFile: not a file (no FileTypes filter): " .. tostring(path))
		return false

	else
		-- [[DBG]] print("checkFile: found: " .. tostring(path))
		return info
	end
end


local function errLoadFailed(self, id)
	error("unable to load " .. self.msg_label .. " with ID: " .. tostring(id), 2)
end


local function loadAttachAndReturn(self, id, file_path)
	-- [[DBG]] print("loadAttachAndReturn: loading: " .. tostring(file_path))
	local result = self.loader(file_path, self.owner)

	-- On success, the loader should return a truthful value. On failure, it can raise a Lua
	-- error with more information.
	if not result then
		error("invalid return value (false/nil) from loader.")
	end
	self.loaded[id] = result

	-- [[DBG]] print("loadAttachAndReturn: done.")
	return result
end


local function fetch(self, id)
	-- [[DBG]] print("fetch(): No prefix paths. No extensions.")
	if not checkFile(id, self.file_types) then
		if self.fallback_id and id ~= self.fallback_id then
			return self:get(self.fallback_id)
		else
			errLoadFailed(self, id)
		end
	end

	return loadAttachAndReturn(self, id, id)
end


local function fetchExt(self, id)
	-- [[DBG]] print("fetchExt(): No prefix paths. Extensions.")
	for i, extension in ipairs(self.extensions) do
		local file_path = id .. "." .. extension
		if checkFile(file_path, self.file_types) then
			return loadAttachAndReturn(self, id, file_path)
		end
	end

	if self.fallback_id and id ~= self.fallback_id then
		return self:get(self.fallback_id)
	else
		errLoadFailed(self, id)
	end
end


local function fetchPre(self, id)
	-- [[DBG]] print("fetchPre(): Prefix paths. No extensions.")
	for i, path in ipairs(self.paths) do
		local file_path = uiRes.join(path, id)
		if checkFile(file_path, self.file_types) then
			return loadAttachAndReturn(self, id, file_path)
		end
	end

	if self.fallback_id and id ~= self.fallback_id then
		return self:get(self.fallback_id)
	else
		errLoadFailed(self, id)
	end
end


local function fetchPreExt(self, id)
	-- [[DBG]] print("fetchPreExt(): Prefix Paths. Extensions.")
	for i, path in ipairs(self.paths) do
		for j, extension in ipairs(self.extensions) do
			local file_path = uiRes.join(path, id .. "." .. extension)
			if checkFile(file_path, self.file_types) then
				return loadAttachAndReturn(self, id, file_path)
			end
		end
	end

	if self.fallback_id and id ~= self.fallback_id then
		return self:get(self.fallback_id)
	else
		errLoadFailed(self, id)
	end
end


function uiLoad.new(loader, opts)
	uiShared.type1(1, loader, "function")
	local paths, extensions, file_types, msg_label, fallback_id, unloader, flag_failed, owner
	if opts then
		paths = opts.paths
		extensions = opts.extensions
		file_types = opts.file_types
		msg_label = opts.msg_label
		fallback_id = opts.fallback_id
		unloader = opts.unloader
		flag_failed = opts.flag_failed
		owner = opts.owner

		uiShared.fieldTypeEval1(2, opts, "paths", "table")
		uiShared.fieldTypeEval1(2, opts, "extensions", "table")
		uiShared.fieldTypeEval1(2, opts, "file_types", "table")
		uiShared.fieldTypeEval1(2, opts, "msg_label", "string")
		uiShared.fieldTypeEval1(2, opts, "fallback_id", "string")
		uiShared.fieldTypeEval1(2, opts, "unloader", "function")
		uiShared.fieldTypeEval1(2, opts, "owner", "table")
	end

	-- Check that all array entries are strings.
	local check_array
	if paths then
		for i in ipairs(paths) do
			uiShared.fieldType1(2, paths, i, "string")
		end
	end
	if extensions then
		for i in ipairs(extensions) do
			uiShared.fieldType1(2, extensions, i, "string")
		end
	end

	local self = setmetatable({}, _mt_cache)

	self.paths = paths
	self.extensions = extensions
	self.file_types = file_types
	self.loader = loader
	self.unloader = unloader
	self.msg_label = msg_label or "resource"
	self.fallback_id = fallback_id
	self.flag_failed = flag_failed
	self.owner = owner

	local fetcher
	if self.paths then
		fetcher = self.extensions and fetchPreExt or fetchPre
	else
		fetcher = self.extensions and fetchExt or fetch
	end

	-- self:_fetch(id)
	self._fetch = fetcher

	self.loaded = {}

	return self
end


function _mt_cache:get(id)
	uiShared.type1(1, id, "string")

	-- [[DBG]] print("cache:get(): start: " .. tostring(id))

	-- Already loaded.
	local resource = self.loaded[id]
	if resource then
		-- [[DBG]] print("cache:get(): already loaded.")
		return resource
	end

	-- Not loaded. Fetch from file system.
	return self:_fetch(id)
end


function _mt_cache:try(id)
	uiShared.type1(1, id, "string")

	-- [[DBG]] print("cache:try(): start: " .. tostring(id))

	-- Already loaded.
	local resource = self.loaded[id]
	if resource then
		-- [[DBG]] print("cache:try(): already loaded.")
		return resource
	end

	-- Marked as failed from a previous load attempt.
	if self.flag_failed and resource == false then
		-- [[DBG]] print("cache:try(): ID is already flagged as failed: " .. tostring(id))
		return false, "previous load attempt failed."
	end

	-- Not loaded. Try fetching from file system.
	local ok, res = pcall(self._fetch, self, id)

	if ok then
		-- [[DBG]] print("cache:try(): found:" .. tostring(id))
		return res
	else
		-- [[DBG]] print("cache:try(): not found. Message: " .. tostring(res))
		if self.flag_failed then
			-- [[DBG]] print("cache:try(): flag as failed: " .. tostring(id))
			self.loaded[id] = false
		end

		return false, res
	end
end


function _mt_cache:getLoaded(id)
	uiShared.type1(1, id, "string")

	return self.loaded[id]
end


function _mt_cache:assign(id, value)
	uiShared.type1(1, id, "string")
	uiShared.notNilNotFalseNotNaN(2, value)

	if self.loaded[id] then
		error("cache already has a " .. self.msg_label .. " with ID: " .. tostring(id))
	end

	self.loaded[id] = value
end


function _mt_cache:unload(id)
	-- [[DBG]] print("cache:unload(): start: " .. tostring(id))
	local resource = self.loaded[id]
	if not resource then
		error("no " .. self.msg_label .. " currently loaded with ID: " .. tostring(id))
	end

	if self.unloader then
		self.unloader(resource, id, self.owner)
	end
	self.loaded[id] = nil
	-- [[DBG]] print("cache:unload(): done.")
end


function _mt_cache:clearAllFailed()
	for k, v in pairs(self.loaded) do
		if v == false then
			-- [[DBG]] print("cache:clearAllFailed(): clearing ID: " .. tostring(k))
			self.loaded[k] = nil
		end
	end
end


function uiLoad.loader_lua(file_path)
	local chunk = love.filesystem.load(file_path)
	local result = chunk()
	return result
end


function uiLoad.loader_image(file_path)
	return love.graphics.newImage(file_path)
end


return uiLoad
