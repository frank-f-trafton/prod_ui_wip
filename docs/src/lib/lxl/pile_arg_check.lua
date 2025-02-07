-- PILE argCheck v1.1.1 (modified)
-- (C) 2024 PILE Contributors
-- License: MIT or MIT-0
-- https://github.com/rabbitboots/pile_base


local argCheck = {}


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local interp = require(PATH .. "pile_interp")


local select, table, type = select, table, type


argCheck.lang = {}
local lang = argCheck.lang


lang.err_type_bad = "argument #$1: bad type (expected [$2], got $3)"
function argCheck.type(n, v, ...)
	local typ = type(v)
	for i = 1, select("#", ...) do
		if typ == select(i, ...) then
			return
		end
	end
	error(interp(lang.err_type_bad, n, table.concat({...}, ", "), typ), 2)
end


lang.err_int_bad = "argument #$1: expected integer"
function argCheck.int(n, v)
	if type(v) ~= "number" or math.floor(v) ~= v then
		error(interp(lang.err_int_bad, n))
	end
end


lang.err_int_ge_bad = "argument #$1: expected integer greater or equal to $2"
function argCheck.intGE(n, v, min)
	if type(v) ~= "number" or math.floor(v) ~= v or v < min then
		error(interp(lang.err_int_ge_bad, n, min))
	end
end


lang.err_int_range_bad = "argument #$1: expected integer within the range of $2 to $3"
function argCheck.intRange(n, v, min, max)
	if type(v) ~= "number" or math.floor(v) ~= v or v < min or v > max then
		error(interp(lang.err_int_range_bad, n, min, max))
	end
end


return argCheck
