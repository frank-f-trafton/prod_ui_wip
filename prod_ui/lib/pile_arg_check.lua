-- PILE argCheck v1.300
-- (C) 2024 - 2025 PILE Contributors
-- License: MIT or MIT-0
-- https://github.com/frank-f-trafton/pile_base


local M = {}


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local interp = require(PATH .. "pile_interp")


local select, table, type = select, table, type


M.lang = {
	argument = "argument #$1: ",
	field = "table '$1', field '$2': "
}
local lang = M.lang


M.L = setmetatable({}, {__mode="kv"})


local function _n(n)
	return type(n) == "number" and interp(lang.argument, n)
		or type(n) == "string" and n .. ": "
		or type(n) == "table" and interp(lang.field, n[1], n[2])
		or ""
end


lang.type = "bad type (expected [$1], got $2)"
function M.type(n, v, ...)
	local typ = type(v)
	for i = 1, select("#", ...) do
		if typ == select(i, ...) then
			return
		end
	end
	error(_n(n) .. interp(lang.type, table.concat({...}, ", "), typ), 2)
end


lang.type_eval = "bad type (expected false/nil or [$1], got $2)"
function M.typeEval(n, v, ...)
	if v then
		local typ = type(v)
		for i = 1, select("#", ...) do
			if typ == select(i, ...) then
				return
			end
		end
		error(_n(n) .. interp(lang.type_eval, table.concat({...}, ", "), typ), 2)
	end
end


lang.type1 = "bad type (expected $1, got $2)"
function M.type1(n, v, e)
	if type(v) ~= e then
		error(_n(n) .. interp(lang.type1, e, type(v)), 2)
	end
end


lang.type_eval1 = "bad type (expected false/nil or $1, got $2)"
function M.typeEval1(n, v, e)
	if v and type(v) ~= e then
		error(_n(n) .. interp(lang.type_eval1, e, type(v)), 2)
	end
end


lang.int = "expected integer"
function M.int(n, v)
	if type(v) ~= "number" or math.floor(v) ~= v then
		error(_n(n) .. lang.int, 2)
	end
end


lang.int_eval = "expected false/nil or integer"
function M.intEval(n, v)
	if v and (type(v) ~= "number" or math.floor(v) ~= v) then
		error(_n(n) .. lang.int_eval, 2)
	end
end


lang.int_ge = "expected integer greater or equal to $1"
function M.intGE(n, v, min)
	if type(v) ~= "number" or math.floor(v) ~= v or v < min then
		error(_n(n) .. interp(lang.int_ge, min), 2)
	end
end


lang.int_ge_eval = "expected false/nil or integer greater or equal to $1"
function M.intGEEval(n, v, min)
	if v and (type(v) ~= "number" or math.floor(v) ~= v or v < min) then
		error(_n(n) .. interp(lang.int_ge_eval, min), 2)
	end
end


lang.int_range_a = "expected integer, got $1"
lang.int_range_b = "got non-integer number"
lang.int_range_c = "integer is out of range"
function M.intRange(n, v, min, max)
	if type(v) ~= "number" then error(_n(n) .. interp(lang.int_range_a, type(v)), 2)
	elseif math.floor(v) ~= v then error(_n(n) .. lang.int_range_b, 2)
	elseif v < min or v > max then error(_n(n) .. lang.int_range_c, 2) end
end


lang.int_range_eval_a = "expected false/nil or integer, got $1"
lang.int_range_eval_b = "got non-integer number"
lang.int_range_eval_c = "integer is out of range"
function M.intRangeEval(n, v, min, max)
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


lang.bad_enum = "invalid $1"
function M.enum(n, v, e)
	if not e[v] then
		error(_n(n) .. interp(lang.bad_enum, e:getName()), 2)
	end
end


function M.enumEval(n, v, e)
	if v and not e[v] then
		error(_n(n) .. interp(lang.bad_enum, e:getName()), 2)
	end
end


lang.bad_one_of = "invalid $1"
function M.oneOf(n, v, id, ...)
	for i = 1, select("#", ...) do
		if v == select(i, ...) then
			return
		end
	end
	error(_n(n) .. interp(lang.bad_one_of, id), 2)
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


return M
