-- PILE argCheck v1.200
-- (C) 2024 - 2025 PILE Contributors
-- License: MIT or MIT-0
-- https://github.com/frank-f-trafton/pile_base


local M = {}


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local interp = require(PATH .. "pile_interp")


local select, table, type = select, table, type


M.lang = {}
local lang = M.lang


lang.type = "argument #$1: bad type (expected [$2], got $3)"
lang.type_n = "bad type (expected [$2], got $3)"
function M.type(n, v, ...)
	local typ = type(v)
	for i = 1, select("#", ...) do
		if typ == select(i, ...) then
			return
		end
	end
	error(interp(n and lang.type or lang.type_n, n, table.concat({...}, ", "), typ), 2)
end


lang.type_eval = "argument #$1: bad type (expected false/nil or [$2], got $3)"
lang.type_eval_n = "bad type (expected false/nil or [$2], got $3)"
function M.typeEval(n, v, ...)
	if v then
		local typ = type(v)
		for i = 1, select("#", ...) do
			if typ == select(i, ...) then
				return
			end
		end
		error(interp(n and lang.type_eval or lang.type_eval_n, n, table.concat({...}, ", "), typ), 2)
	end
end


lang.type1 = "argument #$1: bad type (expected $2, got $3)"
lang.type1_n = "bad type (expected $2, got $3)"
function M.type1(n, v, e)
	if type(v) ~= e then
		error(interp(n and lang.type1 or lang.type1_n, n, e, type(v)), 2)
	end
end


lang.type_eval1 = "argument #$1: bad type (expected false/nil or $2, got $3)"
lang.type_eval1_n = "bad type (expected false/nil or $2, got $3)"
function M.typeEval1(n, v, e)
	if v and type(v) ~= e then
		error(interp(n and lang.type_eval1 or lang.type_eval1_n, n, e, type(v)), 2)
	end
end


lang.int = "argument #$1: expected integer"
lang.int_n = "expected integer"
function M.int(n, v)
	if type(v) ~= "number" or math.floor(v) ~= v or v ~= v then
		error(interp(n and lang.int or lang.int_n, n), 2)
	end
end


lang.int_eval = "argument #$1: expected false/nil or integer"
lang.int_eval_n = "expected false/nil or integer"
function M.intEval(n, v)
	if v and (type(v) ~= "number" or math.floor(v) ~= v or v ~= v) then
		error(interp(n and lang.int_eval or lang.int_eval_n, n), 2)
	end
end


lang.int_ge = "argument #$1: expected integer greater or equal to $2"
lang.int_ge_n = "expected integer greater or equal to $2"
function M.intGE(n, v, min)
	if type(v) ~= "number" or math.floor(v) ~= v or v < min or v ~= v then
		error(interp(n and lang.int_ge or lang.int_ge_n, n, min), 2)
	end
end


lang.int_ge_eval = "argument #$1: expected false/nil or integer greater or equal to $2"
lang.int_ge_eval_n = "expected false/nil or integer greater or equal to $2"
function M.intGEEval(n, v, min)
	if v and (type(v) ~= "number" or math.floor(v) ~= v or v < min or v ~= v) then
		error(interp(n and lang.int_ge_eval or lang.int_ge_eval_n, n, min), 2)
	end
end


lang.int_range_a = "argument #$1: expected integer, got $2"
lang.int_range_a_n = "expected integer, got $2"
lang.int_range_b = "argument #$1: got non-integer number"
lang.int_range_b_n = "got non-integer number"
lang.int_range_c = "argument #$1: integer is out of range"
lang.int_range_c_n = "integer is out of range"
function M.intRange(n, v, min, max)
	if type(v) ~= "number" then error(interp(n and lang.int_range_a or lang.int_range_a_n, n, type(v)), 2)
	elseif math.floor(v) ~= v then error(interp(n and lang.int_range_b or lang.int_range_b_n, n), 2)
	elseif v < min or v > max or v ~= v then error(interp(n and lang.int_range_c or lang.int_range_c_n, n), 2) end
end


