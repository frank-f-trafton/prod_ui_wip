local uiLoad = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local uiShared = require(REQ_PATH .. "ui_shared")


local _mt_loader = {}


function uiLoad.new(owner, fn_load)
	-- 'owner' is presumably a table, but can be of any type.
	uiShared.type1(1, fn_load, "function")

	local self, mt = {}, {}
	mt.__index = _mt_loader
	setmetatable(self, mt)

	mt.owner = owner
	mt.fn_load = fn_load

	return self
end


function _mt_loader:try(path)
	uiShared.type1(1, path, "string")

	local loaded = self[path]
	if loaded then
		return loaded
	end

	local mt = getmetatable(self)
	local res, err = mt.fn_load(mt.owner, path)
	if not res then
		return false, err
	end
	self[path] = res
	return res
end


function _mt_loader:get(path)
	uiShared.type1(1, path, "string")

	local res, err = self:try(path)
	if not res then
		error(tostring(path) .. ": " .. tostring(err), 2)
	end
	return res
end


-- Some example loaders.
--[[
local function _loader_lua(owner, path)
	local chunk, err = love.filesystem.load(path .. ".lua")
	if not chunk then
		return false, err
	end

	return chunk(owner, path)
end


local function _loader_png(owner, path)
	local info = love.filesystem.getInfo(path)
	if not info then
		return false, "file not found."

	elseif info.type ~= "file" then
		return false, "not a file."
	end

	return love.graphics.newImage(path)
end
--]]


return uiLoad
