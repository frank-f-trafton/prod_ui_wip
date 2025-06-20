-- PILE Math v1.1.6
-- (C) 2024 - 2025 PILE Contributors
-- License: MIT or MIT-0
-- https://github.com/rabbitboots/pile_base


local M = {}


function M.clamp(n, a, b)
	return math.max(a, math.min(n, b))
end


function M.lerp(a, b, v)
	return (1 - v) * a + v * b
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
