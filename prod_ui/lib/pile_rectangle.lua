-- PILE Rectangle
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


local M = {}


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local pMath = require(PATH .. "pile_math")
local pAssert = require(PATH .. "pile_assert")


local _lerp, _roundInf = pMath.lerp, pMath.roundInf
local _min, _max = math.min, math.max
local select = select


--[[ASSERT
local L = pAssert.L


local function _checkRectangle(r, name)
	pAssert.type(nil, r, "table")
	L[1] = name
	L[2] = "x"; pAssert.numberNotNaN(L, r.x)
	L[2] = "y"; pAssert.numberNotNaN(L, r.y)
	L[2] = "w"; pAssert.numberNotNaN(L, r.w)
	L[2] = "h"; pAssert.numberNotNaN(L, r.h)
end


local function _checkArrayOfRectangles(list, name)
	pAssert.type(1, list, "table")
	for i, v in ipairs(list) do
		_checkRectangle(v, name .. "[" .. i .. "]")
	end
end


local function _checkVarargOfRectangles(name, ...)
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		_checkRectangle(r, name .. "[" .. i .. "]")
	end
end


local function _checkSideDelta(sd, name)
	pAssert.type(nil, sd, "table")
	L[1] = name
	L[2] = "x1"; pAssert.numberNotNaN(L, sd.x1)
	L[2] = "y1"; pAssert.numberNotNaN(L, sd.y1)
	L[2] = "x2"; pAssert.numberNotNaN(L, sd.x2)
	L[2] = "y2"; pAssert.numberNotNaN(L, sd.y2)
end
--]]


function M.set(r, x, y, w, h)
	--[[ASSERT
	pAssert.type(1, r, "table")
	pAssert.numberNotNaN(2, x)
	pAssert.numberNotNaN(3, y)
	pAssert.numberNotNaN(4, w)
	pAssert.numberNotNaN(5, h)
	--]]

	r.x, r.y, r.w, r.h = x, y, _max(0, w), _max(0, h)

	return r
end


function M.setPosition(r, x, y)
	--[[ASSERT
	pAssert.type(1, r, "table")
	pAssert.numberNotNaN(2, x)
	pAssert.numberNotNaN(3, y)
	--]]

	r.x, r.y = x, y

	return r
end


function M.setDimensions(r, w, h)
	--[[ASSERT
	pAssert.type(1, r, "table")
	pAssert.numberNotNaN(2, w)
	pAssert.numberNotNaN(3, h)
	--]]

	r.w, r.h = w, h

	return r
end


function M.copy(a, b)
	--[[ASSERT
	_checkRectangle(a, "a")
	pAssert.type(2, b, "table")
	--]]

	b.x, b.y, b.w, b.h = a.x, a.y, a.w, a.h

	return a
end


function M.expand(r, x1, y1, x2, y2)
	--[[ASSERT
	_checkRectangle(r, "r")
	pAssert.numberNotNaN(2, x1)
	pAssert.numberNotNaN(3, y1)
	pAssert.numberNotNaN(4, x2)
	pAssert.numberNotNaN(5, y2)
	--]]

	r.x = r.x - x1
	r.y = r.y - y1
	r.w = _max(0, r.w + x1 + x2)
	r.h = _max(0, r.h + y1 + y2)

	return r
end


function M.reduce(r, x1, y1, x2, y2)
	--[[ASSERT
	_checkRectangle(r, "r")
	pAssert.numberNotNaN(2, x1)
	pAssert.numberNotNaN(3, y1)
	pAssert.numberNotNaN(4, x2)
	pAssert.numberNotNaN(5, y2)
	--]]

	r.x = r.x + x1
	r.y = r.y + y1
	r.w = _max(0, r.w - x1 - x2)
	r.h = _max(0, r.h - y1 - y2)

	return r
end


function M.expandT(r, sd)
	--[[ASSERT
	_checkRectangle(r, "r")
	_checkSideDelta(sd, "sd")
	--]]

	r.x = r.x - sd.x1
	r.y = r.y - sd.y1
	r.w = _max(0, r.w + sd.x1 + sd.x2)
	r.h = _max(0, r.h + sd.y1 + sd.y2)

	return r
