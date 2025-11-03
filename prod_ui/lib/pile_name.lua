-- PILE Name Registry v1.315
-- (C) 2025 PILE Contributors
-- License: MIT or MIT-0
-- https://github.com/frank-f-trafton/pile_base


local M = {}


M.lang = {
	bad_name = "expected string or false/nil for name",
	not_allowed = "can only associate names with tables, functions, threads and userdata"
}
local lang = M.lang


M.allowed = {["function"]=true, table=true, thread=true, userdata=true}
local _allowed = M.allowed


M.names = setmetatable({}, {__mode="v"})
local names = M.names


function M.set(o, name)
	if not _allowed[type(o)] then
		error(lang.not_allowed)

	elseif name and type(name) ~= "string" then
		error(lang.bad_name)
	end

	names[o] = name or nil

	return o
end


function M.get(o)
	if not _allowed[type(o)] then
		error(lang.not_allowed)
	end

	return names[o]
end


function M.safeGet(o, fallback)
	if not _allowed[type(o)] then
		error(lang.not_allowed)
	end

	return names[o] or (fallback and tostring(fallback) or "Unknown")
end


return M
