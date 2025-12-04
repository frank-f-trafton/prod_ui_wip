-- PILE Linked List v2.000 (modified)
-- (C) 2024 - 2025 PILE Contributors
-- License: MIT
-- https://github.com/frank-f-trafton/pile_base


local M = {}


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local interp = require(PATH .. "pile_interp")
local pAssert = require(PATH .. "pile_assert")


M.lang = {
	assert_cycles = "linked list contains a cycle (duplicate node reference) or corrupt link",
	self_ref = "attempted to link a node to itself",
}
local lang = M.lang


function M.newNode()
	local node = {}
	node["prev"] = false
	node["next"] = false
	return node
end


function M.link(from, to)
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


function M.unlink(self)
	local temp_next, temp_prev = self["next"], self["prev"]

	if temp_prev then
		temp_prev["next"] = temp_next or false
	end
	if temp_next then
		temp_next["prev"] = temp_prev or false
	end

	self["next"], self["prev"] = false, false
end


function M.unlinkNext(self)
	if self["next"] then
		self["next"]["prev"] = false
		self["next"] = false
	end
end


function M.unlinkPrevious(self)
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


function M.assertNoCycles(self)
	local seen = {self=true}
	local head = _checkForCycles(self, "prev", seen)
	local tail = _checkForCycles(self, "next", seen)

	_checkForCycles(head, "next", {head=true})
	_checkForCycles(tail, "prev", {tail=true})
end


function M.getHead(self)
	local node = self

	while node["prev"] do
		node = node["prev"]
	end
	return node
end


function M.getTail(self)
	local node = self

	while node["next"] do
		node = node["next"]
	end
	return node
end


function M.getNext(self)
	return self["next"] or nil
end


function M.getPrevious(self)
	return self["prev"] or nil
end


function M.iterateNext(t)
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


function M.iteratePrevious(t)
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


local function _inListForward(self, check)
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
M.inListForward = _inListForward


local function _inListBackward(self, check)
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
M.inListBackward = _inListBackward


function M.inList(self, check)
	local prev = self["prev"]
	return _inListForward(self, check) or (prev and _inListBackward(self, prev))
end


return M
