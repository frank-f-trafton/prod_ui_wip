-- PILE Scale v1.315
-- (C) 2025 PILE Contributors
-- License: MIT or MIT-0
-- https://github.com/frank-f-trafton/pile_base


local M = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local pAssert = require(REQ_PATH .. "pile_assert")


function M.number(scale, v, min, max)
	pAssert.numberNotNaN(1, scale)
	pAssert.numberNotNaN(2, v)
	pAssert.numberNotNaNEval(3, min)
	pAssert.numberNotNaNEval(4, max)

	min, max = min or -math.huge, max or math.huge

	return math.max(min, math.min(v * scale, max))
end


function M.integer(scale, v, min, max)
	pAssert.numberNotNaN(1, scale)
	pAssert.numberNotNaN(2, v)
	pAssert.numberNotNaNEval(3, min)
	pAssert.numberNotNaNEval(4, max)

	min, max = min or -math.huge, max or math.huge

	return math.floor(math.max(min, math.min(v * scale, max)))
end


function M.fieldNumber(scale, t, k, min, max)
	pAssert.numberNotNaN(1, scale)
	pAssert.type(2, t, "table")
	-- don't assert 'k'
	pAssert.numberNotNaNEval(4, min)
	pAssert.numberNotNaNEval(5, max)

	local v = t[k]
	pAssert.numberNotNaN("t[k]", v)

	min, max = min or -math.huge, max or math.huge

	t[k] = math.max(min, math.min(v * scale, max))
end


function M.fieldInteger(scale, t, k, min, max)
	pAssert.numberNotNaN(1, scale)
	pAssert.type(2, t, "table")
	-- don't assert 'k'
	pAssert.numberNotNaNEval(4, min)
	pAssert.numberNotNaNEval(5, max)

	local v = t[k]
	pAssert.numberNotNaN("t[k]", v)

	min, max = min or -math.huge, max or math.huge

	t[k] = math.floor(math.max(min, math.min(v * scale, max)))
end


return M
