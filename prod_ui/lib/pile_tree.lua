-- PILE Tree v2.000 (modified)
-- (C) 2024 - 2025 PILE Contributors
-- License: MIT
-- https://github.com/frank-f-trafton/pile_base


local M = {}


local PATH = ... and (...):match("(.-)[^%.]+$") or ""


local interp = require(PATH .. "pile_interp")
local pAssert = require(PATH .. "pile_assert")


local ipairs, type = ipairs, type
local _pAssert_integerEval, _pAssert_notNil, _pAssert_type = pAssert.integerEval, pAssert.notNil, pAssert.type


M.lang = {
	assert_cycles = "assertion: tree contains a cycle (duplicate node reference)",
	event_bad_type = "event handler $1: unsupported type: $2",
	node_already_attached = "this node is already attached to another parent",
	node_attach_self = "tried to attach a node to itself",
	node_no_index = "couldn't find this node in its parent",
	node_no_parent = "corrupt or missing 'parent' link. (Tried to run on a root node?)",
}
local lang = M.lang


-- forward declarations
local _nodeGetVeryLast, _nodeAssertIndex, _nodeAssertParent


local function _nodeNew()
	local node = {}
	node["nodes"] = {}
	node["parent"] = false
	return node
end
M.nodeNew = _nodeNew


function M.nodeAdd(self, pos)
	pos = pos or #self["nodes"] + 1

	local node = _nodeNew()
	node["parent"] = self

	table.insert(self["nodes"], pos, node)

	return node
end


function M.nodeAttach(self, node, pos)
	if node == self then
		error(lang.node_attach_self)

	elseif node["parent"] then
		error(lang.node_already_attached)
	end

	pos = pos or #self["nodes"] + 1

	node["parent"] = self

	table.insert(self["nodes"], pos, node)

	return node
end


function M.nodeRemove(self)
	local parent = _nodeAssertParent(self)
	local siblings = parent["nodes"]

	local i = _nodeAssertIndex(self, siblings)
	self["parent"] = nil
	table.remove(siblings, i)
end


function M.nodeGetIndex(self, nodes)
	local parent = _nodeAssertParent(self)
	return _nodeAssertIndex(self, parent["nodes"])
end


_nodeAssertIndex = function(node, siblings)
	for i = 1, #siblings do
		if siblings[i] == node then
			return i
		end
	end
	error(lang.node_no_index)
end
M.nodeAssertIndex = _nodeAssertIndex


function M.nodeGetDepth(self)
	local node, depth = self, 0
	while node do
		depth = depth + 1
		node = node["parent"]
	end

	return depth
end


local function _nodeAssertNoCycles2(node, seen)
	if seen[node] then
		error(lang.assert_cycles)
	end

	seen[node] = true

	for _, child in ipairs(node["nodes"]) do
		_nodeAssertNoCycles2(child, seen)
	end
end


function M.nodeAssertNoCycles(self)
	_nodeAssertNoCycles2(self, {})
end


function M.nodeGetNext(self)
	local parent = self["parent"]

	-- Root node: select first child or nil.
	if not parent then
		return self["nodes"][1]

	-- Node has children: select the first.
	elseif #self["nodes"] > 0 then
		return self["nodes"][1]
	end

	-- Try the next sibling. Or, if this is the last sibling, go up one level.
	local node = self
	while true do
		-- Reached the end of the tree.
		if not parent then
			return
		end

		local node_i = _nodeAssertIndex(node, parent["nodes"])

		if node_i < #parent["nodes"] then
			return parent["nodes"][node_i + 1]
		end

		node = node["parent"]
		parent = node["parent"]
	end
end


function M.nodeGetPrevious(self)
	local parent = self["parent"]

	-- Root node: nothing to traverse.
	if not parent then
		return
	end

	local nodes = parent["nodes"]

	-- First sibling: select parent.
	local node_i = _nodeAssertIndex(self, nodes)
	if node_i == 1 then
		return parent
	else
		-- Select the rightmost descendant of the left sibling, or just the left sibling if it has no nodes.
		local up_node = nodes[node_i - 1]
		return _nodeGetVeryLast(up_node)
	end
end


