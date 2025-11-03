local uiAssert = {}


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local pAssert = require(PATH .. "lib.pile_assert")
local pName = require(PATH .. "lib.pile_name")
local uiTable = require(PATH .. "ui_table")


uiTable.patch(uiAssert, pAssert)


local _n = uiAssert._n


function uiAssert.loveType(n, v, e)
	if type(v) ~= "userdata" then
		error(_n(n) .. "expected LÖVE object (userdata), got " .. type(v), 2)

	elseif v:type() ~= e then
		error(_n(n) .. "bad LÖVE type (expected " .. e .. ", got " .. v:type(), 2)
	end
end


function uiAssert.loveTypeEval(n, v, e)
	if v then
		if type(v) ~= "userdata" then
			error(_n(n) .. "expected false/nil or LÖVE object (userdata), got " .. type(v), 2)

		elseif v:type() ~= e then
			error(_n(n) .. "expected false/nil or LÖVE type " .. e .. ", got " .. v:type(), 2)
		end
	end
end


function uiAssert.loveTypes(n, v, ...)
	if type(v) ~= "userdata" then
		error(_n(n) .. "expected LÖVE object (userdata), got " .. type(v) .. ")", 2)
	end
	local v_typ = v:type()
	for i = 1, select("#", ...) do
		if v_typ == select(i, ...) then
			return
		end
	end

	error(_n(n) .. "bad LÖVE type (expected [" .. table.concat(e, ", ") .. "], got " .. v:type() .. ")", 2)
end


function uiAssert.loveTypesEval(n, v, ...)
	if v then
		if type(v) ~= "userdata" then
			error(_n(n) .. "expected LÖVE object (userdata), got " .. type(v) .. ")", 2)
		end
		local v_typ = v:type()
		for i = 1, select("#", ...) do
			if v_typ == select(i, ...) then
				return
			end
		end

		error(_n(n) .. "bad LÖVE type (expected false/nil or [" .. table.concat(e, ", ") .. "], got " .. v:type() .. ")", 2)
	end
end


function uiAssert.loveTypeOf(n, v, e)
	if type(v) ~= "userdata" then
		error(_n(n) .. "expected LÖVE object (userdata), got " .. type(v) .. ")", 2)

	elseif not v:typeOf(e) then
		error(_n(n) .. "expected LÖVE object type '" .. e .. "' in class hierarchy", 2)
	end
end


local function _colorOK(v)
	local count = 0
	if type(v) == "table" and #v >= 3 and #v <= 4 then
		for i, c in ipairs(v) do
			if type(c) == "number" then
				count = count + 1
			end
		end
	end
	return not (count < 3)
end


-- Color tables, in the form of {1, 1, 1} (RGB) or {1, 1, 1, 1} (RGBA)
function uiAssert.loveColorTuple(n, v)
	if not _colorOK(v) then
		error(_n(n) .. "bad color (array of 3-4 numbers)", 2)
	end
end


function uiAssert.loveColorTupleEval(n, v)
	if v and not _colorOK(v) then
		error(_n(n) .. "bad color (array of 3-4 numbers)", 2)
	end
end


-- Strings, or arrays of strings and LÖVE color tables
function uiAssert.loveStringOrColoredText(n, v)
	if type(v) ~= "string" and type(v) ~= "table" then
		error(_n(n) .. "bad type (expected text (string or table), got " .. type(v), 2)
	end
end


-- Checking widgets: use 'context:assertWidget(wid)'


return uiAssert
