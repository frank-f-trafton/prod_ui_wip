-- Resource helper functions.


local uiRes = {}


--local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


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


--- Given a file path, strip the file name off the end.
-- @param The file path to strip.
-- @return The stripped path.
function uiRes.pathStripFile(path)

	-- "foo/bar" -> "foo/"
	-- "" -> ""
	-- "foo" -> ""
	-- "/foo" -> "/foo"

	return string.match(path, "(.-/?)[^/]*$")
end


--- Clamp a number between a minimum and max value. If max is less than min, default to min.
-- @param val The number to clamp.
-- @param min The minimum value.
-- @param max The maximum value.
-- @return The clamped number.
function uiRes.clamp(val, min, max) -- XXX untested
	-- XXX this was from uiSkin. It could probably go to a shared math function library.
	return math.max(min, math.min(val, max))
end


local function _enumerate(folder, fileTree, ext, recursive, depth)

	--- Based on the LÖVE Wiki example: https://love2d.org/wiki/love.filesystem.getDirectoryItems

	if depth <= 0 then
		error("file enumeration depth exceeded.")
	end

	local lfs = love.filesystem
	local symlinks_enabled = lfs.areSymlinksEnabled()
	local filesTable = lfs.getDirectoryItems(folder)

	for i, v in ipairs(filesTable) do
		local file = folder .. "/" .. v
		local info = lfs.getInfo(file)

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

	-- XXX assertions
	return _enumerate(folder, {}, ext, recursive, depth)
end


return uiRes

