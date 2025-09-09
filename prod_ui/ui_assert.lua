local uiAssert = {}


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local pArgCheck = require(PATH .. "lib.pile_arg_check")
local pTable = require(PATH .. "lib.pile_table")


pTable.patch(uiAssert, pArgCheck)


function uiAssert.loveType(n, obj, typ)
	if obj:type() ~= typ then
		error("argument #" .. n .. ": bad LÖVE object type (expected " .. typ .. ", got " .. obj:type() .. ")", 2)
	end
end


function uiAssert.loveTypeEval(n, obj, typ)
	if obj and obj:type() ~= typ then
		error("argument #" .. n .. ": bad LÖVE object type (expected " .. typ .. ", got " .. obj:type() .. ")", 2)
	end
end



function uiAssert.loveTypeOf(n, obj, typ)
	if not obj:typeOf(typ) then
		error("argument #" .. n .. ": expected LÖVE object type '" .. typ .. "' in class hierarchy", 2)
	end
end


--- Argument is a string or coloredtext sequence.
function uiAssert.assertText(n, text)
	if type(text) ~= "string" and type(text) ~= "table" then
		error("argument #" .. n .. ": bad type (expected text (string or table), got " .. type(text), 2)
	end
end


return uiAssert
