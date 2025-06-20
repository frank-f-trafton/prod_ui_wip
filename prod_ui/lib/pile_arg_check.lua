-- PILE argCheck v1.1.6
-- (C) 2024 - 2025 PILE Contributors
-- License: MIT or MIT-0
-- https://github.com/rabbitboots/pile_base


local M = {}


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local interp = require(PATH .. "pile_interp")


local select, table, type = select, table, type


M.lang = {}
local lang = M.lang


lang.type = "argument #$1: bad type (expected [$2], got $3)"
function M.type(n, v, ...)
	local typ = type(v)
	for i = 1, select("#", ...) do
		if typ == select(i, ...) then
			return
		end
	end
	error(interp(lang.type, n, table.concat({...}, ", "), typ), 2)
end


lang.type_eval = "argument #$1: bad type (expected false/nil or [$2], got $3)"
function M.typeEval(n, v, ...)
	if v then
		local typ = type(v)
		for i = 1, select("#", ...) do
			if typ == select(i, ...) then
				return
			end
		end
		error(interp(lang.type_eval, n, table.concat({...}, ", "), typ), 2)
	end
end


lang.type1 = "argument #$1: bad type (expected $2, got $3)"
function M.type1(n, v, e)
	if type(v) ~= e then
		error(interp(lang.type1, n, e, type(v)), 2)
	end
end


lang.type_eval1 = "argument #$1: bad type (expected false/nil or $2, got $3)"
function M.typeEval1(n, v, e)
	if v and type(v) ~= e then
		error(interp(lang.type_eval1, n, e, type(v)), 2)
	end
end


lang.field_type = "argument #$1, field '$2': invalid type (expected [$3], got $4)"
function M.fieldType(n, t, id, ...)
	local typ = type(t[id])
	for i = 1, select("#", ...) do
		if typ == select(i, ...) then
			return
		end
	end
	error(interp(lang.field_type, n, id, table.concat({...}, ", "), typ), 2)
end


lang.field_type_eval = "argument #$1, field '$2': bad type (expected false/nil or [$3], got $4)"
function M.fieldTypeEval(n, t, id, ...)
	local v = t[id]
	if v then
		local typ = type(v)
		for i = 1, select("#", ...) do
			if typ == select(i, ...) then
				return
			end
		end
		error(interp(lang.field_type_eval, n, id, table.concat({...}, ", "), typ), 2)
	end
end


lang.field_type1 = "argument #$1, field '$2': invalid type (expected $3, got $4)"
function M.fieldType1(n, t, id, e)
	if type(t[id]) ~= e then
		error(interp(lang.field_type1, n, id, e, type(t[id])), 2)
	end
end


lang.field_type_eval1 = "argument #$1, field '$2': invalid type (expected false/nil or $3, got $4)"
function M.fieldTypeEval1(n, t, id, e)
	local v = t[id]
	if v and type(v) ~= e then
		error(interp(lang.field_type_eval1, n, id, e, type(v)), 2)
	end
end


lang.int = "argument #$1: expected integer"
function M.int(n, v)
	if type(v) ~= "number" or math.floor(v) ~= v or v ~= v then
		error(interp(lang.int, n), 2)
	end
end


lang.int_eval = "argument #$1: expected false/nil or integer"
function M.intEval(n, v)
	if v and (type(v) ~= "number" or math.floor(v) ~= v or v ~= v) then
		error(interp(lang.int_eval, n), 2)
	end
end


lang.int_ge = "argument #$1: expected integer greater or equal to $2"
function M.intGE(n, v, min)
	if type(v) ~= "number" or math.floor(v) ~= v or v < min or v ~= v then
		error(interp(lang.int_ge, n, min), 2)
	end
end


lang.int_ge_eval = "argument #$1: expected false/nil or integer greater or equal to $2"
function M.intGEEval(n, v, min)
	if v and (type(v) ~= "number" or math.floor(v) ~= v or v < min or v ~= v) then
		error(interp(lang.int_ge_eval, n, min), 2)
	end
end


lang.int_range_a = "argument #$1: expected integer, got $2"
lang.int_range_b = "argument #$1: got non-integer number"
lang.int_range_c = "argument #$1: integer is out of range"
function M.intRange(n, v, min, max)
	if type(v) ~= "number" then error(interp(lang.int_range_a, n, type(v)), 2)
	elseif math.floor(v) ~= v then error(interp(lang.int_range_b, n), 2)
	elseif v < min or v > max or v ~= v then error(interp(lang.int_range_c, n), 2) end
end


