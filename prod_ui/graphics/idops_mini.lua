-- Mini version of idops.
--[[
MIT License

Copyright (c) 2022, 2023 RBTS

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

local idops = {}


function idops.extrude(src, x, y, w, h)

	-- Edges
	src:paste(src, x, y - 1, x, y, w, 1)
	src:paste(src, x, y + h, x, y + h - 1, w, 1)
	src:paste(src, x - 1, y, x, y, 1, h)
	src:paste(src, x + w, y, x + w - 1, y, 1, h)

	-- Corners
	src:paste(src, x - 1, y - 1, x, y, 1, 1)
	src:paste(src, x + w, y - 1, x + w - 1, y, 1, 1)
	src:paste(src, x - 1, y + h, x, y + h - 1, 1, 1)
	src:paste(src, x + w, y + h, x + w - 1, y + h - 1, 1, 1)
end


function idops.map_premultiplyUncorrected(x, y, r, g, b, a)
	return r*a, g*a, b*a, a
end


function idops.map_predivideUncorrected(x, y, r, g, b, a) -- "unpremultiply"
	if a <= 0 then
		return 0, 0, 0, 0
	else
		return r/a, g/a, b/a, a
	end
end


function idops.map_premultiplyCorrected(x, y, r, g, b, a)

	-- https://love2d.org/wiki/love.math.linearToGamma
	r, g, b = love.math.gammaToLinear(r, g, b)
	r, g, b = r*a, g*a, b*a
	r, g, b = love.math.linearToGamma(r, g, b)

	return r, g, b, a
end


function idops.map_predivideCorrected(x, y, r, g, b, a) -- "unpremultiply"
	if a <= 0 then
		return 0, 0, 0, 0
	else
		r, g, b = love.math.gammaToLinear(r, g, b)
		r, g, b = r/a, g/a, b/a
		r, g, b = love.math.linearToGamma(r, g, b)
		return r, g, b, a
	end
end


if love.graphics.isGammaCorrect() then

	idops.map_premultiply = idops.map_premultiplyCorrected
	idops.map_predivide = idops.map_predivideCorrected

else
	idops.map_premultiply = idops.map_premultiplyUncorrected
	idops.map_predivide = idops.map_predivideUncorrected	
end


return idops
