-- PILE Hook v2.010
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


local function _callHooks(hl, ...)
	if not hl[0] or hl[0](...) then
		for i = 1, #hl do
			local a,b,c,d = hl[i](...)
			if a ~= nil then
				return a,b,c,d
			end
		end
	end
end


local function _callHooksBack(hl, ...)
	if not hl[0] or hl[0](...) then
		for i = #hl, 1, -1 do
			local a,b,c,d = hl[i](...)
			if a ~= nil then
				return a,b,c,d
			end
		end
	end
end


local _mt_hooks = {__call = _callHooks}
_mt_hooks.__index = _mt_hooks


local _mt_hooks_back = {__call = _callHooksBack}
_mt_hooks_back.__index = _mt_hooks_back


function M.newHookList(back, filter)
	pAssert.typeEval(2, filter, "function")

	local hl = setmetatable({}, back and _mt_hooks_back or _mt_hooks)

	if filter then
		hl[0] = filter
	end

	return hl
end


M.callHooks = _callHooks
M.callHooksBack = _callHooksBack


function M.wrap(hl)
	pAssert.type(1, hl, "table")

	return function(...)
		return hl(...)
	end
end


return M
