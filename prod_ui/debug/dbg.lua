-- Miscellaneous debug and troubleshooting functions.


local dbg = {}


--- Prints the IDs of a widget tree as an indented string.
-- @param wid The root widget to probe.
-- @param thimble If you want to mark the location of the thimble (keyboard focus), pass in 'context.current_thimble' here.
-- @param _str (Internal use, leave blank when calling) The work-in-progress string.
-- @param _tabs (Internal use, leave blank when calling) How many tabs to indent.
-- @return The finalized string, and indentation level (internal use).
function dbg.widStringHierarchy(wid, thimble, _str, _tabs)

	_str = _str or ""
	_tabs = _tabs or 0

	_str = _str .. string.rep("\t", _tabs) .. wid.id .. " (" .. tostring(wid) .. ")"
	if wid == thimble then
		_str = _str .. " (T)"
	end
	_str = _str .. "\n"

	for i, child in ipairs(wid.children) do
		local _
		_str, _ = dbg.widStringHierarchy(child, thimble, _str, _tabs + 1)
	end

	return _str, _tabs
end


function dbg.hexString(str)

	local out = ""
	for i = 1, #str do
		local byte = string.byte(str, i)
		out = out .. string.format("%x", byte)
		if i < #str then
			out = out .. " "
		end
	end

	return out
end


return dbg
