-- PILE Table v1.201
-- (C) 2024 - 2025 PILE Contributors
-- License: MIT or MIT-0
-- https://github.com/frank-f-trafton/pile_base


local M = {}


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


M.lang = {}
local lang = M.lang


local interp = require(PATH .. "pile_interp")
local pArg = require(PATH .. "pile_arg_check")


local ipairs, math, pairs, rawget, rawset, select, table, type = ipairs, math, pairs, rawget, rawset, select, table, type


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


local _deepCopy1
lang.err_deepcopy_key = "cannot copy tables as keys"
local function _deepCopy2(dst, k, v)
	if type(k) == "table" then
		error(lang.err_deepcopy_key)

	elseif dst[k] == nil then
		dst[k] = type(v) == "table" and _deepCopy1({}, v) or v
	end
end


_deepCopy1 = function(dst, src)
	for i, v in ipairs(src) do -- do array keys first
		_deepCopy2(dst, i, v)
	end
	for k, v in pairs(src) do
		_deepCopy2(dst, k, v)
	end
	return dst
end


function M.deepCopy(t)
	pArg.type1(1, t, "table")

	return _deepCopy1({}, t)
end


local deepPatch1
lang.err_deeppatch_key = "cannot patch tables as keys"
local function deepPatch2(t, k, v, overwrite)
	if type(k) == "table" then
		error(lang.err_deeppatch_key)

	elseif type(v) == "table" then
		local tk = rawget(t, k)
		if tk == nil or (overwrite and type(tk) ~= "table") then
			rawset(t, k, {})
		end
		if type(rawget(t, k)) == "table" then
			deepPatch1(rawget(t, k), v, overwrite)
		end

	elseif overwrite or t[k] == nil then
		rawset(t, k, v)
	end
end


deepPatch1 = function(a, b, overwrite)
	for i, v in ipairs(b) do
		deepPatch2(a, i, v, overwrite)
	end
	local n = #b
	for k, v in pairs(b) do
		if type(k) ~= "number" or math.floor(k) ~= k or k < 1 or k > n then
			deepPatch2(a, k, v, overwrite)
		end
	end
end


lang.err_dp_dupes = "duplicate table references in destination and patch"
function M.deepPatch(a, b, overwrite)
	pArg.type1(1, a, "table")
	pArg.type1(2, b, "table")

	if M.hasAnyDuplicateTables(a, b) then
		error(lang.err_dp_dupes)
	end

	return deepPatch1(a, b, overwrite)
end


local _hash = {}
local hasDupes1
local function hasDupes2(v, _d)
	if type(v) == "table" then
		if _hash[v] then
			return v
		end
		_hash[v] = true
		local ret = hasDupes1(v, _d + 1)
		if ret then
			return ret
		end
	end
end


hasDupes1 = function(t, _d)
	for k, v in pairs(t) do
		local ret = hasDupes2(k, _d + 1) or hasDupes2(v, _d + 1)
		if ret then
			return ret
		end
	end
end


lang.err_dupes_zero_args = "no arguments provided."
function M.hasAnyDuplicateTables(...)
	local ret
	M.clear(_hash)
	local n = select("#", ...)
	if n < 1 then
		error(lang.err_dupes_zero_args)
	end
	for i = 1, select("#", ...) do
		local t = select(i, ...)
		pArg.type1(i, t, "table")
		if _hash[t] then
			M.clear(_hash)
			return t
		end
		_hash[t] = true
		ret = hasDupes1(t, 1)
		if ret then
			break
		end
	end
	M.clear(_hash)
	return ret
end


local function _patch2(t, k, v, overwrite)
	local rg = rawget(t, k)
	if overwrite or rg == nil then
		rawset(t, k, v)
	end
	return rg and 1 or 0
end


function M.patch(a, b, overwrite)
	pArg.type1(1, a, "table")
	pArg.type1(2, b, "table")

	local c = 0
	for i, v in ipairs(b) do
		c = c + _patch2(a, i, v, overwrite)
	end
	local n = #b
	for k, v in pairs(b) do
		if type(k) ~= "number" or math.floor(k) ~= k or k < 1 or k > n then
			c = c + _patch2(a, k, v, overwrite)
		end
	end
	return c
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


function M.valueInArray(t, v, i)
	for p = i or 1, #t do
		if t[p] == v then
			return p
		end
	end
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


lang.err_res_bad_s = "argument #$1: expected a non-empty string"
lang.err_res_field_empty = "cannot resolve an empty field"
function M.resolve(t, str, raw)
	pArg.type1(1, t, "table")
	if type(str) ~= "string" or #str == 0 then
		error(interp(lang.err_res_bad_s, 2))
	end

	local val = t
	local i, j, count, len = 1, 1, 0, #str
	while i <= len do
		if type(val) ~= "table" then
			return nil, count
		end
		local fld
		i, j, fld = str:find(count == 0 and "^([^/]+)" or "^/([^/]+)", i)
		if not fld then
			error(lang.err_res_field_empty)
		end
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
function M.assertResolve(t, str, raw)
	local ret, count = M.resolve(t, str, raw)
	if ret == nil then
		error(interp(lang.err_res_assert, str, count))
	end
	return ret, count
end


lang.undeclared = "undeclared field: '$1'"
M.mt_restrict = {
	__index = function(t, k)
		error(interp(lang.undeclared, k))
	end,

	__newindex = function(t, k, v)
		error(interp(lang.undeclared, k))
	end
}


return M
