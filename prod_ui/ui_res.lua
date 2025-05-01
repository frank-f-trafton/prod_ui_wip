-- uiRes: Resource helper functions.


local uiRes = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local pPath = require(REQ_PATH .. "lib.pile_path")
local uiShared = require(REQ_PATH .. "ui_shared")


local _info = {} -- For love.filesystem.getInfo().


function uiRes.infoIsDirectory(info)
	return info and (info.type == "directory" or (love.filesystem.areSymlinksEnabled() and info.type == "symlink"))
end


--- Loads and execute a Lua file, passing an arbitrary set of arguments to the chunk via the '...' operator.
-- @param path The path to the Lua file.
-- @param ... An arbitrary set of arguments to pass to the Lua chunk.
-- @return The result of executing the chunk.
function uiRes.loadLuaFile(path, ...)
	local chunk, err = love.filesystem.load(path)

	if not chunk then
		error(err)
	end

	local retval = chunk(...)

	return retval
end


--- Like uiRes.loadLuaFile(), but includes the file path as the first argument.
function uiRes.loadLuaFileWithPath(path, ...)
	return uiRes.loadLuaFile(path, path, ...)
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


local function _enumerate(path, list, ext, recursive, depth)
	--- Based on the LÖVE Wiki example: https://love2d.org/wiki/love.filesystem.getDirectoryItems

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

		elseif recursive and uiRes.infoIsDirectory(info) then
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
	uiShared.type1(1, path, "string")
	uiShared.typeEval(2, ext, "string", "table")
	-- don't assert 'recursive'
	uiShared.intGEEval(4, depth, 1)

	depth = depth or 1000

	if uiRes.infoIsDirectory(love.filesystem.getInfo(path), _info) then
		return _enumerate(path, {}, ext, recursive, depth)
	end

	return {}
end


function uiRes.assertNotRegistered(what, tbl, id)
	if tbl[id] then
		error(what .. ": ID '" .. tostring(id) .. "' is already registered.")
	end
end


function uiRes.extractIDFromLuaFile(base_path, file_path)
	uiShared.type1(1, base_path, "string")
	uiShared.type1(2, file_path, "string")

	if not file_path:find("%.lua$") then
		error("file_path string doesn't end in '.lua'.")
	end

	local str = file_path:match("^(.-)%.lua$")
	str = uiRes.stripFirstPartOfPath(base_path, str)
	return str
end


return uiRes