lang.int_range_eval_a = "argument #$1: expected false/nil or integer, got $2"
lang.int_range_eval_a_n = "expected false/nil or integer, got $2"
lang.int_range_eval_b = "argument #$1: got non-integer number"
lang.int_range_eval_b_n = "got non-integer number"
lang.int_range_eval_c = "argument #$1: integer is out of range"
lang.int_range_eval_c_n = "integer is out of range"
function M.intRangeEval(n, v, min, max)
	if v then
		if type(v) ~= "number" then error(interp(n and lang.int_range_eval_a or lang.int_range_eval_a_n, n, type(v)), 2)
		elseif math.floor(v) ~= v then error(interp(n and lang.int_range_eval_b or lang.int_range_eval_b_n, n), 2)
		elseif v < min or v > max or v ~= v then error(interp(n and lang.int_range_eval_c or lang.int_range_eval_c_n, n), 2) end
	end
end


lang.int_range_static_a = "argument #$1: expected integer, got $2"
lang.int_range_static_a_n = "expected integer, got $2"
lang.int_range_static_b = "argument #$1: got non-integer number"
lang.int_range_static_b_n = "got non-integer number"
lang.int_range_static_c = "argument #$1: integer is out of range ($2 - $3)"
lang.int_range_static_c_n = "integer is out of range ($2 - $3)"
function M.intRangeStatic(n, v, min, max)
	if type(v) ~= "number" then error(interp(n and lang.int_range_static_a or lang.int_range_static_a_n, n, type(v)), 2)
	elseif math.floor(v) ~= v then error(interp(n and lang.int_range_static_b or lang.int_range_static_b_n, n), 2)
	elseif v < min or v > max or v ~= v then error(interp(n and lang.int_range_static_c or lang.int_range_static_c_n, n, min, max), 2) end
end


lang.int_range_static_eval_a = "argument #$1: expected false/nil or integer, got $2"
lang.int_range_static_eval_a_n = "expected false/nil or integer, got $2"
lang.int_range_static_eval_b = "argument #$1: got non-integer number"
lang.int_range_static_eval_b_n = "got non-integer number"
lang.int_range_static_eval_c = "argument #$1: integer is out of range ($2 - $3)"
lang.int_range_static_eval_c_n = "integer is out of range ($2 - $3)"
function M.intRangeStaticEval(n, v, min, max)
	if v then
		if type(v) ~= "number" then error(interp(n and lang.int_range_static_eval_a or lang.int_range_static_eval_a_n, n, type(v)), 2)
		elseif math.floor(v) ~= v then error(interp(n and lang.int_range_static_eval_b or lang.int_range_static_eval_b_n, n), 2)
		elseif v < min or v > max or v ~= v then error(interp(n and lang.int_range_static_eval_c or lang.int_range_static_eval_c_n, n, min, max), 2) end
	end
end


lang.nan_a = "argument #$1: expected non-NaN number, got $2"
lang.nan_a_n = "expected non-NaN number, got $2"
lang.nan_b = "argument #$1: expected non-NaN number, got NaN"
lang.nan_b_n = "expected non-NaN number, got NaN"
function M.numberNotNaN(n, v)
	if type(v) ~= "number" then
		error(interp(n and lang.nan_a or lang.nan_a_n, n, type(v)), 2)

	elseif v ~= v then
		error(interp(n and lang.nan_b or lang.nan_b_n, n), 2)
	end
end


lang.nan_eval_a = "argument #$1: expected false/nil or non-NaN number, got $2"
lang.nan_eval_a_n = "expected false/nil or non-NaN number, got $2"
lang.nan_eval_b = "argument #$1: expected false/nil or non-NaN number, got NaN"
lang.nan_eval_b_n = "expected false/nil or non-NaN number, got NaN"
function M.numberNotNaNEval(n, v)
	if v then
		if type(v) ~= "number" then
			error(interp(n and lang.nan_eval_a or lang.nan_eval_a_n, n, type(v)), 2)

		elseif v ~= v then
			error(interp(n and lang.nan_eval_b or lang.nan_eval_b_n, n), 2)
		end
	end
end


