--[[
	Logic for tree widgets.
--]]


local commonTree = {}


local _enum_align = {left=true, center=true, right=true}


function commonTree.instanceSetup(self)
	-- X positions and widths of components within menu items.
	-- The X positions are reversed when right alignment is used.
	self.TR_expander_x = 0
	self.TR_expander_w = 0

	self.TR_icon_x = 0
	self.TR_icon_w = 0

	self.TR_text_x = 0
end


function commonTree.setExpanded(self, item, exp)
	item.expanded = exp
	self:orderItems()
	self:arrangeItems()
	self:cacheUpdate(true)
	self:scrollClampViewport()

	--[[
	Calling cacheUpdate() again. We need to set the item ranges after clamping. The function that we want
	is lgcMenu.widgetAutoRangeV(), but it's not accessible (without debug shenanigans) from this source
	file. Either it needs to be attached to widgets as a method, or this source file needs to be loaded
	through the context.
	--]]
	self:cacheUpdate(true)
end


function commonTree.keyForward(self, dir)
	local item = self.items[self.index]
	if item
	and self.TR_expanders_active
	and #item.nodes > 0
	and not item.expanded
	then
		commonTree.setExpanded(self, item, true)

	elseif item and #item.nodes > 0 and item.expanded then
		self:menuSetSelectedIndex(self:menuGetItemIndex(item.nodes[1]))
		self:getInBounds(item.nodes[1], true)
		self:cacheUpdate(true)

	else
		self:scrollDeltaH(32 * dir) -- XXX config
	end
	return true
end


function commonTree.keyBackward(self, dir)
	local item = self.items[self.index]

	if item
	and self.TR_expanders_active
	and #item.nodes > 0
	and item.expanded
	then
		commonTree.setExpanded(self, item, false)

	elseif item and item.parent and item.parent.parent then -- XXX double-check this logic
		self:menuSetSelectedIndex(self:menuGetItemIndex(item.parent))
		self:getInBounds(item.parent, true)
		self:cacheUpdate(true)

	else
		self:scrollDeltaH(32 * dir) -- XXX config
	end
	return true
end


--- Called in uiCall_keyPressed(). Implements basic keyboard navigation.
-- @param key The key code.
-- @param scancode The scancode.
-- @param isrepeat Whether this is a key-repeat event.
-- @return true to halt keynav and further bubbling of the keyPressed event.
function commonTree.wid_defaultKeyNav(self, key, scancode, isrepeat)
	if scancode == "up" then
		self:movePrev(1, true)
		return true

	elseif scancode == "down" then
		self:moveNext(1, true)
		return true

	elseif scancode == "home" then
		self:moveFirst(true)
		return true

	elseif scancode == "end" then
		self:moveLast(true)
		return true

	elseif scancode == "pageup" then
		self:movePageUp(true)
		return true

	elseif scancode == "pagedown" then
		self:movePageDown(true)
		return true

	elseif scancode == "left" then
		return self.TR_item_align_h == "left" and commonTree.keyBackward(self, -1)
			or self.TR_item_align_h == "right" and commonTree.keyForward(self, -1)

	elseif scancode == "right" then
		return self.TR_item_align_h == "left" and commonTree.keyForward(self, 1)
			or self.TR_item_align_h == "right" and commonTree.keyBackward(self, 1)
	end
end


function commonTree.updateItemDimensions(self, skin, item)
	-- Do not try to update the root node.
	if not item.parent then
		return
	end

	local font = skin.font

	item.w = font:getWidth(item.text) + self.TR_icon_w + skin.first_col_spacing
	item.h = math.floor((font:getHeight() * font:getLineHeight()) + skin.item_pad_v)
end


function commonTree.updateAllItemDimensions(self, skin, node)
	for i, item in ipairs(node.nodes) do
		commonTree.updateItemDimensions(self, skin, item)
		if #item.nodes > 0 then
			commonTree.updateAllItemDimensions(self, skin, item)
		end
	end
end


function commonTree.setIconsEnabled(self, enabled)
	self:writeSetting("TR_show_icons", not not enabled)
	self:cacheUpdate(true)
	commonTree.updateAllItemDimensions(self, self.skin, self.tree)
