-- Depot: Version 0.0.1 (BETA)
-- See README.md for more info.

--[[
MIT License

Copyright (c) 2023 RBTS

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]


-- To toggle debug printing, add or remove the spaces between `--` and `[[DBG]]`.


local depot = {}


-- * Internal * ---------------------------------------------------------------


local _mt_cache = {}
_mt_cache.__index = _mt_cache


local function errArgType(n, expected, val)
	error("argument #" .. n .. ": bad type (expected " .. expected .. ", got " .. type(val) .. ")", 2)
end


local function errOptType(n, opt_name, expected, opts)
	error("argument #" .. n .. ", option " .. opt_name
		.. ": bad type (expected " .. expected .. ", got " .. type(opts[opt_name]) .. ")", 2)
end


local function errArrayBadType(n, i, expected, arr)
	error("argument #" .. n .. ", array index #" .. i .. ": bad type (expected " .. expected .. ", got " .. type(arr[i]) .. ")", 2)
end


-- Joins a path and file name, injecting a forward slash when necessary.
local function join(path, file_name)

	if path == "" or string.sub(path, -1) == "/" then
		return path .. file_name

	else
		return path .. "/" .. file_name
	end
end


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
		local file_path = join(path, id)
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
			local file_path = join(path, id .. "." .. extension)
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


-- * Public Functions * -------------------------------------------------------


function depot.new(loader, opts)

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
	end

	-- Assertions
	-- [[
	if type(loader) ~= "function" then errArgType(1, "function", loader)
	elseif paths and type(paths) ~= "table" then errOptType(2, "paths", "false/nil/table", opts)
	elseif extensions and type(extensions) ~= "table" then errOptType(2, "extensions", "false/nil/table", opts)
	elseif file_types and type(file_types) ~= "table" then errOptType(2, "file_types", "false/nil/table", opts)
	elseif msg_label and type(msg_label) ~= "string" then errOptType(2, "msg_label", "false/nil/string", opts)
	elseif fallback_id and type(fallback_id) ~= "string" then errOptType(2, "fallback_id", "false/nil/string", opts)
	elseif unloader and type(unloader) ~= "function" then errOptType(2, "unloader", "false/nil/function", opts)
	elseif owner and type(owner) ~= "table" then errOptType(2, "owner", "false/nil/table", opts) end

	-- Check that all array entries are strings.
	local check_array
	if paths then
		check_array = checkArrayOfStrings(paths)
		if check_array ~= true then
			errArrayBadType(1, check_array, "string", paths)
		end
	end
	if extensions then
		check_array = checkArrayOfStrings(extensions)
		if check_array ~= true then
			errArrayBadType(2, check_array, "string", extensions)
		end
	end
	--]]

	local self = setmetatable({}, _mt_cache)

	self.paths = paths or nil
	self.extensions = extensions or nil
	self.file_types = file_types or nil
	self.loader = loader
	self.unloader = unloader or nil
	self.msg_label = msg_label or "resource"
	self.fallback_id = fallback_id or nil
	self.flag_failed = flag_failed or nil
	self.owner = owner or nil

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


-- * Object: Cache * ----------------------------------------------------------


function _mt_cache:get(id)

	-- Assertions
	-- [[
	if type(id) ~= "string" then errArgType(1, "string", id) end
	--]]

	-- [[DBG]] print("cache:get(): start: " .. tostring(id))

	-- Already loaded.
	local resource = self.loaded[id]
	if resource then
		-- [[DBG]] print("depot:get(): already loaded.")
		return resource
	end

	-- Not loaded. Fetch from file system.
	return self:_fetch(id)
end


function _mt_cache:try(id)

	-- Assertions
	-- [[
	if type(id) ~= "string" then errArgType(1, "string", id) end
	--]]

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

	-- Assertions
	-- [[
	if type(id) ~= "string" then errArgType(1, "string", id) end
	--]]

	return self.loaded[id]
end


function _mt_cache:assign(id, value)

	-- Assertions
	-- [[
	if type(id) ~= "string" then errArgType(1, "string", id)
	elseif not value then errArgType(2, "(not false/nil)", value) end
	--]]

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


-- * Built-in Loaders * -------------------------------------------------------


function depot.loader_lua(file_path)

	local chunk = love.filesystem.load(file_path)
	local result = chunk()
	return result
end


function depot.loader_image(file_path)
	return love.graphics.newImage(file_path)
end


return depot