lang.enum_a = "argument #$1: invalid $2 (got '$3')"
lang.enum_a_n = "invalid $2 (got '$3')"
lang.enum_b = "argument #$1: invalid $2 (got non-number, non-string value)"
lang.enum_b_n = "invalid $2 (got non-number, non-string value)"
local function _enumErr(v) return (type(v) == "string" or type(v) == "number") and lang.enum_a or lang.enum_b end
local function _enumErrN(v) return (type(v) == "string" or type(v) == "number") and lang.enum_a_n or lang.enum_b_n end
function M.enum(n, v, id, e)
	if not e[v] then
		error(interp((n and _enumErr or _enumErrN)(v), n, id, v), 2)
	end
end
function M.enumEval(n, v, id, e)
	if v and not e[v] then
		error(interp((n and _enumErr or _enumErrN)(v), n, id, v), 2)
	end
end


lang.not_nil = "argument #$1: expected non-nil value"
lang.not_nil_n = "expected non-nil value"
function M.notNil(n, v)
	if v == nil then
		error(interp(n and lang.not_nil or lang.not_nil_n, n), 2)
	end
end


lang.not_nil_not_nan_a = "argument #$1: expected non-nil, non-NaN value, got nil"
lang.not_nil_not_nan_a_n = "expected non-nil, non-NaN value, got nil"
lang.not_nil_not_nan_b = "argument #$1: expected non-nil, non-NaN value, got NaN"
lang.not_nil_not_nan_b_n = "expected non-nil, non-NaN value, got NaN"
function M.notNilNotNaN(n, v)
	if v == nil then
		error(interp(n and lang.not_nil_not_nan_a or lang.not_nil_not_nan_a_n, n, type(v)), 2)

	elseif v ~= v then
		error(interp(n and lang.not_nil_not_nan_b or lang.not_nil_not_nan_b_n, n, type(v)), 2)
	end
end


lang.not_nil_not_false = "argument #$1: expected non-nil, non-false value, got false/nil"
lang.not_nil_not_false_n = "expected non-nil, non-false value, got false/nil"
function M.notNilNotFalse(n, v)
	if not v then
		error(interp(n and lang.not_nil_not_false or lang.not_nil_not_false_n, n, type(v)), 2)
	end
end


lang.not_nil_not_false_not_nan_a = "argument #$1: expected non-nil, non-false, non-NaN value, got false/nil"
lang.not_nil_not_false_not_nan_a_n = "expected non-nil, non-false, non-NaN value, got false/nil"
lang.not_nil_not_false_not_nan_b = "argument #$1: expected non-nil, non-false, non-NaN value, got NaN"
lang.not_nil_not_false_not_nan_b_n = "expected non-nil, non-false, non-NaN value, got NaN"
function M.notNilNotFalseNotNaN(n, v)
	if not v then
		error(interp(n and lang.not_nil_not_false_not_nan_a or lang.not_nil_not_false_not_nan_a_n, n, type(v)), 2)

	elseif v ~= v then
		error(interp(n and lang.not_nil_not_false_not_nan_b or lang.not_nil_not_false_not_nan_b_n, n, type(v)), 2)
	end
end


lang.not_nan = "argument #$1: expected non-NaN value"
lang.not_nan_n = "expected non-NaN value"
function M.notNaN(n, v)
	if v ~= v then
		error(interp(n and lang.not_nan or lang.not_nan_n, n, type(v)), 2)
	end
end


lang.f_type = "'$1[$2]': bad type (expected [$3], got $4)"
function M.fieldType(t, tn, f, ...)
	local typ = type(t[f])
	for i = 1, select("#", ...) do
		if typ == select(i, ...) then
			return
		end
	end
	error(interp(lang.f_type, tn, f, table.concat({...}, ", "), typ), 2)
end


lang.f_type_eval = "'$1[$2]': bad type (expected false/nil or [$3], got $4)"
function M.fieldTypeEval(t, tn, f, ...)
	local v = t[f]
	if v then
		local typ = type(v)
		for i = 1, select("#", ...) do
			if typ == select(i, ...) then
				return
			end
		end
		error(interp(lang.f_type_eval, tn, f, table.concat({...}, ", "), typ), 2)
	end
end