lang.int_range_eval_a = "argument #$1: expected false/nil or integer, got $2"
lang.int_range_eval_b = "argument #$1: got non-integer number"
lang.int_range_eval_c = "argument #$1: integer is out of range"
function M.intRangeEval(n, v, min, max)
	if v then
		if type(v) ~= "number" then error(interp(lang.int_range_eval_a, n, type(v)), 2)
		elseif math.floor(v) ~= v then error(interp(lang.int_range_eval_b, n), 2)
		elseif v < min or v > max or v ~= v then error(interp(lang.int_range_eval_c, n), 2) end
	end
end


lang.int_range_static_a = "argument #$1: expected integer, got $2"
lang.int_range_static_b = "argument #$1: got non-integer number"
lang.int_range_static_c = "argument #$1: integer is out of range ($2 - $3)"
function M.intRangeStatic(n, v, min, max)
	if type(v) ~= "number" then error(interp(lang.int_range_static_a, n, type(v)), 2)
	elseif math.floor(v) ~= v then error(interp(lang.int_range_static_b, n), 2)
	elseif v < min or v > max or v ~= v then error(interp(lang.int_range_static_c, n, min, max), 2) end
end


lang.int_range_static_eval_a = "argument #$1: expected false/nil or integer, got $2"
lang.int_range_static_eval_b = "argument #$1: got non-integer number"
lang.int_range_static_eval_c = "argument #$1: integer is out of range ($2 - $3)"
function M.intRangeStaticEval(n, v, min, max)
	if v then
		if type(v) ~= "number" then error(interp(lang.int_range_static_eval_a, n, type(v)), 2)
		elseif math.floor(v) ~= v then error(interp(lang.int_range_static_eval_b, n), 2)
		elseif v < min or v > max or v ~= v then error(interp(lang.int_range_static_eval_c, n, min, max), 2) end
	end
end


lang.nan_a = "argument #$1: expected non-NaN number, got $2"
lang.nan_b = "argument #$1: expected non-NaN number, got NaN"
function M.numberNotNaN(n, v)
	if type(v) ~= "number" then
		error(interp(lang.nan_a, n, type(v)), 2)

	elseif v ~= v then
		error(interp(lang.nan_b, n), 2)
	end
end


lang.nan_eval_a = "argument #$1: expected false/nil or non-NaN number, got $2"
lang.nan_eval_b = "argument #$1: expected false/nil or non-NaN number, got NaN"
function M.numberNotNaNEval(n, v)
	if v then
		if type(v) ~= "number" then
			error(interp(lang.nan_eval_a, n, type(v)), 2)

		elseif v ~= v then
			error(interp(lang.nan_eval_b, n), 2)
		end
	end
end


lang.enum_a = "argument #$1: invalid $2 (got '$3')"
lang.enum_b = "argument #$1: invalid $2 (got non-number, non-string value)"
local function _enumErr(v) return (type(v) == "string" or type(v) == "number") and lang.enum_a or lang.enum_b end
function M.enum(n, v, id, e)
	if not e[v] then
		error(interp(_enumErr(v), n, id, v), 2)
	end
end
function M.enumEval(n, v, id, e)
	if v and not e[v] then
		error(interp(_enumErr(v), n, id, v), 2)
	end
end


lang.not_nil = "argument #$1: expected non-nil value"
function M.notNil(n, v)
	if v == nil then
		error(interp(lang.not_nil, n), 2)
	end
end


lang.not_nil_not_nan_a = "argument #$1: expected non-nil, non-NaN value, got nil"
lang.not_nil_not_nan_b = "argument #$1: expected non-nil, non-NaN value, got NaN"
function M.notNilNotNaN(n, v)
	if v == nil then
		error(interp(lang.not_nil_not_nan_a, n, type(v)), 2)

	elseif v ~= v then
		error(interp(lang.not_nil_not_nan_b, n, type(v)), 2)
	end
end


lang.not_nil_not_false = "argument #$1: expected non-nil, non-false value, got false/nil"
function M.notNilNotFalse(n, v)
	if not v then
		error(interp(lang.not_nil_not_false, n, type(v)), 2)
	end
end


lang.not_nil_not_false_not_nan_a = "argument #$1: expected non-nil, non-false, non-NaN value, got false/nil"
lang.not_nil_not_false_not_nan_b = "argument #$1: expected non-nil, non-false, non-NaN value, got NaN"
function M.notNilNotFalseNotNaN(n, v)
	if not v then
		error(interp(lang.not_nil_not_false_not_nan_a, n, type(v)), 2)

	elseif v ~= v then
		error(interp(lang.not_nil_not_false_not_nan_b, n, type(v)), 2)
	end
end


lang.not_nan = "argument #$1: expected non-NaN value"
function M.notNaN(n, v)
	if v ~= v then
		error(interp(lang.not_nan, n, type(v)), 2)
	end
end


return M
