-- PILE Table v1.1.5 (Modified)
-- (C) 2024 - 2025 PILE Contributors
-- License: MIT or MIT-0
-- https://github.com/rabbitboots/pile_base


local M = {}


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


M.lang = {}
local lang = M.lang


local interp = require(PATH .. "pile_interp")


local ipairs, pairs, rawget, select, table, type = ipairs, pairs, rawget, select, table, type


function M.clear(t)
	for k in pairs(t) do
		t[k] = nil
	end
end


function M.clearArray(t)
	for i = #t, 1, -1 do
		t[i] = nil
	end
end


function M.copy(t)
	local b = {}
	for k, v in pairs(t) do
		b[k] = v
	end
	return b
end


function M.copyArray(t)
	local b = {}
	for i, v in ipairs(t) do
		b[i] = v
	end
	return b
end


local _deepCopy1, _deepCopy2


lang.err_deep_key = "cannot copy tables as keys"
_deepCopy2 = function(dst, k, v)
	if type(k) == "table" then
		error(lang.err_deep_key)
	end
	if dst[k] == nil then
		dst[k] = type(v) == "table" and _deepCopy1({}, v) or v
	end
end


_deepCopy1 = function(dst, src)
	for i, v in ipairs(src) do
		_deepCopy2(dst, i, v)
	end
	for k, v in pairs(src) do
		_deepCopy2(dst, k, v)
	end
	return dst
end


function M.deepCopy(t)
	return _deepCopy1({}, t)
end


function M.isArray(t)
	local c = 0
	for k, v in pairs(t) do
		if type(k) == "number" and math.floor(k) == k and k >= 1 then
			if k > #t then
				return false
			end
			c = c + 1
		end
	end
	return c == #t
end


function M.isArrayOnly(t)
	local c = 0
	for k, v in pairs(t) do
		if type(k) ~= "number" or math.floor(k) ~= k or k < 1 or k > #t then
			return false
		end
		c = c + 1
	end
	return c == #t
end


function M.isArrayOnlyZero(t)
	local c = 0
	for k, v in pairs(t) do
		if type(k) ~= "number" or math.floor(k) ~= k or k < 0 or k > #t then
			return false
		end
		if k ~= 0 then
			c = c + 1
		end
	end
	return c == #t
end


function M.makeLUT(t)
	local lut = {}
	for i, v in ipairs(t) do
		lut[v] = true
	end
	return lut
end


function M.makeLUTV(...)
	local lut = {}
	for i = 1, select("#", ...) do
		lut[select(i, ...)] = true
	end
	return lut
end


lang.err_dupe = "duplicate values in source table"
function M.invertLUT(t)
	local lut = {}
	for k, v in pairs(t) do
		if lut[v] then
			error(lang.err_dupe)
		end
		lut[v] = k
	end
	return lut
end


function M.arrayOfHashKeys(t)
	local a = {}
	for k in pairs(t) do
		a[#a + 1] = k
	end
	return a
end


lang.err_i_empty = "table element at index 'i' is nil"
lang.err_j_empty = "table element at index 'j' is nil"
function M.moveElement(t, i, j)
	if t[i] == nil then error(lang.err_i_empty)
	elseif t[j] == nil then error(lang.err_j_empty) end

	if i ~= j then
		table.insert(t, j, table.remove(t, i))
	end
end


function M.swapElements(t, i, j)
	if t[i] == nil then error(lang.err_i_empty)
	elseif t[j] == nil then error(lang.err_j_empty) end

	t[i], t[j] = t[j], t[i]
end


function M.reverseArray(t)
	local n = #t
	if n > 1 then
		for i = 1, math.floor(n/2) do
			t[i], t[n - i + 1] = t[n - i + 1], t[i]
		end
	end
end


function M.removeElement(t, v, n)
	n = n or math.huge
	local c = 0
	for i = #t, 1, -1 do
		if c >= n then
			break

		elseif rawget(t, i) == v then
			table.remove(t, i)
			c = c + 1
		end
	end
	return c
end


lang.err_k_nil = "the key to assign is nil"
function M.assignIfNil(t, k, ...)
	if k == nil then
		error(lang.err_k_nil)
	end
	if t[k] == nil then
		for i = 1, select("#", ...) do
			local v = select(i, ...)
			if v ~= nil then
				t[k] = v
				break
			end
		end
	end
end


function M.assignIfNilOrFalse(t, k, ...)
	if k == nil then
		error(lang.err_k_nil)
	end
	if not t[k] then
		for i = 1, select("#", ...) do
			local v = select(i, ...)
			if v then
				t[k] = v
				break
			end
		end
	end
end


lang.err_res_bad_t = "argument #$1: expected a table"
lang.err_res_bad_s = "argument #$1: expected a non-empty string"
function M.resolve(t, sep, str, raw)
	if type(t) ~= "table" then
		error(interp(lang.err_res_bad_t, 1))

	elseif type(sep) ~= "string" or #sep == 0 then
		error(interp(lang.err_res_bad_s, 2))

	elseif type(str) ~= "string" or #str == 0 then
		error(interp(lang.err_res_bad_s, 3))
	end

	local val = t
	local i, j, count, len = 0, 0, 0, #str
	while i <= len do
		if type(val) ~= "table" then
			return nil, count
		end

		j = str:find(sep, i + 1, true) or #str + 1
		local fld = str:sub(i, j - 1)
		if raw then
			val = rawget(val, fld)
		else
			val = val[fld]
		end

		i = j + 1
		count = count + 1
	end

	return val, count
end


lang.err_res_assert = "value resolution failed. String: $1, failed at token #$2."
function M.assertResolve(t, sep, str, raw)
	local ret, count = M.resolve(t, sep, str, raw)
	if ret == nil then
		error(interp(lang.err_res_assert, str, count))
	end
	return ret, count
end


return M
