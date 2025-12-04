-- PILE Hook v2.000 (modified)
-- (C) 2024 - 2025 PILE Contributors
-- License: MIT
-- https://github.com/frank-f-trafton/pile_base


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
