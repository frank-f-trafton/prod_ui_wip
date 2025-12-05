-- PILE Table v2.011
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


M.lang = {}
local lang = M.lang


local interp = require(PATH .. "pile_interp")
local pAssert = require(PATH .. "pile_assert")
local pName = require(PATH .. "pile_name")


local ipairs, math, pairs, rawget, rawset, select, table, type = ipairs, math, pairs, rawget, rawset, select, table, type


do
	local jit = rawget(_G, "jit")

	if jit then
		M.clearAll = require("table.clear")
	else
		function M.clearAll(t)
			for i = #t, 1, -1 do
				t[i] = nil
			end
			for k in pairs(t) do
				t[k] = nil
			end
		end
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
	pAssert.type(1, t, "table")

	return _deepCopy1({}, t)
end


local function _patch2(t, k, v, overwrite)
	local rg = rawget(t, k)
	if overwrite or rg == nil then
		rawset(t, k, v)
	end
	return rg and 1 or 0
end


function M.patch(a, b, overwrite)
	pAssert.type(1, a, "table")
	pAssert.type(2, b, "table")

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
	pAssert.type(1, a, "table")
	pAssert.type(2, b, "table")

	if M.hasAnyDuplicateTables(a, b) then
		error(lang.err_dp_dupes)
	end

	return deepPatch1(a, b, overwrite)
end


local _hash = {}
local hasDupes1
local function hasDupes2(v)
	if type(v) == "table" then
		if _hash[v] then
			return v
		end
		_hash[v] = true
		local ret = hasDupes1(v)
		if ret then
			return ret
		end
	end
end


hasDupes1 = function(t)
	for k, v in pairs(t) do
		local ret = hasDupes2(k) or hasDupes2(v)
		if ret then
			return ret
		end
	end
end


lang.err_dupes_zero_args = "no arguments provided."
function M.hasAnyDuplicateTables(...)
	local ret
	M.clearAll(_hash)
	local n = select("#", ...)
	if n < 1 then
		error(lang.err_dupes_zero_args)
	end
	for i = 1, n do
		local t = select(i, ...)
		pAssert.type(i, t, "table")
		if _hash[t] then
			M.clearAll(_hash)
			return t
		end
		_hash[t] = true
		ret = hasDupes1(t)
		if ret then
			break
		end
	end
	M.clearAll(_hash)
	return ret
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


function M.arrayHasDuplicateValues(t)
	for j = 1, #t do
		for i = j + 1, #t do
			if t[i] == t[j] then
				return  j, i
			end
		end
	end
end


function M.newLUT(t)
	local lut = {}
	for i, v in ipairs(t) do
		lut[v] = true
	end
	return lut
end


function M.newLUTV(...)
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
	pAssert.type(1, t, "table")
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


function M.wrap1Array(t, n)
	return t[((n - 1) % #t) + 1]
end


function M.safeTableConcat(t, sep, i, j)
	pAssert.type(1, t, "table")
	pAssert.typeEval(2, sep, "string")
	pAssert.typeEval(3, i, "number")
	pAssert.typeEval(4, j, "number")

	local t2, len = {}, 1
	for x = i or 1, j or #t do
		t2[len] = tostring(t[x])
		len = len + 1
	end
	return table.concat(t2, sep or "")
end


function M.newNamedMap(name, t)
	pAssert.typeEval(1, name, "string")
	pAssert.typeEval(2, t, "table")

	t = t or {}
	pName.set(t, name)
	return t
end


function M.newNamedMapV(name, ...)
	return M.newNamedMap(name, M.newLUTV(...))
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