end


function M.reduceT(r, sd)
	--[[ASSERT
	_checkRectangle(r, "r")
	_checkSideDelta(sd, "sd")
	--]]

	r.x = r.x + sd.x1
	r.y = r.y + sd.y1
	r.w = _max(0, r.w - sd.x1 - sd.x2)
	r.h = _max(0, r.h - sd.y1 - sd.y2)

	return r
end


function M.expandHorizontal(r, x1, x2)
	--[[ASSERT
	_checkRectangle(r, "r")
	pAssert.numberNotNaN(2, x1)
	pAssert.numberNotNaN(3, x2)
	--]]

	r.x = r.x - x1
	r.w = _max(0, r.w + x1 + x2)

	return r
end


function M.reduceHorizontal(r, x1, x2)
	--[[ASSERT
	_checkRectangle(r, "r")
	pAssert.numberNotNaN(2, x1)
	pAssert.numberNotNaN(3, x2)
	--]]

	r.x = r.x + x1
	r.w = _max(0, r.w - x1 - x2)

	return r
end


function M.expandVertical(r, y1, y2)
	--[[ASSERT
	_checkRectangle(r, "r")
	pAssert.numberNotNaN(2, y1)
	pAssert.numberNotNaN(3, y2)
	--]]

	r.y = r.y - y1
	r.h = _max(0, r.h + y1 + y2)

	return r
end


function M.reduceVertical(r, y1, y2)
	--[[ASSERT
	_checkRectangle(r, "r")
	pAssert.numberNotNaN(2, y1)
	pAssert.numberNotNaN(3, y2)
	--]]

	r.y = r.y + y1
	r.h = _max(0, r.h - y1 - y2)

	return r
end


function M.expandLeft(r, x1)
	--[[ASSERT
	_checkRectangle(r, "r")
	pAssert.numberNotNaN(2, x1)
	--]]

	r.x = r.x - x1
	r.w = _max(0, r.w + x1)

	return r
end


function M.reduceLeft(r, x1)
	--[[ASSERT
	_checkRectangle(r, "r")
	pAssert.numberNotNaN(2, x1)
	--]]

	r.x = r.x + x1
	r.w = _max(0, r.w - x1)

	return r
end


function M.expandRight(r, x2)
	--[[ASSERT
	_checkRectangle(r, "r")
	pAssert.numberNotNaN(2, x2)
	--]]

	r.w = _max(0, r.w + x2)

	return r
end


function M.reduceRight(r, x2)
	--[[ASSERT
	_checkRectangle(r, "r")
	pAssert.numberNotNaN(2, x2)
	--]]

	r.w = _max(0, r.w - x2)

	return r
end


function M.expandTop(r, y1)
	--[[ASSERT
	_checkRectangle(r, "r")
	pAssert.numberNotNaN(2, y1)
	--]]

	r.y = r.y - y1
	r.h = _max(0, r.h + y1)

	return r
end


function M.reduceTop(r, y1)
	--[[ASSERT
	_checkRectangle(r, "r")
	pAssert.numberNotNaN(2, y1)
	--]]

	r.y = r.y + y1
	r.h = _max(0, r.h - y1)

	return r
end


function M.expandBottom(r, y2)
	--[[ASSERT
	_checkRectangle(r, "r")
	pAssert.numberNotNaN(2, y2)
	--]]

	r.h = _max(0, r.h + y2)

	return r
end


function M.reduceBottom(r, y2)
	--[[ASSERT
	_checkRectangle(r, "r")
	pAssert.numberNotNaN(2, y2)
	--]]

	r.h = _max(0, r.h - y2)

	return r
end


function M.splitLeft(a, b, len)
	--[[ASSERT
	_checkRectangle(a, "a")
	_checkRectangle(b, "b")
	pAssert.numberNotNaN(3, len)
	--]]

	len = _min(len, a.w)
	a.x = a.x + len
	a.w = a.w - len
	b.x = a.x - len
	b.w = len
	b.y = a.y
	b.h = a.h

	return a
end


