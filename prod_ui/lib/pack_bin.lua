--[[
Based on: https://github.com/jakesgordon/bin-packing/blob/master/js/packer.js

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


local packBin = {}


local _mt_bin = {}
_mt_bin.__index = _mt_bin


function packBin.newBin(width, height, offset_x, offset_y)

	offset_x = offset_x or 0
	offset_y = offset_y or 0

	local bin = setmetatable({}, _mt_bin)

	bin.root = {
		x = offset_x,
		y = offset_y,
		w = width,
		h = height,
	}

	return bin
end


local function findNode(root, w, h)

	if root.used then
		return findNode(root.right, w, h) or findNode(root.down, w, h)

	elseif w <= root.w and h <= root.h then
		return root
	end
	-- (return nil)
end


local function splitNode(node, w, h)

	node.used = true
	node.down = {x = node.x, y = node.y + h, w = node.w, h = node.h - h}
	node.right = {x = node.x + w, y = node.y, w = node.w - w, h = h}

	return node
end


function _mt_bin:fit(boxes, padding)

	padding = padding or 0

	for _, box in ipairs(boxes) do
		local node = findNode(self.root, box.w + padding, box.h + padding)

		if node then
			box.fit = splitNode(node, box.w + padding, box.h + padding)

		else
			return false
		end
	end

	return true
end


return packBin
