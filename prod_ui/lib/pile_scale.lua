-- PILE Scale v2.010
-- https://github.com/frank-f-trafton/pile_base


--[[
MIT License

Copyright (c) 2024 - 2025 PILE Contributors

PILE Base uses code from these libraries:

PILE Tree:
  LUIGI
  Copyright (c) 2015 airstruck
  License: MIT
  https://github.com/airstruck/luigi


Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]


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