function M.splitRight(a, b, len)
	--[[ASSERT
	_checkRectangle(a, "a")
	_checkRectangle(b, "b")
	pAssert.numberNotNaN(3, len)
	--]]

	len = _min(len, a.w)
	a.w = a.w - len
	b.x = a.x + a.w
	b.w = len
	b.y = a.y
	b.h = a.h

	return a
end


function M.splitTop(a, b, len)
	--[[ASSERT
	_checkRectangle(a, "a")
	_checkRectangle(b, "b")
	pAssert.numberNotNaN(3, len)
	--]]

	len = _min(len, a.h)
	a.y = a.y + len
	a.h = a.h - len
	b.y = a.y - len
	b.h = len
	b.x = a.x
	b.w = a.w

	return a
end


function M.splitBottom(a, b, len)
	--[[ASSERT
	_checkRectangle(a, "a")
	_checkRectangle(b, "b")
	pAssert.numberNotNaN(3, len)
	--]]

	len = _min(len, a.h)
	a.h = a.h - len
	b.y = a.y + a.h
	b.h = len
	b.x = a.x
	b.w = a.w

	return a
end


local _split_sides = {
	left=M.splitLeft,
	right=M.splitRight,
	top=M.splitTop,
	bottom=M.splitBottom
}


function M.split(a, b, placement, len)
	--[[ASSERT
	_checkRectangle(a, "a")
	_checkRectangle(b, "b")
	-- don't assert 'placement'.
	pAssert.numberNotNaN(4, len)
	--]]

	local fn = _split_sides[placement]
	if not fn then
		error("invalid placement: " .. tostring(placement))
	else
		fn(a, b, len)
	end

	return a
end


function M.splitOrOverlay(a, b, placement, len)
	--[[ASSERT
	_checkRectangle(a, "a")
	_checkRectangle(b, "b")
	-- don't assert 'placement'.
	if placement ~= "overlay" then
		pAssert.numberNotNaN(4, len)
	end
	--]]

	if placement == "overlay" then
		b.x, b.y, b.w, b.h = a.x, a.y, a.w, a.h
	else
		local fn = _split_sides[placement]
		if not fn then
			error("invalid placement: " .. tostring(placement))
		else
			fn(a, b, len)
		end
	end

	return a
end


function M.placeInner(a, b, ux, uy)
	--[[ASSERT
	_checkRectangle(a, "a")
	_checkRectangle(b, "b")
	pAssert.numberNotNaN(3, ux)
	pAssert.numberNotNaN(4, uy)
	--]]

	b.x = _roundInf(_lerp(a.x, a.x + a.w - b.w, ux))
	b.y = _roundInf(_lerp(a.y, a.y + a.h - b.h, uy))

	return a
end


function M.placeInnerHorizontal(a, b, ux)
	--[[ASSERT
	_checkRectangle(a, "a")
	_checkRectangle(b, "b")
	pAssert.numberNotNaN(3, ux)
	--]]

	b.x = _roundInf(_lerp(a.x, a.x + a.w - b.w, ux))

	return a
end


function M.placeInnerVertical(a, b, uy)
	--[[ASSERT
	_checkRectangle(a, "a")
	_checkRectangle(b, "b")
	pAssert.numberNotNaN(4, uy)
	--]]

	b.y = _roundInf(_lerp(a.y, a.y + a.h - b.h, uy))

	return a
end


function M.placeMidpoint(a, b, ux, uy)
	--[[ASSERT
	_checkRectangle(a, "a")
	_checkRectangle(b, "b")
	pAssert.numberNotNaN(3, ux)
	pAssert.numberNotNaN(4, uy)
	--]]

	b.x = _roundInf(_lerp(a.x - b.w*.5, a.x + a.w + b.w*.5, ux))
	b.y = _roundInf(_lerp(a.y - b.h*.5, a.y + a.h + b.h*.5, uy))

	return a
end


function M.placeMidpointHorizontal(a, b, ux)
	--[[ASSERT
	_checkRectangle(a, "a")
	_checkRectangle(b, "b")
	pAssert.numberNotNaN(3, ux)
	--]]

	b.x = _roundInf(_lerp(a.x - b.w*.5, a.x + a.w + b.w*.5, ux))

	return a
