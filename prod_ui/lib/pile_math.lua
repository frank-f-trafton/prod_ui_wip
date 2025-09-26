-- PILE Math v1.201 (Modified)
-- (C) 2024 - 2025 PILE Contributors
-- License: MIT or MIT-0
-- https://github.com/frank-f-trafton/pile_base


local M = {}


function M.clamp(n, a, b)
	return math.max(a, math.min(n, b))
end


function M.lerp(a, b, v)
	return (1 - v) * a + v * b
end


function M.round(n)
	return n < 0 and math.floor(n + 0.5) or math.ceil(n - 0.5)
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


function M.wrap1Array(t, n)
	return t[((n - 1) % #t) + 1]
end


return M
