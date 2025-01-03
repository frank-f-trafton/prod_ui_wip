-- uiRes: Resource helper functions.


local uiRes = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local uiShared = require(REQ_PATH .. "ui_shared")


--- Load and execute a Lua file, passing an arbitrary set of arguments to the chunk via the '...' operator.
-- @param ... An arbitrary set of arguments to pass to the Lua chunk. The first argument is the file path to the Lua file.
-- @return The result of executing the chunk.
function uiRes.loadLuaFile(...)
	local file_path = select(1, ...)
	local chunk, err = love.filesystem.load(file_path)

	if not chunk then
		error("couldn't load Lua file: " .. tostring(file_path) .. ", error: " .. err, 2)
	end

	local retval = chunk(...)

	return retval
end


--- Converts a file path string to one that is suitable for the Lua function `require`.
-- @param path The path to convert. ("path/to/file.lua" becomes "path.to.file")
-- @omit_end When true, clip off the last word in the path. ("path.to.file" becomes "path.to.")
-- @return The converted path.
function uiRes.pathToRequire(path, omit_end)
	path = path:gsub("/", "."):gsub("%.lua$", "")

	if omit_end then
		path = string.match(path, "(.-)[^%.]*$")
	end

	return path
end


--- Strip the last file or directory from a path.
-- @param path The file path to strip.
-- @param remove_trailing_slashes When true, omits any forward slashes at the end of the stripped path.
-- @return The stripped path, and the portion that was stripped.
function uiRes.pathStripEnd(path, remove_trailing_slashes)
	--[====[
	Examples with `remove_trailing_slashes` off:

	"foo/bar" -> "foo/", "bar"
	"bar" -> "", "bar"
	"" -> "", ""
	"a/b/c/" -> "a/b/", "c"
	"/foo" -> "/", "foo"
	"/" -> "", ""
	[[///]]" -> "//", ""
	--]====]

	local s1, s2 = path:match("^(.-)([^/]*)/?$")
	if remove_trailing_slashes then
		s1 = s1:match("^(.-)/*$")
	end
	return s1, s2
end


--- Strips the file extension from a path.
-- @param path The file path to strip.
-- @return The path without the file extension.
function uiRes.stripFileExtension(path)
	--[[
	"hello.lua" -> "hello", "lua"
	"foo/bar.txt" -> "foo/bar", "txt"
	"zyp.tar.gz" -> "zyp", "tar.gz"
	--]]

	local a, b = uiRes.pathStripEnd(path)
	local c, d = b:match("^([^%.]*)(.*)$")
	return a .. c, d
end

--- Strips the file extension from a path.
-- @param path The file path to strip.
-- @param omit_first_dot When true, removes the first dot in the returned extension (".lua" -> "lua")
-- @return The path without the extension, and the extension.
function uiRes.stripFileExtension(path, omit_first_dot)
	--[[
	"hello.lua" -> "hello", ".lua"
	"foo/bar.txt" -> "foo/bar", ".txt"
	"zyp.tar.gz" -> "zyp", ".tar.gz"
	--]]

	-- If the extension never changes, you can get away with a single call to string.match: "^(.-)%.lua$"

	local a, b = uiRes.pathStripEnd(path)
	local c, d = b:match("^([^%.]*)(.*)$")
	if omit_first_dot then
		d = d:sub(2)
	end
	return a .. c, d
end


--- Strip the first part of a path.
-- @param base_dir The initial part of the path. Any forward slash on the end is omitted.
-- @param path The path to be shortened.
-- @return The stripped path.
function uiRes.stripBaseDirectoryFromPath(base_dir, path)
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


local function _enumerate(folder, fileTree, ext, recursive, depth)
	--- Based on the LÖVE Wiki example: https://love2d.org/wiki/love.filesystem.getDirectoryItems

	if depth <= 0 then
		error("file enumeration depth exceeded.")
	end

	local symlinks_enabled = love.filesystem.areSymlinksEnabled()
	local filesTable = love.filesystem.getDirectoryItems(folder)

	for i, v in ipairs(filesTable) do
		local file = folder .. "/" .. v
		local info = love.filesystem.getInfo(file)

		if info.type == "file" then
			if not ext
			or type(ext) == "string" and string.match(v, "%..-$") == ext
			or type(ext) == "table" and ext[string.match(v, "%..-$")]
			or type(ext) == "function" and ext(folder, v)
			then
				table.insert(fileTree, file)
			end

		elseif recursive and info.type == "directory" or (symlinks_enabled and info.type == "symlink") then
			_enumerate(file, fileTree, ext, recursive, depth - 1)
		end
	end

	return fileTree
end


--- Given a folder path, return a table of files, directories and symlinks (if enabled in love.filesystem).
-- @param folder The starting folder path to scan.
-- @param ext Extension filter. When a string, only files with a matching extension are included. When a table, any file with an extension that matches a key in the table is included. When a function (taking the folder path and file name as arguments), files are included if the function returns true. When false/nil, all files are included.
-- @param recursive When true, scan all sub-folders.
-- @param depth (1000) The maximum recursion depth permitted. Raises an error if exceeded. Must be at least 1.
-- @return A table of enumerated files and folders/symlinks.
function uiRes.enumerate(folder, ext, recursive, depth)
	uiShared.type1(1, folder, "string")
	uiShared.typeEval(2, ext, "string", "table", "function")
	-- don't assert 'recursive'
	uiShared.intGEEval(4, depth, 1)

	if not love.filesystem.getInfo(folder) then
		error("nothing exists at file path: " .. tostring(folder))
	end

	--[[
	'ext' examples:

	string: ".lua"

	table: {
		[".lua"] = true,
		[".txt"] = true,
	}

	function: function(folder, file_name)
		if file_name == "some string comparison" then
			return true -- enumerate file.
		end
		-- do not enumerate file.
	end
	--]]

	depth = depth or 1000

	return _enumerate(folder, {}, ext, recursive, depth)
end


return uiRes