lang.f_type1 = "'$1[$2]': bad type (expected $3, got $4)"
function M.fieldType1(t, tn, f, e)
	local v = t[f]
	if type(v) ~= e then
		error(interp(lang.f_type1, tn, f, e, type(v)), 2)
	end
end


lang.f_type_eval1 = "'$1[$2]': bad type (expected false/nil or $3, got $4)"
function M.fieldTypeEval1(t, tn, f, e)
	local v = t[f]
	if v and type(v) ~= e then
		error(interp(lang.f_type_eval1, tn, f, e, type(v)), 2)
	end
end


lang.f_int = "'$1[$2]': expected integer"
function M.fieldInt(t, tn, f)
	local v = t[f]
	if type(v) ~= "number" or math.floor(v) ~= v or v ~= v then
		error(interp(lang.f_int, tn, f), 2)
	end
end


lang.f_int_eval = "'$1[$2]': expected false/nil or integer"
function M.fieldIntEval(t, tn, f)
	local v = t[f]
	if v and (type(v) ~= "number" or math.floor(v) ~= v or v ~= v) then
		error(interp(lang.f_int_eval, tn, f), 2)
	end
end


lang.f_int_ge = "'$1[$2]': expected integer greater or equal to $3"
function M.fieldIntGE(t, tn, f, min)
	local v = t[f]
	if type(v) ~= "number" or math.floor(v) ~= v or v < min or v ~= v then
		error(interp(lang.f_int_ge, tn, f, min), 2)
	end
end


lang.f_int_ge_eval = "'$1[$2]': expected false/nil or integer greater or equal to $3"
function M.fieldIntGEEval(t, tn, f, min)
	local v = t[f]
	if v and (type(v) ~= "number" or math.floor(v) ~= v or v < min or v ~= v) then
		error(interp(lang.f_int_ge_eval, tn, f, min), 2)
	end
end


lang.f_int_range_a = "'$1[$2]': expected integer, got $3"
lang.f_int_range_b = "'$1[$2]': got non-integer number"
lang.f_int_range_c = "'$1[$2]': integer is out of range"
function M.fieldIntRange(t, tn, f, min, max)
	local v = t[f]
	if type(v) ~= "number" then error(interp(lang.f_int_range_a, tn, f, type(v)), 2)
	elseif math.floor(v) ~= v then error(interp(lang.f_int_range_b, tn, f), 2)
	elseif v < min or v > max or v ~= v then error(interp(lang.f_int_range_c, tn, f), 2) end
end


lang.f_int_range_eval_a = "'$1[$2]': expected false/nil or integer, got $3"
lang.f_int_range_eval_b = "'$1[$2]': got non-integer number"
lang.f_int_range_eval_c = "'$1[$2]': integer is out of range"
function M.fieldIntRangeEval(t, tn, f, min, max)
	local v = t[f]
	if v then
		if type(v) ~= "number" then error(interp(lang.f_int_range_eval_a, tn, f, type(v)), 2)
		elseif math.floor(v) ~= v then error(interp(lang.f_int_range_eval_b, tn, f), 2)
		elseif v < min or v > max or v ~= v then error(interp(lang.f_int_range_eval_c, tn, f), 2) end
	end
end


lang.f_int_range_static_a = "'$1[$2]': expected integer, got $3"
lang.f_int_range_static_b = "'$1[$2]': got non-integer number"
lang.f_int_range_static_c = "'$1[$2]': integer is out of range ($3 - $4)"
function M.fieldIntRangeStatic(t, tn, f, min, max)
	local v = t[f]
	if type(v) ~= "number" then error(interp(lang.f_int_range_static_a, tn, f, type(v)), 2)
	elseif math.floor(v) ~= v then error(interp(lang.f_int_range_static_b, tn, f), 2)
	elseif v < min or v > max or v ~= v then error(interp(lang.f_int_range_static_c, tn, f, min, max), 2) end
end


