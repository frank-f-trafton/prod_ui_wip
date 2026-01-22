-- PILE Math
-- VERSION: 2.022
-- https://github.com/frank-f-trafton/pile_base


--[[
MIT License

Copyright (c) 2024 - 2026 PILE Contributors

LUIGI code: Copyright (c) 2015 airstruck
  https://github.com/airstruck/luigi

lume code: Copyright (c) 2020 rxi
  https://github.com/rxi/lume

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]


local _ceil, _floor, _max, _min, _sqrt = math.ceil, math.floor, math.max, math.min, math.sqrt


local function clamp(n, a, b)
	return _max(a, _min(n, b))
end


-- [lume]
local function dist(x1, y1, x2, y2)
	local dx, dy = x1 - x2, y1 - y2
	return _sqrt(dx*dx + dy*dy)
end

-- [lume]
local function distSq(x1, y1, x2, y2)
	local dx, dy = x1 - x2, y1 - y2
	return dx*dx + dy*dy
end


local function lerp(a, b, v)
	return (1 - v) * a + v * b
end


-- [lume]
local function roundInf(n)
	return n > 0 and _floor(n + .5) or _ceil(n - .5)
end
local _roundInf = roundInf


-- [lume]
local function roundInfIncrement(n, incr)
	return _roundInf(n / incr) * incr
end


local function sign(n)
	return n < 0 and -1 or n > 0 and 1 or 0
end


local function signN(n)
	return n <= 0 and -1 or 1
end


local function signP(n)
	return n < 0 and -1 or 1
end


local function wrap1(n, max)
	return ((n - 1) % max) + 1
end


return {
	clamp = clamp,
	dist = dist,
	distSq = distSq,
	lerp = lerp,
	roundInf = roundInf,
	roundInfIncrement = roundInfIncrement,
	sign = sign,
	signN = signN,
	signP = signP,
	wrap1 = wrap1
}
