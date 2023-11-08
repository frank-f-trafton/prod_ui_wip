-- (BETA 0.0.3)
--[[
AtlasB: A texture atlas generator using a binary packing algorithm.
The resulting textures are always square and power-of-two in size.
--]]

--[[
MIT License

Copyright (c) 2023 RBTS

The binary tree packer is based on:
https://github.com/jakesgordon/bin-packing/blob/master/js/packer.js

Copyright (c) 2011, 2012, 2013, 2014, 2015, 2016 Jake Gordon and contributors
Lua version (c) 2020, 2023 RBTS

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


local atlasB = {}


-- * General *


local function errInt(arg_n, optional, op, n)

	local str_between = optional and " expected false/nil or" or "must be"
	error("argument #" .. arg_n .. ": " .. str_between .. " an integer " .. op .. " " .. n .. ".", 2)
end


local function errArgType(n, expected, val)
	error("argument #" .. n .. ": bad type (expected " .. expected .. ", got " .. type(val) .. ")", 2)
end


local function extrudeSubImage(src, x, y, w, h)

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


-- * / General *


-- * Binary tree packer *


local function newRootNode(w, h)
	return {x = 0, y = 0, w = w, h = h}
end


local function findNode(root, w, h)

	if root then
		if root.used then
			return findNode(root.right, w, h) or findNode(root.down, w, h)

		elseif w <= root.w and h <= root.h then
			return root
		end
	end

	-- (return nil)
end


local function splitNode(node, w, h)

	node.used = true

	if node.h - h > 0 then
		node.down = {x = node.x, y = node.y + h, w = node.w, h = node.h - h}
	end
	if node.w - w > 0 then
		node.right = {x = node.x + w, y = node.y, w = node.w - w, h = h}
	end

	return node
end


local function fitBoxes(root, boxes)

	for _, box in ipairs(boxes) do
		local node = findNode(root, box.w, box.h)

		if node then
			box.x = node.x
			box.y = node.y

			splitNode(node, box.w, box.h)

		else
			return false
		end
	end

	return true
end


-- * / Binary tree packer *


-- * Atlas structure *


local _mt_ab = {}
_mt_ab.__index = _mt_ab


function atlasB.newAtlas(padding, extrude, gran)

	padding = padding or 0

	-- Assertions
	-- [[
	if type(padding) ~= "number" or padding < 0 or math.floor(padding) ~= padding then errInt(1, true, ">=", 0) end
	--]]

	local self = setmetatable({}, _mt_ab)

	self.padding = padding
	self.extrude = extrude or false
	self.granular = gran or false

	-- Is a number when boxes are successfully arranged.
	self.arranged_size = false

	self.boxes = {}

	return self
end


-- The default sorting function.
function _mt_ab.boxSort(a, b)

	-- Order tallest to shortest
	if a.h ~= b.h then
		return a.h > b.h

	-- Tiebreaker: Widest to thinnest
	elseif a.w ~= b.w then
		return a.w > b.w

	-- Tiebreaker: Lowest Y
	elseif a.y ~= b.y then
		return a.y > b.y

	-- Tiebreaker: Lowest X
	elseif a.x ~= b.x then
		return a.x > b.x

	-- Tiebreaker: Order alphabetically by provided ID (typically a filename)
	elseif a.id and b.id then
		return a.id > b.id

	-- User didn't provide ID strings: give up
	else
		return tostring(a) > tostring(b)
	end
end


function _mt_ab:calculateArea()

	local area = 0

	for i, box in ipairs(self.boxes) do
		area = area + box.w * box.h
	end

	return area
end


function _mt_ab:addBox(x, y, w, h, i_data, image_id)

	-- Assertions
	-- [[
	if i_data and type(i_data) ~= "userdata" then errArgType(1, "nil/false or userdata (LÖVE ImageData)", type(i_data))
	-- 'image_id' is optional and can be anything that is usable with a comparison operator.
	-- TODO: coordinate and dimension checks.
	end
	--]]

	local box = {}
	box.i_data = i_data
	if image_id then
		box.id = image_id
	end

	-- Source rectangle within the ImageData
	box.ix = x
	box.iy = y
	box.iw = w
	box.ih = h

	-- Padded destination rectangle (to be placed later)
	box.x = 0
	box.y = 0
	box.w = w + self.padding
	box.h = h + self.padding

	if self.granular and self.padding > 1 then
		local half_pad = math.floor(self.padding / 2)
		box.w = math.ceil(box.w / half_pad) * half_pad
		box.h = math.ceil(box.h / half_pad) * half_pad
	end

	table.insert(self.boxes, box)

	return box
end


function _mt_ab:arrange(min, max)

	-- Assertions
	-- [[
	if type(min) ~= "number" or min < 1 or math.floor(min) ~= min then errInt(1, false, ">=", 1)
	elseif type(max) ~= "number" or max < 1 or math.floor(max) ~= max then errInt(2, false, ">=", 1) end
	--]]

	self.arranged_size = false

	table.sort(self.boxes, self.boxSort)

	local pad = self.padding

	local area_sq = math.sqrt(self:calculateArea())
	local size = 1

	local success
	while size <= max do
		-- Skip sizes that are smaller than the combined area of all boxes and padding.
		if size - pad >= area_sq and size >= min then
			--local bin = newRootNode(size - pad, size - pad)
			local bin = newRootNode(size, size)

			if fitBoxes(bin, self.boxes) then
				success = true
				break
			end
		end

		size = size * 2
	end

	if not success then
		return false
	end

	-- Offset all boxes right and down by half the padding value. In case of odd padding, shift boxes to the upper-left.
	local pad_12 = math.floor(pad/2)
	for _, box in ipairs(self.boxes) do
		box.x = box.x + pad_12
		box.y = box.y + pad_12
	end

	self.arranged_size = size

	return size
end


local def_r, def_g, def_b, def_a = 0, 0, 0, 0
local function mapPixel_setDefaultColor(x, y, r, g, b, a)
	return def_r, def_g, def_b, def_a
end


function _mt_ab:renderImageData(pixel_format, r, g, b, a)

	if not self.arranged_size then
		error("atlas boxes must be successfully arranged before an ImageData can be rendered.")
	end

	local i_data = love.image.newImageData(self.arranged_size, self.arranged_size, pixel_format)
	if r then
		def_r, def_g, def_b, def_a = r, g, b, a
		i_data:mapPixel(mapPixel_setDefaultColor)
	end

	for i, box in ipairs(self.boxes) do
		-- [[DBG]] print(i, box, box.x, box.y, box.iw, box.ih, box.i_data)
		i_data:paste(box.i_data, box.x, box.y, box.ix, box.iy, box.iw, box.ih)

		if self.extrude and self.padding >= 2 then
			for i = 0, (self.padding/2) - 1 do
				extrudeSubImage(i_data, box.x - i, box.y - i, box.iw + i*2, box.ih + i*2)
			end
		end
	end

	-- The final arranged rectangle coords + dimensions are in 'self.boxes':
	-- box.x, box.y, box.iw, box.ih

	return i_data
end


-- * / Atlas structure *


return atlasB
