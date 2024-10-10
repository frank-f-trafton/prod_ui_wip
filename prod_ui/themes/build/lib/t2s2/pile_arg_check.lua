-- PILE argCheck v1.1.0
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


lang.err_eval_bad = "argument #$1: bad type (expected false/nil or [$2], got $3)"
function argCheck.typeEval(n, v, ...)
	if v then
		local typ = type(v)
		for i = 1, select("#", ...) do
			if typ == select(i, ...) then
				return
			end
		end
		error(interp(lang.err_eval_bad, n, table.concat({...}, ", "), typ), 2)
	end
end


lang.err_eval_int_ge_bad = "argument #$1: expected false/nil or integer greater or equal to $2"
function argCheck.evalIntGE(n, v, min)
	if v and (type(v) ~= "number" or math.floor(v) ~= v or v < min) then
		error(interp(lang.err_eval_int_ge_bad, n, min))
	end
end


return argCheck
