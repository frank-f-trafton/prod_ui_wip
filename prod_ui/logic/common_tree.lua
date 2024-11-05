local commonTree = {}

--[[
	Logic for tree widgets.
--]]


function commonTree.instanceSetup(self)
	-- When true, allows the user to expand and compress items with child items (click the icon or
	-- press left/right arrow keys).
	self.expanders_active = false

	-- Shows item icons.
	self.show_icons = false

	-- X positions and widths of components within menu items.
	-- The X positions are reversed when right alignment is used.
	self.expander_x = 0
	self.expander_w = 0

	self.icon_x = 0
	self.icon_w = 0

	self.text_x = 0
end



function commonTree.keyForward(self)
	local item = self.menu.items[self.menu.index]
	if item
	and self.expanders_active
	and #item.nodes > 0
	and item.expanded
	then
		item.expanded = not item.expanded
		self:orderItems()
		self:arrange()
		self:cacheUpdate(true)

	elseif item and item.parent and item.parent.parent then -- XXX double-check this logic
		self.menu:setSelectedIndex(self.menu:getItemIndex(item.parent))

	else
		self:scrollDeltaH(-32) -- XXX config
	end
	return true
end


function commonTree.keyBackward(self)
	local item = self.menu.items[self.menu.index]
	if item
	and self.expanders_active
	and #item.nodes > 0
	and not item.expanded
	then
		item.expanded = not item.expanded -- XXX: wrap into a local function
		self:orderItems()
		self:arrange()
		self:cacheUpdate(true)

	elseif item and #item.nodes > 0 and item.expanded then
		self.menu:setSelectedIndex(self.menu:getItemIndex(item.nodes[1]))

	else
		self:scrollDeltaH(32) -- XXX config
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
		self:movePrev(self.page_jump_size, true)
		return true

	elseif scancode == "pagedown" then
		self:moveNext(self.page_jump_size, true)
		return true

	elseif scancode == "left" then
		return self.skin.item_align_h == "left" and commonTree.keyForward(self)
			or self.skin.item_align_h == "right" and commonTree.keyBackward(self)

	elseif scancode == "right" then
		return self.skin.item_align_h == "left" and commonTree.keyBackward(self)
			or self.skin.item_align_h == "right" and commonTree.keyForward(self)
	end
end


function commonTree.updateItemDimensions(self, skin, item)
	-- Do not try to update the root node.
	if not item.parent then
		return
	end

	local font = skin.font

	item.w = font:getWidth(item.text) + self.icon_w + skin.first_col_spacing
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
	self.show_icons = not not enabled

	self:cacheUpdate(true)
	commonTree.updateAllItemDimensions(self, self.skin, self.tree)
end


function commonTree.setExpandersActive(self, active)
	self.expanders_active = not not active

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

	item.selectable = true
	item.marked = false -- multi-select

	item.text = text
	item.bijou_id = bijou_id
	item.tq_bijou = self.context.resources.tex_quads[bijou_id]

	item.x, item.y = 0, 0
	commonTree.updateItemDimensions(self, skin, item)

	return item
end


local function _orderLoop(self, items, node)
	if node.expanded then
		for i, child_node in ipairs(node.nodes) do
			items[#items + 1] = child_node
			_orderLoop(self, items, child_node)
		end
	end
end


function commonTree.orderItems(self)
	-- Clear the existing menu item layout.
	local items = self.menu.items
	for i = #items, 1, -1 do
		items[i] = nil
	end

	-- Repopulate the menu based on the tree order.
	_orderLoop(self, items, self.tree)
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
	node.item = nil
	local item_i = self.menu:getItemIndex(item)
	table.remove(self.menu.items, item_i)
end


function commonTree.removeNode(self, node)
	-- XXX: Assertions (?)

	_removeNode(self, node, 1)

	self:orderItems()
	self:arrange()
end


function commonTree.arrange(self)
	local skin, menu = self.skin, self.menu
	local items = menu.items
	local font = skin.font

	local yy = 0

	for i = 1, #items do
		local item = items[i]

		if skin.item_align_h == "left" then
			item.x = item.depth * skin.indent
		else -- "right"
			item.x = self.doc_w - item.w - (item.depth * skin.indent)
		end
		item.y = yy
		yy = item.y + item.h
	end
end


return commonTree