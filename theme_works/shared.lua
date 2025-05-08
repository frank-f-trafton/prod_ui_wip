local shared = {}


local nativefs = require("lib.nativefs")


-- * Filesystem wrappers * --


function shared.nfsGetInfo(path)
	return nativefs.getInfo(path)
end


function shared.nfsWrite(path, data)
	local ok, err = nativefs.write(path, data)
	if not ok then
		error(err)
	end
end


function shared.nfsRemove(path)
	local ok, err = nativefs.remove(path)

	if not ok then
		error("failed to delete '" .. tostring(path) .. "': " .. tostring(err))
	end
end


function shared.recursiveEnumerate(folder, _file_list, _folder_list)
	_file_list = _file_list or {}
	_folder_list = _folder_list or {}

	local filesTable = nativefs.getDirectoryItems(folder)

	for i, v in ipairs(filesTable) do
		local file = folder .. "/" .. v
		local info = nativefs.getInfo(file)

		if not info then
			print("ERROR: failed to get file info for: " .. file)
		else
			if info.type == "file" then
				table.insert(_file_list, file)

			elseif info.type == "directory" then
				table.insert(_folder_list, file)
				shared.recursiveEnumerate(file, _file_list, _folder_list)
			end
		end
	end

	return _file_list, _folder_list
end


function shared.recursiveDelete(folder)
	local files, folders = shared.recursiveEnumerate(folder)
	for i, file in ipairs(files) do
		shared.nfsRemove(file)
	end

	for i = #folders, 1, -1 do
		shared.nfsRemove(folders[i])
	end
end


function shared.pathToRequire(path, omit_end)
	path = path:gsub("/", "."):gsub("%.lua$", "")

	if omit_end then
		path = string.match(path, "(.-)[^%.]*$")
	end

	return path
end


function shared.stripTrailingSlash(path)
	return string.match(path, "(.-)/*$")
end


function shared.nfsLoadLuaFile(...)
	local file_path = select(1, ...)
	local chunk, err = nativefs.load(file_path)

	if not chunk then
		error("couldn't load Lua file: " .. tostring(file_path) .. ", error: " .. err)
	end

	local retval = chunk(...)

	return retval
end


return shared
