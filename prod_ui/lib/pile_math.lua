-- PILE Math v2.000
-- (C) 2024 - 2025 PILE Contributors
-- License: MIT
-- https://github.com/frank-f-trafton/pile_base


local M = {}


local _ceil, _floor, _max, _min = math.ceil, math.floor, math.max, math.min


function M.clamp(n, a, b)
	return _max(a, _min(n, b))
end


function M.lerp(a, b, v)
	return (1 - v) * a + v * b
end


function M.roundInf(n)
	return n > 0 and _floor(n + .5) or _ceil(n - .5)
end


function M.sign(n)
	return n < 0 and -1 or n > 0 and 1 or 0
end


function M.signN(n)
	return n <= 0 and -1 or 1
end


function M.signP(n)
	return n < 0 and -1 or 1
end


function M.wrap1(n, max)
	return ((n - 1) % max) + 1
end


return M
