local uiShared = {}


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local pArgCheck = require(PATH .. "lib.pile_arg_check")
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


uiShared.type = pArgCheck.type -- (n, v, ...)
uiShared.typeEval = pArgCheck.typeEval -- typeEval(n, v, ...)
uiShared.type1 = pArgCheck.type1 -- (n, v, e)
uiShared.typeEval1 = pArgCheck.typeEval1 -- (n, v, e)
uiShared.fieldType = pArgCheck.fieldType -- (n, t, id, ...)
uiShared.fieldType1 = pArgCheck.fieldType1 -- (n, t, id, e)
uiShared.fieldTypeEval = pArgCheck.fieldTypeEval -- (n, t, id, ...)
uiShared.fieldTypeEval1 = pArgCheck.fieldTypeEval1 -- (n, t, id, e)
uiShared.int = pArgCheck.int -- (n, v)
uiShared.intEval = pArgCheck.intEval -- (n, v)
uiShared.intGE = pArgCheck.intGE -- (n, v, min)
uiShared.intGEEval = pArgCheck.intGEEval -- (n, v, min)
uiShared.intRange = pArgCheck.intRange -- (n, v, min, max)
uiShared.intRangeEval = pArgCheck.intRangeEval -- (n, v, min, max)
uiShared.intRangeStatic = pArgCheck.intRangeStatic -- (n, v, min, max)
uiShared.intRangeStaticEval = pArgCheck.intRangeStaticEval -- (n, v, min, max)
uiShared.numberNotNaN = pArgCheck.numberNotNaN -- (n, v)
uiShared.numberNotNaNEval = pArgCheck.numberNotNaNEval -- (n, v)
uiShared.enum = pArgCheck.enum -- (n, v, id, e)
uiShared.enumEval = pArgCheck.enumEval -- (n, v, id, e)
uiShared.notNil = pArgCheck.notNil -- (n, v)
uiShared.notNilNotNaN = pArgCheck.notNilNotNaN -- (n, v)
uiShared.notNilNotFalse = pArgCheck.notNilNotFalse -- (n, v)
uiShared.notNilNotFalseNotNaN = pArgCheck.notNilNotFalseNotNaN -- (n, v)
uiShared.notNaN = pArgCheck.notNaN -- (n, v)


function uiShared.loveType(n, obj, typ)
	if obj:type() ~= typ then
		error("argument #" .. n .. ": bad LÖVE object type (expected " .. typ .. ", got " .. obj:type() .. ")", 2)
	end
end


function uiShared.loveTypeEval(n, obj, typ)
	if obj and obj:type() ~= typ then
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


function uiShared.attachFields(src, dst, force)
	for k, v in pairs(src) do
		if not force and dst[k] then
			error("attempted to overwrite an existing field: " .. tostring(k))
		end
		dst[k] = v
	end
end


-- * / Type Utilities *


return uiShared
