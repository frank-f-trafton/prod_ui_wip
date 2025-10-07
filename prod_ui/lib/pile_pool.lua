-- PILE Pool v1.202 (Beta)
-- (C) 2024 - 2025 PILE Contributors
-- License: MIT or MIT-0
-- https://github.com/frank-f-trafton/pile_base


--[[
This module is experimental. Testing is required to determine if pooling tables and LÖVE C++ objects
would be worthwhile.

Initial benchmarks with Lua 5.1 suggest that in most cases, one would be better off just creating new
tables. (Can I remove some more overhead here?)

LuaJIT with compilation is promising, but simple tests can be deceptive due to how the JIT
process works. A real test will require integration with a more complete ProdUI.

Of course, there is also the trade-off of potentially introducing manual memory management troubles to
a LÖVE game/app...
--]]


local M = {}


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local pArg = require(PATH .. "pile_arg_check")


local _mt_pool = {}
_mt_pool.__index = _mt_pool
M._mt_pool = _mt_pool


local table = table


function M.new(popping, pushing, threshold)
	pArg.typeEval1(1, popping, "function")
	pArg.typeEval1(2, pushing, "function")
	pArg.numberNotNaNEval(3, threshold)

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
	pArg.numberNotNaNEval(1, threshold)

	self.threshold = threshold
	self:reduceStack(threshold)
end


function _mt_pool:getThreshold()
	return self.threshold
end


function _mt_pool:reduceStack(n)
	pArg.numberNotNaNEval(1, n)

	n = n and math.max(0, n) or 0
	for i = #self.stack, n + 1, -1 do
		self:pop()
		if i > self.threshold then
			self.stack[i] = nil
		end
	end
end


return M
