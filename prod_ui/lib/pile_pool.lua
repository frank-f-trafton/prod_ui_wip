-- PILE Pool v2.011
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


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local pAssert = require(PATH .. "pile_assert")


local _mt_pool = {}
_mt_pool.__index = _mt_pool
M._mt_pool = _mt_pool


local table = table


function M.new(popping, pushing, threshold)
	pAssert.typeEval(1, popping, "function")
	pAssert.typeEval(2, pushing, "function")
	pAssert.numberNotNaNEval(3, threshold)

	return setmetatable({
		popping = popping or nil,
		pushing = pushing or nil,
		threshold = threshold or 0,
		stack = {},
		c = 0,
	}, _mt_pool)
end


function _mt_pool:pop()
	local stack, len, r = self.stack, self.c
	r, stack[len] = stack[len], nil
	if self.c > 0 then
		self.c = len - 1
	end
	local popping = self.popping
	if popping then
		r = popping(r)
	end

	return r
end


function _mt_pool:push(r)
	local pushing = self.pushing
	if pushing then
		r = pushing(r)
	end
	local len = self.c
	if len < self.threshold then
		self.stack[len + 1], self.c = r, self.c + 1
	end
end


function _mt_pool:setThreshold(threshold)
	pAssert.numberNotNaNEval(1, threshold)

	self.threshold = threshold
	self:reduceStack(threshold)
end


function _mt_pool:getThreshold()
	return self.threshold
end


function _mt_pool:reduceStack(n)
	pAssert.numberNotNaNEval(1, n)

	n = n and math.max(0, n) or 0
	for i = #self.stack, n + 1, -1 do
		self:pop()
		if i > self.threshold then
			self.stack[i] = nil
		end
	end
end


return M