lang.f_int_range_static_eval_a = "'$1[$2]': expected false/nil or integer, got $3"
lang.f_int_range_static_eval_b = "'$1[$2]': got non-integer number"
lang.f_int_range_static_eval_c = "'$1[$2]': integer is out of range ($3 - $4)"
function M.fieldIntRangeStaticEval(t, tn, f, min, max)
	local v = t[f]
	if v then
		if type(v) ~= "number" then error(interp(lang.f_int_range_static_eval_a, tn, f, type(v)), 2)
		elseif math.floor(v) ~= v then error(interp(lang.f_int_range_static_eval_b, tn, f), 2)
		elseif v < min or v > max or v ~= v then error(interp(lang.f_int_range_static_eval_c, tn, f, min, max), 2) end
	end
end


lang.f_nan_a = "'$1[$2]': expected non-NaN number, got $3"
lang.f_nan_b = "'$1[$2]': expected non-NaN number, got NaN"
function M.fieldNumberNotNaN(t, tn, f)
	local v = t[f]
	if type(v) ~= "number" then
		error(interp(lang.f_nan_a, tn, f, type(v)), 2)

	elseif v ~= v then
		error(interp(lang.f_nan_b, tn, f), 2)
	end
end


lang.f_nan_eval_a = "'$1[$2]': expected false/nil or non-NaN number, got $3"
lang.f_nan_eval_b = "'$1[$2]': expected false/nil or non-NaN number, got NaN"
function M.fieldNumberNotNaNEval(t, tn, f)
	local v = t[f]
	if v then
		if type(v) ~= "number" then
			error(interp(lang.f_nan_eval_a, tn, f, type(v)), 2)

		elseif v ~= v then
			error(interp(lang.f_nan_eval_b, tn, f), 2)
		end
	end
end


lang.f_enum_a = "'$1[$2]': invalid $3 (got '$4')"
lang.f_enum_b = "'$1[$2]': invalid $3 (got non-number, non-string value)"
local function _fEnumErr(v) return (type(v) == "string" or type(v) == "number") and lang.f_enum_a or lang.f_enum_b end
function M.fieldEnum(t, tn, f, id, e)
	local v = t[f]
	if not e[v] then
		error(interp(_fEnumErr(v), tn, f, id, v), 2)
	end
end
function M.fieldEnumEval(t, tn, f, id, e)
	local v = t[f]
	if v and not e[v] then
		error(interp(_fEnumErr(v), tn, f, id, v), 2)
	end
end


lang.f_not_nil = "'$1[$2]': expected non-nil value"
function M.fieldNotNil(t, tn, f)
	if t[f] == nil then
		error(interp(lang.f_not_nil, tn, f), 2)
	end
end


lang.f_not_nil_not_nan_a = "'$1[$2]': expected non-nil, non-NaN value, got nil"
lang.f_not_nil_not_nan_b = "'$1[$2]': expected non-nil, non-NaN value, got NaN"
function M.fieldNotNilNotNaN(t, tn, f)
	local v = t[f]
	if v == nil then
		error(interp(lang.f_not_nil_not_nan_a, tn, f, type(v)), 2)

	elseif v ~= v then
		error(interp(lang.f_not_nil_not_nan_b, tn, f, type(v)), 2)
	end
end


lang.f_not_nil_not_false = "'$1[$2]': expected non-nil, non-false value, got false/nil"
function M.fieldNotNilNotFalse(t, tn, f)
	local v = t[f]
	if not v then
		error(interp(lang.f_not_nil_not_false, tn, f, type(v)), 2)
	end
end


lang.f_not_nil_not_false_not_nan_a = "'$1[$2]': expected non-nil, non-false, non-NaN value, got false/nil"
lang.f_not_nil_not_false_not_nan_b = "'$1[$2]': expected non-nil, non-false, non-NaN value, got NaN"
function M.fieldNotNilNotFalseNotNaN(t, tn, f)
	local v = t[f]
	if not v then
		error(interp(lang.f_not_nil_not_false_not_nan_a, tn, f, type(v)), 2)

	elseif v ~= v then
		error(interp(lang.f_not_nil_not_false_not_nan_b, tn, f, type(v)), 2)
	end
end


lang.f_not_nan = "'$1[$2]': expected non-NaN value"
function M.fieldNotNaN(t, tn, f)
	local v = t[f]
	if v ~= v then
		error(interp(lang.f_not_nan, tn, f, type(v)), 2)
	end
end


return M
