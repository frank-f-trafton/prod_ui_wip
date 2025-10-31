local uiScale = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local uiAssert = require(REQ_PATH .. "ui_assert")


function uiScale.number(scale, v, min, max)
	uiAssert.type(1, scale, "number")
	uiAssert.int(2, v)
	uiAssert.typeEval(3, min, "number")
	uiAssert.typeEval(4, max, "number")

	min, max = min or -math.huge, max or math.huge

	return math.max(min, math.min(v * scale, max))
end


function uiScale.integer(scale, v, min, max)
	uiAssert.type(1, scale, "number")
	uiAssert.int(2, v)
	uiAssert.typeEval(3, min, "number")
	uiAssert.typeEval(4, max, "number")

	min, max = min or -math.huge, max or math.huge

	return math.floor(math.max(min, math.min(v * scale, max)))
end


function uiScale.fieldNumber(scale, t, k, min, max)
	uiAssert.type(1, scale, "number")
	uiAssert.type(2, t, "table")
	-- don't assert 'k'
	uiAssert.typeEval(4, min, "number")
	uiAssert.typeEval(5, max, "number")

	local v = t[k]
	uiAssert.type("t[k]", v, "number")

	min, max = min or -math.huge, max or math.huge

	t[k] = math.max(min, math.min(v * scale, max))
end


function uiScale.fieldInteger(scale, t, k, min, max)
	uiAssert.type(1, scale, "number")
	uiAssert.type(2, t, "table")
	-- don't assert 'k'
	uiAssert.typeEval(4, min, "number")
	uiAssert.typeEval(5, max, "number")

	local v = t[k]
	uiAssert.type("t[k]", v, "number")

	min, max = min or -math.huge, max or math.huge

	t[k] = math.floor(math.max(min, math.min(v * scale, max)))
end


return uiScale