end


function commonTree.setExpandersActive(self, active)
	self:writeSetting("TR_expanders_active", not not active)
	self:cacheUpdate(true)
	commonTree.updateAllItemDimensions(self, self.skin, self.tree)
end


function commonTree.setItemAlignment(self, align)
	if not _enum_align[align] then
		error("invalid alignment setting.")
	end
	self:writeSetting("TR_item_align_h", align)
	self:cacheUpdate(true)
	commonTree.updateAllItemDimensions(self, self.skin, self.tree)
end


function commonTree.addNode(self, text, parent_node, tree_pos, bijou_id)
	--print("add node", text, parent_node, tree_pos, bijou_id)
	-- XXX: Assertions.

	local skin = self.skin
	local font = skin.font

	parent_node = parent_node or self.tree
	local node = parent_node:addNode(tree_pos)

	node.depth = node:getNodeDepth() - 1

	-- Nodes function as menu items.
	local item = node

	-- Is true when the node is visible as a menu item.
	-- Needed to simplify the clearing of marks and the menu selection when unexpanding a node.
	item.presented = false

	item.selectable = true
	item.marked = false -- multi-select

	item.text = text
	item.bijou_id = bijou_id
	item.tq_bijou = self.context.resources.quads["atlas"][bijou_id] -- TODO: fix

	item.x, item.y = 0, 0
	commonTree.updateItemDimensions(self, skin, item)

	return item
end


local function _orderLoop(self, items, node)
	if node.expanded then
		for i, child in ipairs(node.nodes) do
			items[#items + 1] = child
			child.presented = true
			_orderLoop(self, items, child)
		end
	end
end


local function _unmarkLoop(self, node, _depth)
	_depth = _depth or 1
	for i, child in ipairs(node.nodes) do
		if not child.presented then
			child.marked = false
		end
		_unmarkLoop(self, child, _depth + 1)
	end
end


local function _selectionLoop(self, node)
	while node do
		if node.presented and node.selectable then
			self:menuSetSelectedItem(node)
			return
		else
			node = node.parent
		end
	end

	self:menuSetSelectedIndex(0)
end


function commonTree.orderItems(self)
	local items = self.items

	-- Note the current selected item, if any.
	local item_sel = items[self.index]

	-- Clear the existing menu layout.
	for i = #items, 1, -1 do
		items[i].presented = false
		items[i] = nil
	end

	-- Repopulate the menu based on the tree order.
	_orderLoop(self, items, self.tree)

	-- Unmark any items that are now hidden from the menu.
	_unmarkLoop(self, self.tree)

	-- Fix the selected item.
	if item_sel then
		-- If the item is still visible, update the selected index.
		-- If not, find the next selectable ancestor, or select nothing if there is no suitable candidate.
		if item_sel.presented then
			self:menuSetSelectedItem(item_sel)
		else
			_selectionLoop(self, item_sel)
		end
	end
end


local function _removeNode(self, node, depth)
	local node_i = node:getNodeIndex()
	local node_parent = node.parent
	if not node_parent then
		error("cannot remove the root tree node")
	end

	-- Remove all child nodes first.
	for i, child_node in ipairs(node.nodes) do
		self:removeNode(child_node, depth + 1)
		node:removeNode(node_i)
	end

	local item = node.item
	item.presented = nil
	node.item = nil
	local item_i = self:menuGetItemIndex(item)
	table.remove(self.items, item_i)
end


function commonTree.removeNode(self, node)
	-- XXX: Assertions (?)

	_removeNode(self, node, 1)

	self:orderItems()
	self:arrangeItems()
end


function commonTree.arrangeItems(self)
	local skin, items = self.skin, self.items
	local font = skin.font

	local yy = 0

	for i = 1, #items do
		local item = items[i]

		if self.TR_item_align_h == "left" then
			item.x = item.depth * skin.indent
		else -- "right"
			item.x = self.doc_w - item.w - (item.depth * skin.indent)
		end
		item.y = yy
		yy = item.y + item.h
	end
end


return commonTree