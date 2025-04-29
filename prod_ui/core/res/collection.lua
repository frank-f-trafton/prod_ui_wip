-- Resource collection objects.


local M = {}


local _mt_cf = {}
_mt_cf.__index = _mt_cf


M.lang = {}
local lang = M.lang


lang.err_bad_id = "missing resource"


function M.new()
	local cf = {
		paths = {},
		cache = {}
	}
	return setmetatable(cf, _mt_cf)
end


function _mt_cf:get(id)
	local cached = self.cache[id]
	if cached ~= nil then
		return self.cache[id]
	end

	local res
	if self:cb_lookFirst(id) then
		res = self:cb_loadFirst(id)
	else
		for i, path in ipairs(self.paths) do
			print("i", i, "path", path)
			local path_id = path .. (path ~= "" and "/" or "") .. id
			print("path_id", path_id)
			if self:cb_look(path_id) then
				res = self:cb_load(path_id)
				break
			end
		end
	end

	if res ~= nil then
		self.cache[id] = res
		return res
	end

	return self:cb_missing(id)
end


function _mt_cf:cb_look(path_id)
	return love.filesystem.getInfo(path_id .. ".lua", "file")
end


function _mt_cf:cb_lookFirst(id) end


function _mt_cf:cb_load(path_id)
	local chunk, err = love.filesystem.load(path_id .. ".lua")
	if not chunk then
		error(err)
	end
	return chunk()
end


function _mt_cf:cb_loadFirst(id) end


function _mt_cf:cb_missing(id)
	error(lang.err_bad_id)
end


return M
