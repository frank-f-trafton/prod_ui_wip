-- uiRes: Resource helper functions.


local uiRes = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local pPath = require(REQ_PATH .. "lib.pile_path")
local pTable = require(REQ_PATH .. "lib.pile_table")
local uiAssert = require(REQ_PATH .. "ui_assert")


local _info = {} -- For love.filesystem.getInfo()
local _blank_env = {} -- For setfenv()


function uiRes.assertGetInfo(...)
	local info = love.filesystem.getInfo(...)
	if not info then
		error("unable to read file: " .. tostring(select(1, ...)))
	end
	return info
end


--[[
NOTE: love.filesystem.getDirectoryItems() is affected by quirk in PhysicsFS, where the direct contents of
symlinked directories cannot be listed:

https://github.com/love2d/love/issues/1938
--]]
function uiRes.infoCanTraverse(info)
	return info and (info.type == "directory" or (love.filesystem.areSymlinksEnabled() and info.type == "symlink"))
end


function uiRes.assertLoad(path)
	local chunk, err = love.filesystem.load(path)
	if not chunk then
		error(err)
	end
	return chunk
end


--- Loads and executes a Lua file, passing an arbitrary set of arguments to the chunk via the '...' operator.
-- @param path The path to the Lua file.
-- @param [env] The environment table to use, if applicable.
-- @param [...] An arbitrary set of arguments to pass to the Lua chunk.
-- @return The result of executing the chunk.
function uiRes.loadLuaFile(path, env, ...)
	local chunk = uiRes.assertLoad(path)
	if env then
		setfenv(chunk, env)
	end
	local retval = chunk(...)
	return retval
end


