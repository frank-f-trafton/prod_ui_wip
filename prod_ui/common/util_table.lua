-- ProdUI: Lua table utilities.


local utilTable = {}


-- * Drill-down functions *


--- Looks up a value in a nested table structure, using a string of delimited fields.
-- @param tbl The table to begin searching from.
-- @param sep The separator pattern. Must contain at least one character (like "/"). Plain search mode is used,
--	so Lua's magic search characters will be treated as literals.
-- @param str The string of fields to check.
-- @return The retrieved value or nil, plus the index of the substring where the search stopped.
function utilTable.tryDrill(tbl, sep, str)
	if type(sep) ~= "string" or #sep == 0 then
		error("argument #2: must be a non-empty string.")
	end

	local i, j, count, len = 0, 0, 0, #str
	while i <= len do
		if type(tbl) ~= "table" then
			if i == 0 then
				error("argument #1: expected table.")
			end
			return nil, count
		end

		j = str:find(sep, i + 1, true) or #str + 1
		tbl = tbl[str:sub(i, j - 1)]

		i = j + 1
		count = count + 1
	end

	-- 'tbl' should now contain the final value.
	return tbl, count
end


--- Wrapper for tryDrill which raises an error if the result is nil.
function utilTable.drill(tbl, sep, str)
	local ret, count = utilTable.tryDrill(tbl, sep, str)
	if ret == nil then
		error("table drill-down failed. String: '" .. str .. "', failed at substring #" .. count .. ".")
	end
	return ret
end


return utilTable