local function _nodeGetSiblingDelta(node, delta, wrap)
	local parent = _nodeAssertParent(node)
	local siblings = node["parent"]["nodes"]
	local index = _nodeAssertIndex(node, siblings)

	local selected = siblings[index + delta]
	if not selected and wrap then
		selected = siblings[delta > 0 and 1 or #siblings]
	end

	return selected
end


function M.nodeGetNextSibling(self, wrap)
	return _nodeGetSiblingDelta(self, 1, wrap)
end


function M.nodeGetPreviousSibling(self, wrap)
	return _nodeGetSiblingDelta(self, -1, wrap)
end


function M.nodeGetChild(self, n)
	_pAssert_type("n", n, "number")

	return self["nodes"][n]
end


function M.nodeGetChildren(self)
	return self["nodes"]
end


function M.nodeGetSiblings(self)
	local parent = _nodeAssertParent(self)
	return self["parent"]["nodes"]
end


function M.nodeGetParent(self)
	return self["parent"]
end


_nodeAssertParent = function(self)
	local parent = self["parent"]
	if type(parent) ~= "table" then
		error(lang.node_no_parent)
	end
	return parent
end
M.nodeAssertParent = _nodeAssertParent


function M.nodeGetRoot(self)
	local node = self
	while node["parent"] do
		node = node["parent"]
	end
	return node
end


_nodeGetVeryLast = function(self)
	local node = self
	while #node["nodes"] > 0 do
		node = node["nodes"][#node["nodes"]]
	end

	return node
end
M.nodeGetVeryLast = _nodeGetVeryLast


function M.nodeIterate(t)
	_pAssert_type(1, t, "table")

	local function inner(t)
		coroutine.yield(t)
		local nodes = t["nodes"]
		for i = 1, #nodes do
			inner(nodes[i])
		end
	end
	local co = coroutine.create(inner)

	local iter = function(t)
		local ok, rv = coroutine.resume(co, t)
		if not ok then
			error(rv)
		end
		return rv
	end

	return iter, t, nil
end


function M.nodeIterateBack(t)
	_pAssert_type(1, t, "table")

	local function inner(t)
		local nodes = t["nodes"]
		for i = #nodes, 1, -1 do
			inner(nodes[i])
		end
		coroutine.yield(t)
	end
	local co = coroutine.create(inner)

	local iter = function(t)
		local ok, rv = coroutine.resume(co, t)
		if not ok then
			error(rv)
		end
		return rv
	end

	return iter, t, nil
end


local function _nodeForEach(self, inclusive, callback, ...)
	if inclusive then
		local a,b,c,d = callback(self, ...)
		if a then
			return a,b,c,d
		end
	end
	for i, node in ipairs(self["nodes"]) do
		local a,b,c,d = _nodeForEach(node, true, callback, ...)
		if a then
			return a,b,c,d
		end
	end
end
M.nodeForEach = _nodeForEach


local function _nodeForEachBack(self, inclusive, callback, ...)
	local nodes = self["nodes"]
	for i = #nodes, 1, -1 do
		local a,b,c,d = _nodeForEachBack(nodes[i], true, callback, ...)
		if a then
			return a,b,c,d
		end
	end
	if inclusive then
		local a,b,c,d = callback(self, ...)
		if a then
			return a,b,c,d
		end
	end
end
M.nodeForEachBack = _nodeForEachBack


function M.nodeHasThisAncestor(self, node)
	_pAssert_type("node", node, "table")

	local ancestor = self["parent"]
	while ancestor do
		if ancestor == node then
			return true
		end
		ancestor = ancestor["parent"]
	end

	return false
end


function M.nodeIsInLineage(self, node)
	_pAssert_type("node", node, "table")

	local n2 = self
	while n2 do
		if n2 == node then
			return true
		end
		n2 = n2["parent"]
	end

	return false
end


local function _nodeFindKeyInChildren(self, i, k, v)
	_pAssert_integerEval(2, i, "number")
	_pAssert_notNil(3, k)

	local children = self["nodes"]
	i = i or 1

	for j = i, #children do
		local child = children[j]
		local value = child[k]
		if v == nil and value then
			return child, value, j

		elseif v ~= nil and value == v then
			return child, value, j
		end
	end
end
M.nodeFindKeyInChildren = _nodeFindKeyInChildren


local function _nodeFindKeyDescending(self, inclusive, k, v)
	if inclusive then
		local value = self[k]
		if v == nil and value then
			return self, value

		elseif v ~= nil and value == v then
			return self, value
		end
	end

	for i, child in ipairs(self["nodes"]) do
		local r1, r2 = _nodeFindKeyDescending(child, true, k, v)
		if r1 then
			return r1, r2
		end
	end
end


function M.nodeFindKeyDescending(self, inclusive, k, v)
	_pAssert_notNil(3, k)

	return _nodeFindKeyDescending(self, inclusive, k, v)
end


function M.nodeFindKeyAscending(self, inclusive, k, v)
	_pAssert_notNil(3, k)

	local node = inclusive and self or self["parent"]
	while node do
		local value = node[k]
		if v == nil and value then
			return node, value

		elseif v ~= nil and value == v then
			return node, value
		end

		node = node["parent"]
	end
end


return M
