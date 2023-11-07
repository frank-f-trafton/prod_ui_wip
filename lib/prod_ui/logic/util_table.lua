-- ProdUI: Lua table utilities.


local utilTable = {}


-- * Error functions *


function utilTable.concatVarargs(...)

	local str = ""
	local len = select("#", ...)
	for i = 1, len do
		str = str .. tostring(select(i, ...))
		if i < len then
			str = str .. ", "
		end
	end

	return str
end


function utilTable.concatSequence(seq)

	local str = ""
	for i, chunk in ipairs(seq) do
		str = str .. tostring(seq[i])
		if i < #seq then
			str = str .. ", "
		end
	end

	return str
end


-- * Drill-down functions *


--- Tries to get a value in a hierarchy of tables ("drill down").
-- @param tbl The top-level table to check.
-- @param ... Varargs list of fields to check, in order. All but the final field must point to table values.
-- @return The found value (can be nil), or nil plus index of where the search failed.
function utilTable.tryDrillV(tbl, ...)

	-- TODO: Assertions.

	local len = select("#", ...)

	for i = 1, len do
		if type(tbl) ~= "table" then
			return nil, i
		end

		-- Confirm that the field can be used as a table index. The two exceptions are nil and NaN.
		local field = select(i, ...)
		if field == nil or field ~= field then
			return nil, i
		end

		tbl = tbl[field]
	end

	-- tbl should now contain the final value.
	return tbl
end



--- Gets a value in a hierarchy of tables ("drill down"). The function raises a Lua error if the path through
--  the tables is invalid or the final value is nil.
-- @param tbl The top-level table to check.
-- @param ... Varargs list of fields to check in order. All but the final field must point to table values.
-- @return The found value. Raises a Lua error if the path was invalid or the final value is nil.
function utilTable.drillV(tbl, ...)

	-- TODO: Assertions. (will be handled in tryDrillV())

	local ret, bad_index = utilTable.tryDrillV(tbl, ...)
	if ret == nil then
		error("table drill-down failed on index #" .. bad_index .. ". Fields: " .. utilTable.concatVarargs(...))
	end

	return ret
end


--- Sequence version of utilTable.tryDrillV().
-- @param tbl The top-level table to check.
-- @param t2 Sequence (array) of fields to check in order. All but the final field must point to table values.
-- @return The found value (can be nil).
function utilTable.tryDrillT(tbl, t2)

	-- TODO: Assertions.

	for i = 1, #t2 do
		if type(tbl) ~= "table" then
			return nil, i
		end

		-- Confirm that the field can be used as a table index. The two exceptions are nil and NaN.
		local field = t2[i]
		if field == nil or field ~= field then
			return nil, i
		end

		tbl = tbl[field]
	end

	-- tbl should now contain the final value.
	return tbl
end


--- Sequence version of utilTable.drillV().
-- @param tbl The top-level table to check.
-- @param t2 Sequence (array) of fields to check in order. All but the final field must point to table values.
-- @return The found value. Raises a Lua error if the path was invalid or the final value is nil.
function utilTable.drillT(tbl, t2)

	-- TODO: Assertions. (will be handled in tryDrillT())

	local ret, bad_index = utilTable.tryDrillT(tbl, t2)
	if ret == nil then
		error("table drill-down failed on index #" .. bad_index .. ". Fields: " .. utilTable.concatSequence(t2))
	end

	return ret
end


--- String version of utilTable.tryDrillV(), where fields are stored in a string between a separator pattern.
-- @param tbl The top-level table to check.
-- @param sep The separator pattern. Must contain at least one character (like "/"). Plain search mode is used,
-- so Lua magic search characters will be treated as literals.
-- @param str The string of fields to check in order.
-- @return The found value (can be nil).
function utilTable.tryDrillS(tbl, sep, str)

	-- Assertions
	-- [[
	if type(tbl) ~= "table" then error("arg #1 must be a table.")
	elseif type(sep) ~= "string" or #sep == 0 then error("arg #2 must be a string with at least one character.")
	elseif type(str) ~= "string" then error("arg #3 must be a string.") end
	--]]

	local i, j = 0, 0
	local len = #str
	local count = 1

	while i <= len do
		if type(tbl) ~= "table" then
			return nil, count
		end

		j = str:find(sep, i + 1, true)
		j = j or #str + 1

		local field = str:sub(i, j - 1)

		if field == nil then
			return nil, count
		end

		tbl = tbl[field]

		count = count + 1
		i = j + 1
	end

	-- tbl should now contain the final value.
	return tbl
end


function utilTable.drillS(tbl, sep, str)

	-- Assertions handled in tryDrillS

	local ret, bad_index = utilTable.tryDrillS(tbl, sep, str)
	if ret == nil then
		error("table drill-down failed on index #" .. bad_index .. ". Fields: " .. str)
	end

	return ret
end


return utilTable

