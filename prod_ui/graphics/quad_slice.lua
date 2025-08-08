--[[
QuadSlice: a 9-slice library for LÖVE.
See README.md for usage notes.

Version: 1.3.1

License: MIT

Copyright (c) 2022 - 2025 RBTS / Frank F. Trafton

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


--[[
* Quad layout

	   x    w1   w2   w3
	y  +----+----+----+
	   |q1  |q2  |q3  |
	h1 +----+----+----+
	   |q4  |q5  |q6  |
	h2 +----+----+----+
	   |q7  |q8  |q9  |
	h3 +----+----+----+


* Mirroring

	Horizontal: (3, 6, 9) -> (1, 4, 7)

	Vertical:   (7, 8, 9) -> (1, 2, 3)

	Both:       (3, 6) -> (1, 4)
	            (7, 8) -> (1, 2)
	            (9)    -> (1)
--]]


local quadSlice = {}


local math, type = math, type
local _lg_draw, _lg_newQuad = love.graphics.draw, love.graphics.newQuad


local zero_quad -- assigned upon first use of quadSlice.newSlice().


local _mt_slice = {}
_mt_slice.__index = _mt_slice
quadSlice._mt_slice = _mt_slice


-- * Internal *


local function errGEZero(id, arg_n, level)
	error("argument #" .. arg_n .. " (" .. id .. ") must be a number >= 0.", level or 2)
end


local function errBadType(id, arg_n, val, expected, level)
	error("argument #" .. arg_n .. " (" .. id .. "): bad type (expected " .. expected .. ", got " .. type(val) .. ").", level or 2)
end


local function assertDrawParams(arg_n_start, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
	if type(quads) ~= "table" then errBadType("quads", arg_n_start + 0, quads, "table", 3)
	elseif type(x) ~= "number" then errBadType("x", arg_n_start + 1, x, "number", 3)
	elseif type(y) ~= "number" then errBadType("y", arg_n_start + 2, y, "number", 3)
	elseif type(w1) ~= "number" then errBadType("w1", arg_n_start + 3, w1, "number", 3)
	elseif type(h1) ~= "number" then errBadType("h1", arg_n_start + 4, h1, "number", 3)
	elseif type(w2) ~= "number" then errBadType("w2", arg_n_start + 5, w2, "number", 3)
	elseif type(h2) ~= "number" then errBadType("h2", arg_n_start + 6, h2, "number", 3)
	elseif type(w3) ~= "number" then errBadType("w3", arg_n_start + 7, w3, "number", 3)
	elseif type(h3) ~= "number" then errBadType("h3", arg_n_start + 8, h3, "number", 3)
	elseif type(sw1) ~= "number" then errBadType("sw1", arg_n_start +  9, sw1, "number", 3)
	elseif type(sh1) ~= "number" then errBadType("sh1", arg_n_start + 10, sh1, "number", 3)
	elseif type(sw2) ~= "number" then errBadType("sw2", arg_n_start + 11, sw2, "number", 3)
	elseif type(sh2) ~= "number" then errBadType("sh2", arg_n_start + 12, sh2, "number", 3)
	elseif type(sw3) ~= "number" then errBadType("sw3", arg_n_start + 13, sw3, "number", 3)
	elseif type(sh3) ~= "number" then errBadType("sh3", arg_n_start + 14, sh3, "number", 3) end
end


local function assertDraw(arg_n_start, x, y, w, h)
	if type(x) ~= "number" then errBadType("x", arg_n_start + 0, x, "number", 3)
	elseif type(y) ~= "number" then errBadType("y", arg_n_start + 1, y, "number", 3)
	elseif type(w) ~= "number" then errBadType("w", arg_n_start + 2, w, "number", 3)
	elseif type(h) ~= "number" then errBadType("h", arg_n_start + 3, h, "number", 3) end
end


local function checkMirroring(quad, xa, ya, wa, ha, xb, yb, wb, hb, iw, ih, mirror_h, mirror_v)
	-- If the tile should be mirrored, apply inverted copies of the 'xb', 'yb', 'wb'
	-- and 'hb' coordinates as needed.
	if mirror_h then
		xa = -(xb + wb)
	end
	if mirror_v then
		ya = -(yb + hb)
	end

	quad:setViewport(xa, ya, wa, ha, iw, ih)
end


-- Called by Slice:setTileEnabled(). This should not be called on `zero_quad`.
local tbl_fn_enable_tile = {
	-- s == self, q == quad

	-- 1
	function(s, q) q:setViewport(s.x, s.y, s.w1, s.h1, s.iw, s.ih) end,

	-- 2
	function(s, q) q:setViewport(s.x + s.w1, s.y, s.w2, s.h1, s.iw, s.ih) end,

	-- 3
	function(s, q)
		checkMirroring(q,
			s.x + s.w1 + s.w2, s.y, s.w3, s.h1,
			s.x, s.y, s.w1, s.h1, -- [from tile 1]
			s.iw, s.ih, s.mirror_h, false
		)
	end,

	-- 4
	function(s, q) q:setViewport(s.x, s.y + s.h1, s.w1, s.h2, s.iw, s.ih) end,

	-- 5
	function(s, q) q:setViewport(s.x + s.w1, s.y + s.h1, s.w2, s.h2, s.iw, s.ih) end,

	-- 6
	function(s, q)
		checkMirroring(q,
			s.x + s.w1 + s.w2, s.y + s.h1, s.w3, s.h2,
			s.x, s.y + s.h1, s.w1, s.h2, -- [from tile 4]
			s.iw, s.ih, s.mirror_h, false
		)
	end,

	-- 7
	function(s, q)
		checkMirroring(q,
		s.x, s.y + s.h1 + s.h2, s.w1, s.h3,
		s.x, s.y, s.w1, s.h1, -- [from tile 1]
		s.iw, s.ih, false, s.mirror_v
	)
	end,

	-- 8
	function(s, q)
		checkMirroring(q,
			s.x + s.w1, s.y + s.h1 + s.h2, s.w2, s.h3,
			s.x + s.w1, s.y, s.w2, s.h1, -- [from tile 2]
			s.iw, s.ih, false, s.mirror_v
		)
	end,

	-- 9
	function(s, q)
		if s.mirror_h and s.mirror_v then
			checkMirroring(q,
				s.x + s.w1 + s.w2, s.y + s.h1 + s.h2, s.w3, s.h3,
				s.x, s.y, s.w1, s.h1, -- [from tile 1]
				s.iw, s.ih, s.mirror_h, s.mirror_v
			)

		elseif s.mirror_h then
			checkMirroring(q,
				s.x + s.w1 + s.w2, s.y + s.h1 + s.h2, s.w3, s.h3,
				s.x, s.y + s.h1 + s.h2, s.w1, s.h3, -- [from tile 7]
				s.iw, s.ih, s.mirror_h, false
			)

		elseif s.mirror_v then
			checkMirroring(q,
				s.x + s.w1 + s.w2, s.y + s.h1 + s.h2, s.w3, s.h3,
				s.x + s.w1 + s.w2, s.y, s.w3, s.h1, -- [from tile 3]
				s.iw, s.ih, false, s.mirror_v
			)

		else
			q:setViewport(s.x + s.w1 + s.w2, s.y + s.h1 + s.h2, s.w3, s.h3, s.iw, s.ih)
		end
	end,
}


-- * Slice table creation *


function quadSlice.newSlice(x,y, w1,h1, w2,h2, w3,h3, iw,ih)
	-- Assertions
	-- [[
	if type(x) ~= "number" then errBadType("x", 1, x, "number", 3)
	elseif type(y) ~= "number" then errBadType("y", 2, y, "number", 3)
	elseif type(w1) ~= "number" or w1 < 0 then errGEZero("w1", 3, 3)
	elseif type(h1) ~= "number" or h1 < 0 then errGEZero("h1", 4, 3)
	elseif type(w2) ~= "number" or w2 < 0 then errGEZero("w2", 5, 3)
	elseif type(h2) ~= "number" or h2 < 0 then errGEZero("h2", 6, 3)
	elseif type(w3) ~= "number" or w3 < 0 then errGEZero("w3", 7, 3)
	elseif type(h3) ~= "number" or h3 < 0 then errGEZero("h3", 8, 3)
	elseif type(iw) ~= "number" or iw < 0 then errGEZero("iw", 9, 3)
	elseif type(ih) ~= "number" or ih < 0 then errGEZero("ih", 10, 3) end
	--]]

	local self = setmetatable({}, _mt_slice)

	self.iw, self.ih = iw, ih
	self.x, self.y = x, y

	self.w, self.h = (w1 + w2 + w3), (h1 + h2 + h3)

	self.w1, self.h1 = w1, h1
	self.w2, self.h2 = w2, h2
	self.w3, self.h3 = w3, h3

	self.mirror_h = false
	self.mirror_v = false

	local quads = {}
	self.quads = quads

	-- Any tiles with zero width or height are assigned a reference to a zero-width,
	-- zero-height dummy quad.

	zero_quad = zero_quad or _lg_newQuad(0, 0, 0, 0, 1, 1)

	for i = 1, 9 do
		quads[i] = zero_quad
	end
	if h1 > 0 then
		if w1 > 0 then quads[1] = _lg_newQuad(0, 0, 0, 0, self.iw, self.ih) end
		if w2 > 0 then quads[2] = _lg_newQuad(0, 0, 0, 0, self.iw, self.ih) end
		if w3 > 0 then quads[3] = _lg_newQuad(0, 0, 0, 0, self.iw, self.ih) end
	end
	if h2 > 0 then
		if w1 > 0 then quads[4] = _lg_newQuad(0, 0, 0, 0, self.iw, self.ih) end
		if w2 > 0 then quads[5] = _lg_newQuad(0, 0, 0, 0, self.iw, self.ih) end
		if w3 > 0 then quads[6] = _lg_newQuad(0, 0, 0, 0, self.iw, self.ih) end
	end
	if h3 > 0 then
		if w1 > 0 then quads[7] = _lg_newQuad(0, 0, 0, 0, self.iw, self.ih) end
		if w2 > 0 then quads[8] = _lg_newQuad(0, 0, 0, 0, self.iw, self.ih) end
		if w3 > 0 then quads[9] = _lg_newQuad(0, 0, 0, 0, self.iw, self.ih) end
	end

	self:resetTiles()

	return self
end


-- * Slice state *


function _mt_slice:resetTiles()
	local quads = self.quads
	for i = 1, 9 do
		self:setTileEnabled(i, true)
	end
end


function _mt_slice:setTileEnabled(index, enabled)
	-- Assertions
	-- [[
	if type(index) ~= "number" then errBadType("index", 1, index, "number", 2)
	elseif index < 1 or index > 9 then error("tile index is out of range (expected 1-9, got: " .. tostring(index) .. ").") end
	--]]

	index = math.floor(index)
	local this_quad = self.quads[index]

	if this_quad ~= zero_quad then
		if enabled then
			tbl_fn_enable_tile[index](self, this_quad)
		else
			this_quad:setViewport(0, 0, 0, 0)
		end
	end
end


function _mt_slice:setMirroring(mirror_h, mirror_v)
	-- NOTE: this has no effect on the mesh helper functions, as they don't use LÖVE quads.

	self.mirror_h = not not mirror_h
	self.mirror_v = not not mirror_v

	self:resetTiles()
end


-- * Slice positioning and drawing *


function _mt_slice:getDrawParams(w, h)
	-- Assertions -- commented out by default.
	--[[
	if type(w) ~= "number" then errBadType("w", 1, w, "number")
	elseif type(h) ~= "number" then errBadType("h", 2, h, "number") end
	--]]

	w, h = math.max(0, w), math.max(0, h)

	local w1, h1 = self.w1, self.h1
	local w3, h3 = self.w3, self.h3
	local w2, h2 = math.max(0, w - (w1 + w3)), math.max(0, h - (h1 + h3))

	-- Crunch down edge tiles if there is not enough space.
	if w1 + w3 > 0 then -- avoid div/0
		w1 = math.min(w1, w1 * (w / (w1 + w3)))
		w3 = math.min(w3, w3 * (w / (w1 + w3)))
	end

	if h1 + h3 > 0 then -- avoid div/0
		h1 = math.min(h1, h1 * (h / (h1 + h3)))
		h3 = math.min(h3, h3 * (h / (h1 + h3)))
	end

	local sw1 = (self.w1 > 0) and w1 / self.w1 or 0
	local sh1 = (self.h1 > 0) and h1 / self.h1 or 0

	local sw2 = (self.w2 > 0) and w2 / self.w2 or 0
	local sh2 = (self.h2 > 0) and h2 / self.h2 or 0

	local sw3 = (self.w3 > 0) and w3 / self.w3 or 0
	local sh3 = (self.h3 > 0) and h3 / self.h3 or 0

	return w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3
end
local _getDrawParams = _mt_slice.getDrawParams


function _mt_slice:draw(texture, x, y, w, h)
	-- Assertions -- commented out by default.
	--[[
	if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
	assertDraw(2, x, y, w, h)
	--]]

	w, h = math.max(0, w), math.max(0, h)

	self.drawFromParams(texture, self.quads, x,y, _getDrawParams(self, w, h))
end


-- NOTE: Uses dot notation.
function _mt_slice.drawFromParams(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
	-- Assertions -- commented out by default
	--[[
	if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
	assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
	--]]

	_lg_draw(texture, quads[1], x, y, 0, sw1, sh1)
	_lg_draw(texture, quads[2], x + w1, y, 0, sw2, sh1)
	_lg_draw(texture, quads[3], x + w1 + w2, y, 0, sw3, sh1)

	_lg_draw(texture, quads[4], x, y + h1, 0, sw1, sh2)
	_lg_draw(texture, quads[5], x + w1, y + h1, 0, sw2, sh2)
	_lg_draw(texture, quads[6], x + w1 + w2, y + h1, 0, sw3, sh2)

	_lg_draw(texture, quads[7], x, y + h1 + h2, 0, sw1, sh3)
	_lg_draw(texture, quads[8], x + w1, y + h1 + h2, 0, sw2, sh3)
	_lg_draw(texture, quads[9], x + w1 + w2, y + h1 + h2, 0, sw3, sh3)
end


function _mt_slice:batchAdd(batch, x, y, w, h)
	-- Assertions -- commented out by default.
	--[[
	if type(batch) ~= "userdata" then errBadType("batch", 1, batch, "userdata (LÖVE SpriteBatch)") end
	assertDraw(2, x, y, w, h)
	--]]

	w, h = math.max(0, w), math.max(0, h)

	local last_index = self:batchAddFromParams(batch, self.quads, x, y, _getDrawParams(self, w, h))

	return last_index
end


function _mt_slice:batchAddFromParams(batch, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
	-- Assertions -- commented out by default.
	--[[
	if type(batch) ~= "userdata" then errBadType("batch", 1, batch, "userdata (LÖVE SpriteBatch)") end
	assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
	--]]

	-- Top row
	batch:add(quads[1], x, y, 0, sw1, sh1)
	batch:add(quads[2], x + w1, y, 0, sw2, sh1)
	batch:add(quads[3], x + w1 + w2, y, 0, sw3, sh1)

	-- Middle row
	batch:add(quads[4], x, y + h1, 0, sw1, sh2)
	batch:add(quads[5], x + w1, y + h1, 0, sw2, sh2)
	batch:add(quads[6], x + w1 + w2, y + h1, 0, sw3, sh2)

	-- Bottom row
	batch:add(quads[7], x, y + h1 + h2, 0, sw1, sh3)
	batch:add(quads[8], x + w1, y + h1 + h2, 0, sw2, sh3)
	local last_index = batch:add(quads[9], x + w1 + w2, y + h1 + h2, 0, sw3, sh3)

	return last_index
end


function _mt_slice:batchSet(batch, index, x, y, w, h)
	-- Assertions -- commented out by default.
	--[[
	if type(batch) ~= "userdata" then errBadType("batch", 1, batch, "userdata (LÖVE SpriteBatch)")
	elseif type(index) ~= "number" then errBadType("index", 2, index, "number") end
	assertDraw(3, x, y, w, h)
	--]]

	w, h = math.max(0, w), math.max(0, h)

	self:batchSetFromParams(batch, index, self.quads, x, y, _getDrawParams(self, w, h))
end


function _mt_slice:batchSetFromParams(batch, index, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
	-- Assertions -- commented out by default.
	--[[
	if type(batch) ~= "userdata" then errBadType("batch", 1, batch, "userdata (LÖVE SpriteBatch)")
	elseif type(index) ~= "number" then errBadType("index", 2, index, "number") end
	assertDrawParams(3, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
	--]]

	-- Top row
	batch:set(index, quads[1], x, y, 0, sw1, sh1)
	batch:set(index + 1, quads[2], x + w1, y, 0, sw2, sh1)
	batch:set(index + 2, quads[3], x + w1 + w2, y, 0, sw3, sh1)

	-- Middle row
	batch:set(index + 3, quads[4], x, y + h1, 0, sw1, sh2)
	batch:set(index + 4, quads[5], x + w1, y + h1, 0, sw2, sh2)
	batch:set(index + 5, quads[6], x + w1 + w2, y + h1, 0, sw3, sh2)

	-- Bottom row
	batch:set(index + 6, quads[7], x, y + h1 + h2, 0, sw1, sh3)
	batch:set(index + 7, quads[8], x + w1, y + h1 + h2, 0, sw2, sh3)
	batch:set(index + 8, quads[9], x + w1 + w2, y + h1 + h2, 0, sw3, sh3)
end


-- * Mesh helpers *


--[[
	Actual drawing of the mesh is left to the library user.
	See 'test_mesh_render.lua' for a basic example.
--]]


function _mt_slice:getTextureUV()
	local iw, ih = self.iw, self.ih

	local sx1 = self.x / iw
	local sy1 = self.y / ih
	local sx2 = (self.x + self.w1) / iw
	local sy2 = (self.y + self.h1) / ih
	local sx3 = (self.x + self.w1 + self.w2) / iw
	local sy3 = (self.y + self.h1 + self.h2) / ih
	local sx4 = (self.x + self.w1 + self.w2 + self.w3) / iw
	local sy4 = (self.y + self.h1 + self.h2 + self.h3) / ih

	return sx1, sy1, sx2, sy2, sx3, sy3, sx4, sy4
end


function _mt_slice:getStretchedVertices(w, h)
	-- No assertions.

	-- (Don't enforce a minimum width or height of 0 in this case.)

	-- Crunch down edges
	-- [[
	local crunch_w = self.w > 0 and math.min(1, w / self.w) or 0
	local crunch_h = self.h > 0 and math.min(1, h / self.h) or 0
	local w1 = math.floor(self.w1 * crunch_w)
	local h1 = math.floor(self.h1 * crunch_h)
	local w3 = math.floor(self.w3 * crunch_w)
	local h3 = math.floor(self.h3 * crunch_h)
	--]]

	local x2 = w1
	local y2 = h1
	local x3 = math.max(x2, w - w3)
	local y3 = math.max(y2, h - h3)

	return 0, 0, x2, y2, x3, y3, w, h
end


-- * Alternative draw functions * --


--[[
Here is a set of alternative drawing functions. `full` is a copy of the default. The others omit
certain tiles, which might reduce overhead in cases where many partial slices are drawn. (Profile
to be sure.)

Usage: overwrite `slice.drawFromParams` with the desired function.

`slice.drawFromParams = nil` will revert to the default.

These have no impact on manual SpriteBatch or Mesh methods.

Assertions are commented out by default.
--]]
quadSlice.draw_functions = {
	blank = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
	end,

	center = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[5], x + w1, y + h1, 0, sw2, sh2)
	end,

	corners = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[1], x, y, 0, sw1, sh1)
		_lg_draw(texture, quads[3], x + w1 + w2, y, 0, sw3, sh1)
		_lg_draw(texture, quads[7], x, y + h1 + h2, 0, sw1, sh3)
		_lg_draw(texture, quads[9], x + w1 + w2, y + h1 + h2, 0, sw3, sh3)
	end,

	-- Top row
	x0y0w3h1 = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[1], x, y, 0, sw1, sh1)
		_lg_draw(texture, quads[2], x + w1, y, 0, sw2, sh1)
		_lg_draw(texture, quads[3], x + w1 + w2, y, 0, sw3, sh1)
	end,

	-- Middle row
	x0y1w3h1 = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[4], x, y + h1, 0, sw1, sh2)
		_lg_draw(texture, quads[5], x + w1, y + h1, 0, sw2, sh2)
		_lg_draw(texture, quads[6], x + w1 + w2, y + h1, 0, sw3, sh2)
	end,

	-- Bottom row
	x0y2w3h1 = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[7], x, y + h1 + h2, 0, sw1, sh3)
		_lg_draw(texture, quads[8], x + w1, y + h1 + h2, 0, sw2, sh3)
		_lg_draw(texture, quads[9], x + w1 + w2, y + h1 + h2, 0, sw3, sh3)
	end,

	-- Left column
	x0y0w1h3 = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[1], x, y, 0, sw1, sh1)
		_lg_draw(texture, quads[4], x, y + h1, 0, sw1, sh2)
		_lg_draw(texture, quads[7], x, y + h1 + h2, 0, sw1, sh3)
	end,

	-- Middle column
	x1y0w1h3 = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[2], x + w1, y, 0, sw2, sh1)
		_lg_draw(texture, quads[5], x + w1, y + h1, 0, sw2, sh2)
		_lg_draw(texture, quads[8], x + w1, y + h1 + h2, 0, sw2, sh3)
	end,

	-- Right column
	x2y0w1h3 = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[3], x + w1 + w2, y, 0, sw3, sh1)
		_lg_draw(texture, quads[6], x + w1 + w2, y + h1, 0, sw3, sh2)
		_lg_draw(texture, quads[9], x + w1 + w2, y + h1 + h2, 0, sw3, sh3)
	end,

	-- 2x2 upper-left
	x0y0w2h2 = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[1], x, y, 0, sw1, sh1)
		_lg_draw(texture, quads[2], x + w1, y, 0, sw2, sh1)
		_lg_draw(texture, quads[4], x, y + h1, 0, sw1, sh2)
		_lg_draw(texture, quads[5], x + w1, y + h1, 0, sw2, sh2)
	end,

	-- 2x2 upper-right
	x1y0w2h2 = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[2], x + w1, y, 0, sw2, sh1)
		_lg_draw(texture, quads[3], x + w1 + w2, y, 0, sw3, sh1)
		_lg_draw(texture, quads[5], x + w1, y + h1, 0, sw2, sh2)
		_lg_draw(texture, quads[6], x + w1 + w2, y + h1, 0, sw3, sh2)
	end,

	-- 2x2 bottom-left
	x0y1w2h2 = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[4], x, y + h1, 0, sw1, sh2)
		_lg_draw(texture, quads[5], x + w1, y + h1, 0, sw2, sh2)
		_lg_draw(texture, quads[7], x, y + h1 + h2, 0, sw1, sh3)
		_lg_draw(texture, quads[8], x + w1, y + h1 + h2, 0, sw2, sh3)
	end,

	-- 2x2 bottom-right
	x1y1w2h2 = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[5], x + w1, y + h1, 0, sw2, sh2)
		_lg_draw(texture, quads[6], x + w1 + w2, y + h1, 0, sw3, sh2)
		_lg_draw(texture, quads[8], x + w1, y + h1 + h2, 0, sw2, sh3)
		_lg_draw(texture, quads[9], x + w1 + w2, y + h1 + h2, 0, sw3, sh3)
	end,

	-- 1x2 middle + top
	x1y0w1h2 = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[2], x + w1, y, 0, sw2, sh1)
		_lg_draw(texture, quads[5], x + w1, y + h1, 0, sw2, sh2)
	end,

	-- 1x2 middle + bottom
	x1y1w1h2 = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[5], x + w1, y + h1, 0, sw2, sh2)
		_lg_draw(texture, quads[8], x + w1, y + h1 + h2, 0, sw2, sh3)
	end,

	-- 2x1 middle + left
	x0y1w2h1 = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[4], x, y + h1, 0, sw1, sh2)
		_lg_draw(texture, quads[5], x + w1, y + h1, 0, sw2, sh2)
	end,

	-- 2x1 middle + right
	x1y1w2h1 = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[5], x + w1, y + h1, 0, sw2, sh2)
		_lg_draw(texture, quads[6], x + w1 + w2, y + h1, 0, sw3, sh2)
	end,

	-- 3x2 top and middle
	x0y0w3h2 = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[1], x, y, 0, sw1, sh1)
		_lg_draw(texture, quads[2], x + w1, y, 0, sw2, sh1)
		_lg_draw(texture, quads[3], x + w1 + w2, y, 0, sw3, sh1)

		_lg_draw(texture, quads[4], x, y + h1, 0, sw1, sh2)
		_lg_draw(texture, quads[5], x + w1, y + h1, 0, sw2, sh2)
		_lg_draw(texture, quads[6], x + w1 + w2, y + h1, 0, sw3, sh2)
	end,

	-- 3x2 top and middle (hollow)
	x0y03h2_h = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[1], x, y, 0, sw1, sh1)
		_lg_draw(texture, quads[2], x + w1, y, 0, sw2, sh1)
		_lg_draw(texture, quads[3], x + w1 + w2, y, 0, sw3, sh1)

		_lg_draw(texture, quads[4], x, y + h1, 0, sw1, sh2)
		_lg_draw(texture, quads[6], x + w1 + w2, y + h1, 0, sw3, sh2)
	end,

	-- 3x2 middle and bottom
	x0y1w3h2 = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[4], x, y + h1, 0, sw1, sh2)
		_lg_draw(texture, quads[5], x + w1, y + h1, 0, sw2, sh2)
		_lg_draw(texture, quads[6], x + w1 + w2, y + h1, 0, sw3, sh2)

		_lg_draw(texture, quads[7], x, y + h1 + h2, 0, sw1, sh3)
		_lg_draw(texture, quads[8], x + w1, y + h1 + h2, 0, sw2, sh3)
		_lg_draw(texture, quads[9], x + w1 + w2, y + h1 + h2, 0, sw3, sh3)
	end,

	-- 3x2 middle and bottom (hollow)
	x0y1w3h2_h = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[4], x, y + h1, 0, sw1, sh2)
		_lg_draw(texture, quads[6], x + w1 + w2, y + h1, 0, sw3, sh2)

		_lg_draw(texture, quads[7], x, y + h1 + h2, 0, sw1, sh3)
		_lg_draw(texture, quads[8], x + w1, y + h1 + h2, 0, sw2, sh3)
		_lg_draw(texture, quads[9], x + w1 + w2, y + h1 + h2, 0, sw3, sh3)
	end,

	-- 2x3 left and middle
	x0y0w2h3 = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[1], x, y, 0, sw1, sh1)
		_lg_draw(texture, quads[2], x + w1, y, 0, sw2, sh1)

		_lg_draw(texture, quads[4], x, y + h1, 0, sw1, sh2)
		_lg_draw(texture, quads[5], x + w1, y + h1, 0, sw2, sh2)

		_lg_draw(texture, quads[7], x, y + h1 + h2, 0, sw1, sh3)
		_lg_draw(texture, quads[8], x + w1, y + h1 + h2, 0, sw2, sh3)
	end,

	-- 2x3 left and middle (hollow)
	x0y0w2h3_h = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[1], x, y, 0, sw1, sh1)
		_lg_draw(texture, quads[2], x + w1, y, 0, sw2, sh1)

		_lg_draw(texture, quads[4], x, y + h1, 0, sw1, sh2)

		_lg_draw(texture, quads[7], x, y + h1 + h2, 0, sw1, sh3)
		_lg_draw(texture, quads[8], x + w1, y + h1 + h2, 0, sw2, sh3)
	end,

	-- 2x3 middle and right
	x1y0w2h3 = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[2], x + w1, y, 0, sw2, sh1)
		_lg_draw(texture, quads[3], x + w1 + w2, y, 0, sw3, sh1)

		_lg_draw(texture, quads[5], x + w1, y + h1, 0, sw2, sh2)
		_lg_draw(texture, quads[6], x + w1 + w2, y + h1, 0, sw3, sh2)

		_lg_draw(texture, quads[8], x + w1, y + h1 + h2, 0, sw2, sh3)
		_lg_draw(texture, quads[9], x + w1 + w2, y + h1 + h2, 0, sw3, sh3)
	end,

	-- 2x3 middle and right (hollow)
	x1y0w2h3_h = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[2], x + w1, y, 0, sw2, sh1)
		_lg_draw(texture, quads[3], x + w1 + w2, y, 0, sw3, sh1)

		_lg_draw(texture, quads[6], x + w1 + w2, y + h1, 0, sw3, sh2)

		_lg_draw(texture, quads[8], x + w1, y + h1 + h2, 0, sw2, sh3)
		_lg_draw(texture, quads[9], x + w1 + w2, y + h1 + h2, 0, sw3, sh3)
	end,

	-- 3x3 hollow, open top
	hollow_top = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[1], x, y, 0, sw1, sh1)
		_lg_draw(texture, quads[3], x + w1 + w2, y, 0, sw3, sh1)

		_lg_draw(texture, quads[4], x, y + h1, 0, sw1, sh2)
		_lg_draw(texture, quads[6], x + w1 + w2, y + h1, 0, sw3, sh2)

		_lg_draw(texture, quads[7], x, y + h1 + h2, 0, sw1, sh3)
		_lg_draw(texture, quads[8], x + w1, y + h1 + h2, 0, sw2, sh3)
		_lg_draw(texture, quads[9], x + w1 + w2, y + h1 + h2, 0, sw3, sh3)
	end,

	-- 3x3 hollow, open bottom
	hollow_bottom = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[1], x, y, 0, sw1, sh1)
		_lg_draw(texture, quads[2], x + w1, y, 0, sw2, sh1)
		_lg_draw(texture, quads[3], x + w1 + w2, y, 0, sw3, sh1)

		_lg_draw(texture, quads[4], x, y + h1, 0, sw1, sh2)
		_lg_draw(texture, quads[6], x + w1 + w2, y + h1, 0, sw3, sh2)

		_lg_draw(texture, quads[7], x, y + h1 + h2, 0, sw1, sh3)
		_lg_draw(texture, quads[9], x + w1 + w2, y + h1 + h2, 0, sw3, sh3)
	end,

	-- 3x3 hollow, open left
	hollow_left = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[1], x, y, 0, sw1, sh1)
		_lg_draw(texture, quads[2], x + w1, y, 0, sw2, sh1)
		_lg_draw(texture, quads[3], x + w1 + w2, y, 0, sw3, sh1)

		_lg_draw(texture, quads[6], x + w1 + w2, y + h1, 0, sw3, sh2)

		_lg_draw(texture, quads[7], x, y + h1 + h2, 0, sw1, sh3)
		_lg_draw(texture, quads[8], x + w1, y + h1 + h2, 0, sw2, sh3)
		_lg_draw(texture, quads[9], x + w1 + w2, y + h1 + h2, 0, sw3, sh3)
	end,

	-- 3x3 hollow, open right
	hollow_right = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[1], x, y, 0, sw1, sh1)
		_lg_draw(texture, quads[2], x + w1, y, 0, sw2, sh1)
		_lg_draw(texture, quads[3], x + w1 + w2, y, 0, sw3, sh1)

		_lg_draw(texture, quads[4], x, y + h1, 0, sw1, sh2)

		_lg_draw(texture, quads[7], x, y + h1 + h2, 0, sw1, sh3)
		_lg_draw(texture, quads[8], x + w1, y + h1 + h2, 0, sw2, sh3)
		_lg_draw(texture, quads[9], x + w1 + w2, y + h1 + h2, 0, sw3, sh3)
	end,

	-- 3x3 full slice
	full = _mt_slice.drawFromParams,

	-- 3x3 (hollow)
	hollow = function(texture, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)
		--if type(texture) ~= "userdata" then errBadType("texture", 1, texture, "userdata (LÖVE Texture)") end
		--assertDrawParams(2, quads, x,y, w1,h1, w2,h2, w3,h3, sw1,sh1, sw2,sh2, sw3,sh3)

		_lg_draw(texture, quads[1], x, y, 0, sw1, sh1)
		_lg_draw(texture, quads[2], x + w1, y, 0, sw2, sh1)
		_lg_draw(texture, quads[3], x + w1 + w2, y, 0, sw3, sh1)

		_lg_draw(texture, quads[4], x, y + h1, 0, sw1, sh2)
		_lg_draw(texture, quads[6], x + w1 + w2, y + h1, 0, sw3, sh2)

		_lg_draw(texture, quads[7], x, y + h1 + h2, 0, sw1, sh3)
		_lg_draw(texture, quads[8], x + w1, y + h1 + h2, 0, sw2, sh3)
		_lg_draw(texture, quads[9], x + w1 + w2, y + h1 + h2, 0, sw3, sh3)
	end
}


return quadSlice