--- Given a path and a substring that is anchored to the end, Strips the first part of a path.
-- @param base_dir The initial part of the path. Any forward slash on the end is omitted.
-- @param path The path to be shortened.
-- @return The stripped path.
function uiRes.stripFirstPartOfPath(base_dir, path)
	-- "base/dir/", "base/dir/foobar.lua" -> "foobar.lua"
	-- "base/dir", "base/dir/foobar.lua" -> "foobar.lua"

	if path:sub(1, #base_dir) ~= base_dir then
		error("base_dir doesn't match the start of this path.")
	end
	local dir_chop = #base_dir + 1
	if path:sub(dir_chop, dir_chop) == "/" then
		dir_chop = dir_chop + 1
	end
	return path:sub(dir_chop)
end


function uiRes.assertNotRegistered(what, tbl, id)
	if tbl[id] then
		error(what .. ": ID '" .. tostring(id) .. "' is already registered.")
	end
end


function uiRes.extractIDFromLuaFile(base_path, file_path)
	uiAssert.type(1, base_path, "string")
	uiAssert.type(2, file_path, "string")

	if not file_path:find("%.lua$") then
		error("file_path string doesn't end in '.lua'.")
	end

	local str = file_path:match("^(.-)%.lua$")
	str = uiRes.stripFirstPartOfPath(base_path, str)
	return str
end


local function _enumerate(path, list, ext, recursive, depth)
	-- Based on: https://love2d.org/wiki/love.filesystem.getDirectoryItems

	if depth <= 0 then
		error("file enumeration depth exceeded.")
	end

	local files_array = love.filesystem.getDirectoryItems(path)

	for i, v in ipairs(files_array) do
		local id = pPath.join(path, v)
		local info = love.filesystem.getInfo(id, _info)

		if info.type == "file" then
			if not ext
			or type(ext) == "string" and v:match("%..-$") == ext
			or type(ext) == "table" and ext[v:match("%..-$")]
			then
				table.insert(list, id)
			end

		elseif recursive and uiRes.infoCanTraverse(info) then
			_enumerate(id, list, ext, recursive, depth - 1)
		end
	end

	return list
end


--- Given a directory path, returns a table of files.
-- @param path The starting path to scan.
-- @param ext Extension filter. When a string, only files with a matching extension are included. When a table, any file with an extension that matches a key in the table is included. When false/nil, all files are included.
-- @param recursive When true, scan all subdirectories.
-- @param depth (1000) The maximum recursion depth permitted. Raises an error if exceeded. Must be at least 1.
-- @return A table of enumerated files. If the path does not point to a directory, then an empty table is returned.
function uiRes.enumerate(path, ext, recursive, depth)
	uiAssert.type(1, path, "string")
	uiAssert.typesEval(2, ext, "string", "table")
	-- don't assert 'recursive'
	uiAssert.intGEEval(4, depth, 1)

	depth = depth or 1000

	if uiRes.infoCanTraverse(love.filesystem.getInfo(path), _info) then
		return _enumerate(path, {}, ext, recursive, depth)
	end

	return {}
end


local function _enumerateDirTable(path, tbl, handlers, depth, max_items)
	-- Based on: https://love2d.org/wiki/love.filesystem.getDirectoryItems

	if depth <= 0 then
		error("directory enumeration depth exceeded.")
	end

	for _, file_name in ipairs(love.filesystem.getDirectoryItems(path)) do
		max_items = max_items - 1
		if max_items <= 0 then
			error("max items exceeded.")
		end

		local item_path = pPath.join(path, file_name)
		local info = love.filesystem.getInfo(item_path, _info)
		if not info then
			error("file was enumerated, but could not be queried for more info: " .. tostring(item_path))

		elseif info.type == "file" then
			local file_ext = pPath.getExtension(file_name)
			local id, retval = handlers[file_ext](item_path, file_name, file_ext)
			if id ~= nil then
				if retval == nil then
					error("no return value provided for ID: " .. tostring(id) .. ". Path: " .. item_path)

				elseif tbl[id] then
					error("This ID is already populated: " .. tostring(id) .. ". Path: " .. item_path)
				end

				tbl[id] = retval
			end

		elseif uiRes.infoCanTraverse(info) then
			local id
			if handlers["directory"] then
				id = handlers["directory"](item_path, file_name)
			else
				id = file_name
			end

			if tbl[id] then
				error("This ID is already populated: " .. tostring(id) .. ". Path: " .. item_path)
			end
			tbl[id] = {}
			_enumerateDirTable(item_path, tbl[id], handlers, depth - 1, max_items)
		end
	end
end


--- Loads a set of files as one Lua table.
-- @param path The path.
-- @param [handlers] A table of extension handler functions. If not provided, a set of defaults will be substituted.
--	(For more info, see the defaults and their comments below.)
-- @param [depth] (1000) How deep to enumerate before raising an error.
-- @param [max_items] (16384) How many items to check before raising an error.
-- @return The table.
function uiRes.loadDirectoryAsTable(path, handlers, depth, max_items)
	uiAssert.type(1, path, "string")
	uiAssert.typeEval(2, handlers, "table")
	uiAssert.typeEval(3, depth, "number")
	uiAssert.typeEval(4, max_items, "number")

	handlers = handlers or uiRes.dir_handlers
	depth = depth or 1000
	max_items = max_items or 200000

	local info = love.filesystem.getInfo(path, _info)
	if uiRes.infoCanTraverse(love.filesystem.getInfo(path), info) then
		local tbl = {}
		_enumerateDirTable(path, tbl, handlers, depth, max_items)
		return tbl
	end
end


-- The default DirTable handlers.
--[[
For files, the arguments are:
* full_path: the path, filename and extension.
* name: The filename and extension.
* ext: Just the extension.

The last two are provided for convenience, since they are computed while iterating.

The return values are a key and a value to assign to the table at this level. Return 'nil' to ignore the file and
assign nothing.

Directories are scanned by default, but a special handler named "directory" may be provided.
* full_path
* name

Note the lack of an extension argument.

Return just the key to use for the new table at this level, or 'nil' to ignore the directory and its contents.
--]]
uiRes.dir_handlers = {
	[".lua"] = function(full_path, name, ext)
		--[[
		-- To ignore .lua files whose names begin with an underscore:
		if name:sub(1, 1) == "_" then
			return
		end
		--]]

		local chunk = uiRes.assertLoad(full_path)
		chunk = chunk()
		local id = name:sub(1, -(#ext + 1))

		return id, chunk
	end,

	--[=[
	[".txt"] = function(full_path, name, ext)
		--[[
		-- To ignore text files whose names begin with an underscore:
		if name:sub(1, 1) == "_" then
			return
		end
		--]]

		local str, err = love.filesystem.read(full_path)
		if not str then
			error(err)
		end

		local id = name:sub(1, -(#ext + 1))

		return id, str
	end,
	--]=]

	--[=[
	["directory"] = function(full_path, name)
		--[[
		-- To ignore directory names that begin with an underscore:
		if name:sub(1, 1) == "_" then
			return
		end
		--]]
		return name
	end,
	--]=]
}


uiRes.dir_handler_lua_blank_env = {
	-- Load a Lua file with a blank environment:
	[".lua"] = function(full_path, name, ext)
		local chunk = uiRes.assertLoad(full_path)
		setfenv(chunk, _blank_env)
		chunk = chunk()
		local id = name:sub(1, -(#ext + 1))

		return id, chunk
	end,
}


-- @param path The file path to the Lua file (without extension) or directory.
-- @param [env] The environment table to use, if applicable.
-- @param [handlers] A table of extension handler functions. If not provided, a set of defaults will be substituted.
-- @return A table based on the file or directory of files.
function uiRes.loadLuaFileOrDirectoryAsTable(path, env, handlers)
	uiAssert.type(1, path, "string")

	local lua_path = path .. ".lua"
	local info = love.filesystem.getInfo(lua_path, _info)
	if info and info.type == "file" then
		return uiRes.loadLuaFile(lua_path, env)
	else
		info = love.filesystem.getInfo(path, _info)
		if info and info.type == "directory" then
			return uiRes.loadDirectoryAsTable(path, handlers)
		end
	end
	error("failed to load Lua file or directory: " .. path)
end


return uiRes
