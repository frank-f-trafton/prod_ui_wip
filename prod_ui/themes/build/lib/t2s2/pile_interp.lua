-- PILE interp v1.1.0
-- (C) 2024 PILE Contributors
-- License: MIT or MIT-0
-- https://github.com/rabbitboots/pile_base


local interp = {}


local min, pairs, select, tostring = math.min, pairs, select, tostring


local v = {}


local function c()
	for k in pairs(v) do
		v[k] = nil
	end
	v["$"] = "$"
end


c()


return function(s, ...)
	for i = 1, min(10, select("#", ...)) do
		v[tostring(i)] = tostring(select(i, ...))
	end
	local r = tostring(s):gsub("%$(.)", v)
	c()
	return r
end
