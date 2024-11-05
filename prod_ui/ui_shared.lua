local uiShared = {}


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local pileArgCheck = require(PATH .. "lib.pile_arg_check")


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


uiShared.type = pileArgCheck.type -- (n, v, ...)
uiShared.type1 = pileArgCheck.type1 -- (n, v, e)
uiShared.typeEval = pileArgCheck.typeEval -- typeEval(n, v, ...)
uiShared.typeEval1 = pileArgCheck.typeEval1 -- (n, v, e)
uiShared.int = pileArgCheck.int -- (n, v)
uiShared.evalInt = pileArgCheck.evalInt -- (n, v)
uiShared.intGE = pileArgCheck.intGE -- (n, v, min)
uiShared.evalIntGE = pileArgCheck.evalIntGE -- (n, v, min)
uiShared.intRange = pileArgCheck.intRange -- (n, v, min, max)
uiShared.evalIntRange = pileArgCheck.evalIntRange -- (n, v, min, max)
uiShared.intRangeStatic = pileArgCheck.intRangeStatic -- (n, v, min, max)
uiShared.evalIntRangeStatic = pileArgCheck.evalIntRangeStatic -- (n, v, min, max)
uiShared.numberNotNaN = pileArgCheck.numberNotNaN -- (n, v)
uiShared.enum = pileArgCheck.enum -- (n, v, id, e)
uiShared.enumEval = pileArgCheck.enumEval -- (n, v, id, e)


function uiShared.loveType(n, obj, typ)
	if obj:type() ~= typ then
		error("argument #" .. n .. ": bad LÖVE object type (expected " .. typ .. ", got " .. obj:type() .. ")", 2)
	end
end


function uiShared.loveTypeOf(n, obj, typ)
	if not obj:typeOf(typ) then
		error("argument #" .. n .. ": expected LÖVE object type '" .. typ .. "' in class hierarchy", 2)
	end
end


--- Argument is a string or coloredtext sequence.
function uiShared.assertText(n, text)
	if type(text) ~= "string" and type(text) ~= "table" then
		error("argument #" .. n .. ": bad type (expected text (string or table), got " .. type(text), 2)
	end
end


-- * / Assertions *


return uiShared
