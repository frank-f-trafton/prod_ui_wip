-- PILE Assert v1.315
-- (C) 2024 - 2025 PILE Contributors
-- License: MIT or MIT-0
-- https://github.com/frank-f-trafton/pile_base


local M = {}


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local interp = require(PATH .. "pile_interp")
local pName = require(PATH .. "pile_name")


local select, table, type = select, table, type


M.lang = {
	argument = "argument #$1: ",
	field = "table '$1', field '$2': "
}
local lang = M.lang


M.L = setmetatable({}, {__mode="kv"})


function M._n(n)
	local typ = type(n)
	return typ == "number" and interp(lang.argument, n)
		or typ == "string" and n .. ": "
		or typ == "table" and interp(lang.field, n[1], n[2])
		or typ == "function" and n() .. ": "
		or ""
end
local _n = M._n


local function _safeConcat(t, sep, i, j)
	local t2 = {}
	for i, v in ipairs(t) do
		t2[i] = tostring(v)
	end
	return table.concat(t2, sep or "", i or 1, j or #t2)
end


lang.type = "bad type (expected $1, got $2)"
function M.type(n, v, e)
	if type(v) ~= e then
		error(_n(n) .. interp(lang.type, e, type(v)), 2)
	end
end


lang.type_eval = "bad type (expected false/nil or $1, got $2)"
function M.typeEval(n, v, e)
	if v and type(v) ~= e then
		error(_n(n) .. interp(lang.type_eval, e, type(v)), 2)
	end
end


lang.types = "bad type (expected [$1], got $2)"
function M.types(n, v, ...)
	local typ = type(v)
	for i = 1, select("#", ...) do
		if typ == select(i, ...) then
			return
		end
	end
	error(_n(n) .. interp(lang.types, table.concat({...}, ", "), typ), 2)
end


lang.types_eval = "bad type (expected false/nil or [$1], got $2)"
function M.typesEval(n, v, ...)
	if v then
		local typ = type(v)
		for i = 1, select("#", ...) do
			if typ == select(i, ...) then
				return
			end
		end
		error(_n(n) .. interp(lang.types_eval, table.concat({...}, ", "), typ), 2)
	end
end


lang.bad_one_of = "expected one of: $1"
function M.oneOf(n, v, ...)
	for i = 1, select("#", ...) do
		if v == select(i, ...) then
			return
		end
	end
	error(_n(n) .. interp(lang.bad_one_of, _safeConcat({...}, ", ")), 2)
end


lang.bad_one_of_eval = "expected false/nil or one of: $1"
function M.oneOfEval(n, v, ...)
	if v then
		for i = 1, select("#", ...) do
			if v == select(i, ...) then
				return
			end
		end
		error(_n(n) .. interp(lang.bad_one_of_eval, _safeConcat({...}, ", ")), 2)
	end
end


lang.num_ge = "expected number greater or equal to $1"
function M.numberGE(n, v, min)
	if type(v) ~= "number" or v < min then
		error(_n(n) .. interp(lang.num_ge, min), 2)
	end
end


lang.num_ge_eval = "expected false/nil or number greater or equal to $1"
function M.numberGEEval(n, v, min)
	if v and (type(v) ~= "number" or v < min) then
		error(_n(n) .. interp(lang.num_ge_eval, min), 2)
	end
end


lang.bad_num_or_one_of = "expected number >= $1 or one of: $2"
function M.numberGEOrOneOf(n, v, min, ...)
	if type(v) == "number" then
		if not min or v >= min then
			return
		end
	else
		for i = 1, select("#", ...) do
			if v == select(i, ...) then
				return
			end
		end
	end
	error(_n(n) .. interp(lang.bad_num_or_one_of, min, _safeConcat({...}, ", ")), 2)
end


lang.num_range_a = "expected number, got $1"
lang.num_range_b = "number is out of range"
function M.numberRange(n, v, min, max)
	if type(v) ~= "number" then error(_n(n) .. interp(lang.int_range_a, type(v)), 2)
	elseif v < min or v > max then error(_n(n) .. lang.int_range_b, 2) end
end


lang.num_range_eval_a = "expected false/nil or number, got $1"
lang.num_range_eval_b = "number is out of range"
function M.numberRangeEval(n, v, min, max)
	if v then
		if type(v) ~= "number" then error(_n(n) .. interp(lang.num_range_eval_a, type(v)), 2)
		elseif v < min or v > max then error(_n(n) .. lang.num_range_eval_b, 2) end
	end
end


lang.int = "expected integer"
function M.integer(n, v)
	if type(v) ~= "number" or math.floor(v) ~= v then
		error(_n(n) .. lang.int, 2)
	end
end


lang.int_eval = "expected false/nil or integer"
function M.integerEval(n, v)
	if v and (type(v) ~= "number" or math.floor(v) ~= v) then
		error(_n(n) .. lang.int_eval, 2)
	end
end


lang.int_ge = "expected integer greater or equal to $1"
function M.integerGE(n, v, min)
	if type(v) ~= "number" or math.floor(v) ~= v or v < min then
		error(_n(n) .. interp(lang.int_ge, min), 2)
	end
end


lang.int_ge_eval = "expected false/nil or integer greater or equal to $1"
function M.integerGEEval(n, v, min)
	if v and (type(v) ~= "number" or math.floor(v) ~= v or v < min) then
		error(_n(n) .. interp(lang.int_ge_eval, min), 2)
	end
end


lang.int_range_a = "expected integer, got $1"
lang.int_range_b = "got non-integer number"
lang.int_range_c = "integer is out of range"
function M.integerRange(n, v, min, max)
	if type(v) ~= "number" then error(_n(n) .. interp(lang.int_range_a, type(v)), 2)
	elseif math.floor(v) ~= v then error(_n(n) .. lang.int_range_b, 2)
	elseif v < min or v > max then error(_n(n) .. lang.int_range_c, 2) end
end


lang.int_range_eval_a = "expected false/nil or integer, got $1"
lang.int_range_eval_b = "got non-integer number"
lang.int_range_eval_c = "integer is out of range"
function M.integerRangeEval(n, v, min, max)
	if v then
		if type(v) ~= "number" then error(_n(n) .. interp(lang.int_range_eval_a, type(v)), 2)
		elseif math.floor(v) ~= v then error(_n(n) .. lang.int_range_eval_b, 2)
		elseif v < min or v > max then error(_n(n) .. lang.int_range_eval_c, 2) end
	end
end


lang.nan_a = "expected non-NaN number, got $1"
lang.nan_b = "expected non-NaN number, got NaN"
function M.numberNotNaN(n, v)
	if type(v) ~= "number" then
		error(_n(n) .. interp(lang.nan_a, type(v)), 2)

	elseif v ~= v then
		error(_n(n) .. lang.nan_b, 2)
	end
end


lang.nan_eval_a = "expected false/nil or non-NaN number, got $1"
lang.nan_eval_b = "expected false/nil or non-NaN number, got NaN"
function M.numberNotNaNEval(n, v)
	if v then
		if type(v) ~= "number" then
			error(_n(n) .. interp(lang.nan_eval_a, type(v)), 2)

		elseif v ~= v then
			error(_n(n) .. lang.nan_eval_b, 2)
		end
	end
end


lang.bad_named_map = "invalid $1"
function M.namedMap(n, v, e)
	if not e[v] then
		error(_n(n) .. interp(lang.bad_named_map, pName.safeGet(e, "NamedMap")), 2)
	end
end


function M.namedMapEval(n, v, e)
	if v and not e[v] then
		error(_n(n) .. interp(lang.bad_named_map, pName.safeGet(e, "NamedMap")), 2)
	end
end


lang.not_nil = "expected non-nil value"
function M.notNil(n, v)
	if v == nil then
		error(_n(n) .. lang.not_nil, 2)
	end
end


lang.not_nil_not_nan_a = "expected non-nil, non-NaN value, got nil"
lang.not_nil_not_nan_b = "expected non-nil, non-NaN value, got NaN"
function M.notNilNotNaN(n, v)
	if v == nil then
		error(_n(n) .. lang.not_nil_not_nan_a, 2)

	elseif v ~= v then
		error(_n(n) .. lang.not_nil_not_nan_b, 2)
	end
end


lang.not_nil_not_false = "expected non-nil, non-false value, got false/nil"
function M.notNilNotFalse(n, v)
	if not v then
		error(_n(n) .. lang.not_nil_not_false, 2)
	end
end


lang.not_nil_not_false_not_nan_a = "expected non-nil, non-false, non-NaN value, got false/nil"
lang.not_nil_not_false_not_nan_b = "expected non-nil, non-false, non-NaN value, got NaN"
function M.notNilNotFalseNotNaN(n, v)
	if not v then
		error(_n(n) .. lang.not_nil_not_false_not_nan_a, 2)

	elseif v ~= v then
		error(_n(n) .. lang.not_nil_not_false_not_nan_b, 2)
	end
end


lang.not_nan = "expected non-NaN value"
function M.notNaN(n, v)
	if v ~= v then
		error(_n(n) .. lang.not_nan, 2)
	end
end


lang.mt_bad_t = "expected table"
lang.mt_bad_mt = "expected table to have a metatable"
lang.mt_bad_match = "expected metatable for: $1"
function M.tableHasThisMetatable(n, v, mt)
	if type(v) ~= "table" then
		error(_n(n) .. lang.mt_bad_t, 2)
	end
	local this_mt = getmetatable(v)
	if not this_mt then
		error(_n(n) .. lang.mt_bad_mt, 2)
	end
	if this_mt ~= mt then
		error(_n(n) .. interp(lang.mt_bad_match, pName.safeGet(mt)), 2)
	end
end


lang.expect_no_mt = "expected a table without an assigned metatable"
function M.tableWithoutMetatable(n, v)
	if type(v) ~= "table" or getmetatable(v) then
		error(_n(n) .. lang.expect_no_mt, 2)
	end
end


lang.fail_default = "error!"
function M.fail(n, v, err)
	error(_n(n) .. tostring(err) or lang.fail_default, 2)
end


function M.pass()
	-- n/a
end


function M.assert(n, v, err)
	if not v then
		error(_n(n) .. tostring(err) or lang.fail_default, 2)
	end
end


return M