end


function M.placeMidpointVertical(a, b, uy)
	--[[ASSERT
	_checkRectangle(a, "a")
	_checkRectangle(b, "b")
	pAssert.numberNotNaN(4, uy)
	--]]

	b.y = _roundInf(_lerp(a.y - b.h*.5, a.y + a.h + b.h*.5, uy))

	return a
end


function M.placeOuter(a, b, ux, uy)
	--[[ASSERT
	_checkRectangle(a, "a")
	_checkRectangle(b, "b")
	pAssert.numberNotNaN(3, ux)
	pAssert.numberNotNaN(4, uy)
	--]]

	b.x = _roundInf(_lerp(a.x - b.w, a.x + a.w + b.w, ux))
	b.y = _roundInf(_lerp(a.y - b.h, a.y + a.h + b.h, uy))

	return a
end


function M.placeOuterHorizontal(a, b, ux)
	--[[ASSERT
	_checkRectangle(a, "a")
	_checkRectangle(b, "b")
	pAssert.numberNotNaN(3, ux)
	--]]

	b.x = _roundInf(_lerp(a.x - b.w, a.x + a.w + b.w, ux))

	return a
end


function M.placeOuterVertical(a, b, uy)
	--[[ASSERT
	_checkRectangle(a, "a")
	_checkRectangle(b, "b")
	pAssert.numberNotNaN(4, uy)
	--]]

	b.y = _roundInf(_lerp(a.y - b.h, a.y + a.h + b.h, uy))

	return a
end


function M.center(a, b)
	--[[ASSERT
	_checkRectangle(a, "a")
	_checkRectangle(b, "b")
	--]]

	b.x = _roundInf(a.x + (a.w - b.w)*.5)
	b.y = _roundInf(a.y + (a.h - b.h)*.5)

	return a
end


function M.centerHorizontal(a, b)
	--[[ASSERT
	_checkRectangle(a, "a")
	_checkRectangle(b, "b")
	--]]

	b.x = _roundInf(a.x + (a.w - b.w)*.5)

	return a
end


function M.centerVertical(a, b)
	--[[ASSERT
	_checkRectangle(a, "a")
	_checkRectangle(b, "b")
	--]]

	b.y = _roundInf(a.y + (a.h - b.h)*.5)

	return a
end


function M.flipHorizontal(a, b)
	--[[ASSERT
	_checkRectangle(a, "a")
	_checkRectangle(b, "b")
	--]]

	local l = b.x - a.x
	b.x = a.w - l - b.w + a.x

	return a
end


function M.flipVertical(a, b)
	--[[ASSERT
	_checkRectangle(a, "a")
	_checkRectangle(b, "b")
	--]]

	local l = b.y - a.y
	b.y = a.h - b.h - l + a.y

	return a
end


function M.pointOverlap(r, x, y)
	--[[ASSERT
	pAssert.type(1, r, "table")
	pAssert.numberNotNaN(2, x)
	pAssert.numberNotNaN(3, y)
	--]]

	return x >= r.x and x < r.x + r.w and y >= r.y and y < r.y + r.h
end


function M.getBounds(...)
	--[[ASSERT
	_checkVarargOfRectangles("vararg", ...)
	--]]

	local x1, y1, x2, y2 = 0, 0, 0, 0
	for i = 1, select("#", ...) do
		local r = select(i, ...)
		x1, y1, x2, y2 = _min(x1, r.x), _min(y1, r.y), _max(x2, r.x + r.w), _max(y2, r.y + r.h)
	end

	return x1, y1, x2, y2
end


function M.getBoundsT(list)
	--[[ASSERT
	_checkArrayOfRectangles(list, "list")
	--]]

	local x1, y1, x2, y2 = 0, 0, 0, 0
	for i, r in ipairs(list) do
		x1, y1, x2, y2 = _min(x1, r.x), _min(y1, r.y), _max(x2, r.x + r.w), _max(y2, r.y + r.h)
	end

	return x1, y1, x2, y2
end


return M
