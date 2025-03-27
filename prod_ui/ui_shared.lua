local uiShared = {}


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local pileArgCheck = require(PATH .. "lib.pile_arg_check")
local pTable = require(PATH .. "lib.pile_table")


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
uiShared.typeEval = pileArgCheck.typeEval -- typeEval(n, v, ...)
uiShared.type1 = pileArgCheck.type1 -- (n, v, e)
uiShared.typeEval1 = pileArgCheck.typeEval1 -- (n, v, e)
uiShared.fieldType = pileArgCheck.fieldType -- (n, t, id, ...)
uiShared.fieldType1 = pileArgCheck.fieldType1 -- (n, t, id, e)
uiShared.fieldTypeEval = pileArgCheck.fieldTypeEval -- (n, t, id, ...)
uiShared.fieldTypeEval1 = pileArgCheck.fieldTypeEval1 -- (n, t, id, e)
uiShared.int = pileArgCheck.int -- (n, v)
uiShared.intEval = pileArgCheck.intEval -- (n, v)
uiShared.intGE = pileArgCheck.intGE -- (n, v, min)
uiShared.intGEEval = pileArgCheck.intGEEval -- (n, v, min)
uiShared.intRange = pileArgCheck.intRange -- (n, v, min, max)
uiShared.intRangeEval = pileArgCheck.intRangeEval -- (n, v, min, max)
uiShared.intRangeStatic = pileArgCheck.intRangeStatic -- (n, v, min, max)
uiShared.intRangeStaticEval = pileArgCheck.intRangeStaticEval -- (n, v, min, max)
uiShared.numberNotNaN = pileArgCheck.numberNotNaN -- (n, v)
uiShared.numberNotNaNEval = pileArgCheck.numberNotNaNEval -- (n, v)
uiShared.enum = pileArgCheck.enum -- (n, v, id, e)
uiShared.enumEval = pileArgCheck.enumEval -- (n, v, id, e)
uiShared.notNil = pileArgCheck.notNil -- (n, v)
uiShared.notNilNotNaN = pileArgCheck.notNilNotNaN -- (n, v)
uiShared.notNilNotFalse = pileArgCheck.notNilNotFalse -- (n, v)
uiShared.notNilNotFalseNotNaN = pileArgCheck.notNilNotFalseNotNaN -- (n, v)
uiShared.notNaN = pileArgCheck.notNaN -- (n, v)


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


-- * Type Utilities *


uiShared.makeLUT = pTable.makeLUT -- (t); array of values to convert into a hash table.
uiShared.makeLUTV = pTable.makeLUTV -- (...); varargs list of values to convert to a hash table.


-- * / Type Utilities *


return uiShared
