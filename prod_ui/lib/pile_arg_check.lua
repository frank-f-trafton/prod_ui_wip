-- PILE argCheck v1.1.3 (modified)
-- (C) 2024 PILE Contributors
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
		error(interp(lang.int, n))
	end
end


lang.int_eval = "argument #$1: expected false/nil or integer"
function M.intEval(n, v)
	if v and (type(v) ~= "number" or math.floor(v) ~= v or v ~= v) then
		error(interp(lang.int_eval, n))
	end
end


lang.int_ge = "argument #$1: expected integer greater or equal to $2"
function M.intGE(n, v, min)
	if type(v) ~= "number" or math.floor(v) ~= v or v < min or v ~= v then
		error(interp(lang.int_ge, n, min))
	end
end


lang.int_ge_eval = "argument #$1: expected false/nil or integer greater or equal to $2"
function M.intGEEval(n, v, min)
	if v and (type(v) ~= "number" or math.floor(v) ~= v or v < min or v ~= v) then
		error(interp(lang.int_ge_eval, n, min))
	end
end


lang.int_range = "argument #$1: integer is out of range"
function M.intRange(n, v, min, max)
	if type(v) ~= "number" or math.floor(v) ~= v or v < min or v > max or v ~= v then
		error(interp(lang.int_range, n, min, max))
	end
end
function M.intRangeEval(n, v, min, max)
	if v and (type(v) ~= "number" or math.floor(v) ~= v or v < min or v > max or v ~= v) then
		error(interp(lang.int_range, n, min, max))
	end
end


lang.int_range_static = "argument #$1: expected integer within the range of $2 to $3"
function M.intRangeStatic(n, v, min, max)
	if type(v) ~= "number" or math.floor(v) ~= v or v < min or v > max or v ~= v then
		error(interp(lang.int_range_static, n, min, max))
	end
end


lang.int_range_static_eval = "argument #$1: expected false/nil or integer within the range of $2 to $3"
function M.intRangeStaticEval(n, v, min, max)
	if v and (type(v) ~= "number" or math.floor(v) ~= v or v < min or v > max or v ~= v) then
		error(interp(lang.int_range_static_eval, n, min, max))
	end
end


lang.nan_a = "argument #$1: unexpected non-NaN number, got $2"
lang.nan_b = "argument #$1: unexpected non-NaN number, got NaN"
function M.numberNotNaN(n, v)
	if type(v) ~= "number" then
		error(interp(lang.nan_a, n, type(v)))

	elseif v ~= v then
		error(interp(lang.nan_b, n))
	end
end


lang.nan_eval_a = "argument #$1: unexpected false/nil or non-NaN number, got $2"
lang.nan_eval_b = "argument #$1: unexpected false/nil or non-NaN number, got NaN"
function M.numberNotNaNEval(n, v)
	if type(v) ~= "number" then
		error(interp(lang.nan_eval_a, n, type(v)))

	elseif v ~= v then
		error(interp(lang.nan_eval_b, n))
	end
end


lang.enum_a = "argument #$1: invalid $2 (got $3)"
lang.enum_b = "argument #$1: invalid $2 (got non-number, non-string value)"
local function _enumErr(v) return (type(v) == "string" or type(v) == "number") and lang.enum_a or lang.enum_b end
function M.enum(n, v, id, e)
	if not e[v] then
		error(interp(_enumErr(v), n, id, v))
	end
end
function M.enumEval(n, v, id, e)
	if v and not e[v] then
		error(interp(_enumErr(v), n, id, v))
	end
end


lang.something = "argument #$1: expected non-false, non-nil value, got type $2"
function M.something(n, v)
	if not v then
		error(interp(lang.something, n, type(v)))
	end
end


return M
