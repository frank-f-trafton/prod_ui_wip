-- Astro core (internal) module for Sprites.


--[[
Copyright (c) 2023 RBTS

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


local astroCore = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local auxColor = require(REQ_PATH .. "aux_color")


astroCore.temp_transform = love.math.newTransform()


function astroCore.errBadType(n, val, expected)
	error("argument #" .. n .. ": bad type (expected " .. expected .. ", got " .. type(val) .. ")", 2)
end


-- Printable data types
astroCore.type_text = {
	["string"] = true,
	["table"] = true,
	["number"] = true,
}

astroCore.setColorMix = function(self)

	local rr, gg, bb, aa = love.graphics.getColor()
	auxColor.mixVV(rr, gg, bb, aa, self.r, self.g, self.b, self.a)
end


function astroCore.defaultSpriteBase(self)

	self.x = 0
	self.y = 0
	-- 'self.w' and 'self.h' are not guaranteed to be assigned.

	self.visible = true

	self.r = 1.0
	self.g = 1.0
	self.b = 1.0
	self.a = 1.0
	-- How additional colors are stored is up to the Sprite implementation.

	self.blend_mode = "alpha"
	self.alpha_mode = "alphamultiply"

	-- Parameters for love.graphics.draw() or a temporary LÖVE Transform object.
	self.rad = 0 -- rotation in radians
	self.sx = 1
	self.sy = 1
	self.ox = 0
	self.oy = 0
	self.kx = 0
	self.ky = 0

	return self
end


--- Creates a new Sprite Style.
-- @return The new Sprite Style table with common defaults.
function astroCore.newSpriteStyle()

	local self = {}
	astroCore.defaultSpriteBase(self)

	-- Default methods.
	self.setColor = astroCore.setColorMix

	return self
end


return astroCore
