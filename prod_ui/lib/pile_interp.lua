-- PILE Interp
-- VERSION: 2.012
-- https://github.com/frank-f-trafton/pile_base


--[[
MIT License

Copyright (c) 2024 - 2025 PILE Contributors

PILE Base uses code from these libraries:

PILE Tree:
  LUIGI
  Copyright (c) 2015 airstruck
  License: MIT
  https://github.com/airstruck/luigi


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
