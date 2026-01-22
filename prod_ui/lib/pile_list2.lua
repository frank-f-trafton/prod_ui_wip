-- PILE List2
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


local M = {}


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local interp = require(PATH .. "pile_interp")
local pAssert = require(PATH .. "pile_assert")


M.lang = {
	assert_cycles = "linked list contains a cycle (duplicate node reference) or corrupt link",
	self_ref = "attempted to link a node to itself",
}
local lang = M.lang


function M.nodeNew()
	return {["prev"] = false, ["next"] = false}
end


function M.nodeLink(from, to)
	if from == to then
		error(lang.self_ref)
	end

	if from["next"] then
		from["next"]["prev"] = false
	end
	if to["prev"] then
		to["prev"]["next"] = false
	end

	from["next"], to["prev"] = to, from
end


function M.nodeUnlink(self)
	local temp_next, temp_prev = self["next"], self["prev"]

	if temp_prev then
		temp_prev["next"] = temp_next or false
	end
	if temp_next then
		temp_next["prev"] = temp_prev or false
	end

	self["next"], self["prev"] = false, false
end


function M.nodeUnlinkNext(self)
	if self["next"] then
		self["next"]["prev"] = false
		self["next"] = false
	end
end


function M.nodeUnlinkPrevious(self)
	if self["prev"] then
		self["prev"]["next"] = false
		self["prev"] = false
	end
end


local function _checkForCycles(node, label, seen)
	local node2 = node[label]
	local last_node = node
	while node2 do
		last_node = node2
		if seen[node2] then
			error(lang.assert_cycles)
		end
		seen[node2] = true
		node2 = node2[label]
	end
	return last_node
end


function M.nodeAssertNoCycles(self)
	local seen = {self=true}
	local head = _checkForCycles(self, "prev", seen)
	local tail = _checkForCycles(self, "next", seen)

	_checkForCycles(head, "next", {head=true})
	_checkForCycles(tail, "prev", {tail=true})
end


function M.nodeGetHead(self)
	local node = self
	while node["prev"] do
		node = node["prev"]
	end
	return node
end


function M.nodeGetTail(self)
	local node = self
	while node["next"] do
		node = node["next"]
	end
	return node
end


function M.nodeGetNext(self)
	return self["next"] or nil
end


function M.nodeGetPrevious(self)
	return self["prev"] or nil
end


function M.nodeIterateNext(t)
	pAssert.type(1, t, "table")

	local first = true
	local iter = function(t, node)
		if first then
			first = false
			return t
		end

		return node["next"] or nil
	end

	return iter, t, nil
end


function M.nodeIteratePrevious(t)
	pAssert.type(1, t, "table")

	local first = true
	local iter = function(t, node)
		if first then
			first = false
			return t
		end

		return node["prev"] or nil
	end

	return iter, t, nil
end


local function _nodeInListForward(self, check)
	pAssert.type(2, check, "table")

	local node = self
	while node do
		if node == check then
			return true
		end
		node = node["next"]
	end

	return false
end
M.nodeInListForward = _nodeInListForward


local function _nodeInListBackward(self, check)
	pAssert.type(2, check, "table")

	local node = self
	while node do
		if node == check then
			return true
		end
		node = node["prev"]
	end

	return false
end
M.nodeInListBackward = _nodeInListBackward


function M.nodeInList(self, check)
	local prev = self["prev"]
	return _nodeInListForward(self, check) or (prev and _nodeInListBackward(prev, check))
end


return M
