local uiShared = {}


-- * Dummies *


--- A generic dummy function.
function uiShared.dummyFunc() end


-- A generic empty table dummy.
uiShared.dummy_table = {}
uiShared.dummy_table.__newindex = function()
	-- NOTE: this will not catch table.insert() or rawset().
	error("attempt to write to an empty table dummy.", 2)
end
setmetatable(uiShared.dummy_table, uiShared.dummy_table)


-- * Generic type errors *


--- Type error in a function argument.
function uiShared.errBadType(num, var, type_string)
	error("argument #" .. num .. " bad type (expected " .. type_string .. ", got " .. type(var) .. ")", 2)
end


--- Type error in a table field.
function uiShared.errBadFieldType(field_str, var, type_string)
	error("Table field '" .. field_str .. "' bad type (expected " .. type_string .. ", got " .. type(var) .. ")", 2)
end


--- Type error in a sequence.
function uiShared.errBadSeq(num, var, type_string)
	error("sequence entry #" .. num .. " bad type (expected " .. type_string .. ", got " .. type(var) .. ")", 2)
end


-- * Lock errors *


--- The context is locked.
function uiShared.errLockedContext(action)
	error("cannot " .. action .. " while context is locked for updating.", 2)
end


--- A widget's parent is locked.
function uiShared.errLockedParent(action)
	error("cannot " .. action .. " while widget's parent is locked for updating.", 2)
end


--- A widget is locked.
function uiShared.errLocked(action)
	error("cannot " .. action .. " while widget is locked for updating.", 2)
end


-- * Assertions *


--- Argument is a string or coloredtext sequence.
function uiShared.assertText(n, text)

	if type(text) ~= "string" and type(text) ~= "table" then
		error("argument #" .. n .. ": bad type (expected text (string or table), got " .. type(text), 2)
	end
end


--- Argument is a number.
function uiShared.assertNumber(n, num)

	if type(num) ~= "number" then
		uiShared.errBadType(n, num, "number")
	end
end


--- Argument is a table.
function uiShared.assertTable(n, tbl)

	if type(tbl) ~= "table" then
		uiShared.errBadType(n, tbl, "table")
	end
end


--- Argument is a number which is not NaN.
function uiShared.assertNumberNotNaN(n, num)

	if type(num) ~= "number" then
		uiShared.errBadType(n, num, "number")

	elseif num ~= num then
		error("argument #" .. n .. ": value cannot be NaN.")
	end
end


--- Argument is an integer which is not NaN.
function uiShared.assertNumberIntNotNaN(n, num)

	if type(num) ~= "number" then
		uiShared.errBadType(n, num, "number")

	elseif math.floor(num) ~= num then
		error("argument #" .. n .. ": value must be an integer.")

	elseif num ~= num then
		error("argument #" .. n .. ": value cannot be NaN.")
	end
end


--- Argument is an integer, within a certain range.
function uiShared.assertIntRange(n, num, first, last)

	if type(num) ~= "number" then
		uiShared.errBadType(n, num, "number")

	elseif math.floor(num) ~= num then
		error("argument #" .. n .. ": value must be an integer.")

	elseif num < first or num > last then
		error("argument #" .. n .. ": value is out of range.")
	end
end


-- * / Assertions *


return uiShared
