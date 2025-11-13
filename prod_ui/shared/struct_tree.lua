-- Provides the guts of a tree structure, suitable for use in a TreeBox widget.


local context = select(1, ...)


local structTree = {}


local _mt_tree = {}
_mt_tree.__index = _mt_tree
structTree.mt_tree = _mt_tree


local function _getNodeIndex(self, parent)
	local nodes = parent.nodes
	local node_i

	for i = 1, #nodes do
		if nodes[i] == self then
			return i
		end
	end
end


local function getRightmostNode(node)
	while node.expanded and #node.nodes > 0 do
		node = node.nodes[#node.nodes]
	end

	return node
end


function structTree.new()
	local self = setmetatable({}, _mt_tree)

	self.parent = false

	-- When true, the node's children are visible and selectable.
	-- For top-level nodes, this should always be true.
	self.expanded = true

	self.nodes = {}

	return self
end


function _mt_tree:addNode(pos)
	pos = pos or #self.nodes + 1

	local node = structTree.new()
	node.parent = self

	table.insert(self.nodes, pos, node)

	return node
end


function _mt_tree:removeNode(pos)
	local removed = table.remove(self.nodes, pos)
	removed.parent = nil

	return removed
end


function _mt_tree:getNodeIndex()
	local parent = self.parent
	if not parent then
		error("the tree root does not have a node index.")
	end

	local i = _getNodeIndex(self, parent)

	if not i then
		error("unable to locate node within its parent.")
	end

	return i
end


function _mt_tree:getNextNode()
	local parent = self.parent

	-- Root node: return first child node or nil.
	if not parent then
		if self.expanded then
			return self.nodes[1] -- or nil
		else
			return
		end
	end

	-- Node contains child nodes and is expanded: return first child node.
	if self.expanded and #self.nodes > 0 then
		return self.nodes[1]
	end

	-- Try the next sibling. If this is the last sibling, go up one level.
	while true do
		-- Reached the end of the tree.
		if not parent then
			break
		end

		local node_i = self:getNodeIndex()

		if node_i < #parent.nodes then
			return parent.nodes[node_i + 1]
		end

		self = self.parent
		parent = self.parent
	end
end


function _mt_tree:getPreviousNode()
	local parent = self.parent

	-- Root node: return the last selectable node or nil.
	if not parent then
		local right = getRightmostNode(self)
		return (right ~= self) and right or nil
	end

	-- This is the first sibling: return non-root parent. If the parent is the root, return nil.
	-- (Ignore the 'expanded' state of ancestors here.)
	local node_i = self:getNodeIndex()
	if node_i == 1 then
		if parent.parent then
			return parent
		else
			return
		end
	-- Select the rightmost descendant of the left sibling, or just the left sibling
	-- if it is unexpanded or has no nodes.
	else
		local up_node = parent.nodes[node_i - 1]
		return getRightmostNode(up_node)
	end
end


function _mt_tree:getFirstNode()
	return self.nodes[1]
end


function _mt_tree:getLastNode()
	return getRightmostNode(self)
end


function _mt_tree:getNodeDepth()
	local depth = 0
	local node = self

	while node.parent do
		node = node.parent
		depth = depth + 1
	end

	return depth
end


function _mt_tree:isNodeExpanded()
	local node = self

	while node do
		if not node.expanded then
			return false
		end
		node = node.parent
	end

	return true
end


return structTree
