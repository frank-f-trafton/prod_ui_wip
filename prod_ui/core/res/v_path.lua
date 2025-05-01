--[[
Multi-path wrappers for some functions in the love.filesystem API and in 'ui_res.lua'.
--]]


local context = select(1, ...)


local vPath = {}


local _info = {} -- For love.filesystem.getInfo().


local pPath = require(context.conf.prod_ui_req .. "lib.pile_path")
local uiRes = require(context.conf.prod_ui_req .. "ui_res")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")


function vPath.getInfo(paths, id, ...)
	for i, base in ipairs(paths) do
		local path = pPath.join(base, id)
		local info = love.filesystem.getInfo(path, ...)
		if info then
			return info, path
		end
	end
end


function vPath.getDirectoryItems(paths, id)
	local hash = {}
	for i, base in ipairs(paths) do
		local path = pPath.join(base, id)
		local temp = love.filesystem.getDirectoryItems(path)
		for i, v in ipairs(temp) do
			hash[v] = path
		end
	end
	return hash
end


local function _enumerate(base, path, hash, ext, recursive, depth)
	--- Based on the LÖVE Wiki example: https://love2d.org/wiki/love.filesystem.getDirectoryItems

	if depth <= 0 then
		error("file enumeration depth exceeded.")
	end

	local full_path = pPath.join(base, path)
	local files_array = love.filesystem.getDirectoryItems(full_path)

	for i, v in ipairs(files_array) do
		local id = pPath.join(path, v)

		if not hash[id] then
			local joined_id = pPath.join(base, id)
			local info = love.filesystem.getInfo(joined_id, _info)

			if info.type == "file" then
				if not ext
				or type(ext) == "string" and v:match("%..-$") == ext
				or type(ext) == "table" and ext[v:match("%..-$")]
				then
					hash[id] = joined_id
				end

			elseif recursive and uiRes.infoIsDirectory(info) then
				_enumerate(base, id, hash, ext, recursive, depth - 1)
			end
		end
	end
end


function vPath.enumerate(paths, ext, recursive, depth)
	uiShared.type1(1, paths, "table")
	uiShared.typeEval(2, ext, "string", "table")
	-- don't assert 'recursive'
	uiShared.intGEEval(4, depth, 1)

	depth = depth or 1000

	local hash = {}

	for i, base in ipairs(paths) do
		_enumerate(base, "", hash, ext, recursive, depth)
	end

	return hash
end


return vPath
