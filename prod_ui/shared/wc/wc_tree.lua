-- Logic for tree widgets.


local context = select(1, ...)


local wcTree = {}


local pTree = require(context.conf.prod_ui_req .. "lib.pile_tree")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiTable = require(context.conf.prod_ui_req .. "ui_table")
local wcMenu = context:getLua("shared/wc/wc_menu")


local _nm_align = {left=true, center=true, right=true}


local _mt_tree = {}
_mt_tree.__index = _mt_tree
wcTree.mt_tree = _mt_tree


function wcTree.newNode()
	local self = setmetatable(pTree.nodeNew(), _mt_tree)

	-- When true, the node's children are visible and selectable.
	-- For root nodes, this should always be true.
	self.expanded = true

	return self
end


function _mt_tree:nodeAdd(pos)
	local node = wcTree.newNode()
	pTree.nodeAttach(self, node, pos)
	return node
end


_mt_tree.nodeRemove = pTree.nodeRemove


function _mt_tree:nodeIsExpanded()
	local node = self

	while node do
		if not node.expanded then
			return false
		end
		node = node.parent
	end

	return true
end


--
function wcTree.instanceSetup(self)
	-- X positions and widths of components within menu items.
	-- The X positions are reversed when right alignment is used.
	self.TR_expander_x = 0
	self.TR_expander_w = 0

	self.TR_icon_x = 0
	self.TR_icon_w = 0

	self.TR_text_x = 0
end


local methods = {}


function wcTree.defSetup(def)
	uiTable.patch(def, methods, true)
end


function methods:setNodeExpanded(item, exp)
	-- TODO: confirm that the widget owns the item
	item.expanded = not not exp

	-- If expanding this node, then ensure that all
	-- parent nodes are expanded, too.
	if exp then
		local node = item
		while node.parent do -- (stop just before the root node)
			node.expanded = true
			node = node.parent
		end
	end

	self:orderItems()
	self:arrangeItems(self)
	self:cacheUpdate(true)
	self:scrollClampViewport()

	-- TODO: deal with having two calls to cacheUpdate().
	self:cacheUpdate(true)
end


function methods:setIconsEnabled(enabled)
	self:writeSetting("TR_show_icons", not not enabled)
	self:cacheUpdate(true)
	wcTree.updateAllItemDimensions(self, self.skin, self.tree)

	return self
end


function methods:setExpandersActive(active)
	self:writeSetting("TR_expanders_active", not not active)
	self:cacheUpdate(true)
	wcTree.updateAllItemDimensions(self, self.skin, self.tree)

	return self
end


function methods:setItemAlignment(align)
	if not _nm_align[align] then
		error("invalid alignment setting.")
	end
	self:writeSetting("TR_item_align_h", align)
	self:cacheUpdate(true)
	wcTree.updateAllItemDimensions(self, self.skin, self.tree)

	return self
end


function methods:addNode(text, parent_node, tree_pos, icon_id, expanded)
	uiAssert.type(1, text, "string")
	uiAssert.tableWithMetatableEval(2, parent_node, wcTree.mt_tree)
	uiAssert.typeEval(3, tree_pos, "number")
	uiAssert.typeEval(4, icon_id, "string")
	-- don't assert 'expanded'

	--print("add node", text, parent_node, tree_pos, icon_id, expanded)

	local skin = self.skin
	local font = skin.font

	parent_node = parent_node or self.tree
	local node = parent_node:nodeAdd(tree_pos)

	node.depth = pTree.nodeGetDepth(node) - 1 -- TODO: check this

	-- Nodes function as menu items.
	local item = node

	item.expanded = not not expanded

	-- Is true when the node is visible as a menu item.
	-- Needed to simplify the clearing of marks and the menu selection when unexpanding a node.
	item.presented = false

	item.selectable = true
	item.marked = false -- multi-select

	item.text = text
	item.icon_id = icon_id
	item.tq_icon = wcMenu.getIconQuad(self.icon_set_id, item.icon_id)

	item.x, item.y = 0, 0
	wcTree.updateItemDimensions(self, skin, item)

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


function methods:orderItems()
	local items = self.MN_items

	-- Note the current selected item, if any.
	local item_sel = items[self.MN_index]

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

	return self
end


local function _removeNode(self, node, _depth)
	local node_parent = pTree.nodeAssertParent(node)
	local nodes = node.nodes

	-- Remove all child nodes first.
	for i = #nodes, 1, -1 do
		local child = nodes[i]
		self:removeNode(child, _depth + 1)
		child:nodeRemove()
	end

	local item = node.item
	item.presented = nil
	node.item = nil
	local item_i = self:menuGetItemIndex(item)
	table.remove(self.MN_items, item_i)
end


function methods:removeNode(node)
	-- XXX: Assertions (?)

	_removeNode(self, node, 1)

	self:orderItems()
	self:arrangeItems()

	return self
end


function methods:arrangeItems()
	local skin, items = self.skin, self.MN_items
	local yy = 0

	for i = 1, #items do
		local item = items[i]

		item.x = item.depth * skin.indent
		item.y = yy
		yy = item.y + item.h
	end

	return self
end


function wcTree.keyForward(self, dir)
	local item = self.MN_items[self.MN_index]
	if item
	and self.TR_expanders_active
	and #item.nodes > 0
	and not item.expanded
	then
		self:setNodeExpanded(item, true)

	elseif item and #item.nodes > 0 and item.expanded then
		self:menuSetSelectedIndex(self:menuGetItemIndex(item.nodes[1]))
		self:getInBounds(item.nodes[1], true)
		self:cacheUpdate(true)

	else
		self:scrollDeltaH(32 * dir) -- XXX config
	end
	return true
end


function wcTree.keyBackward(self, dir)
	local item = self.MN_items[self.MN_index]

	if item
	and self.TR_expanders_active
	and #item.nodes > 0
	and item.expanded
	then
		self:setNodeExpanded(item, false)

	elseif item and item.parent and item.parent.parent then -- XXX double-check this logic
		self:menuSetSelectedIndex(self:menuGetItemIndex(item.parent))
		self:getInBounds(item.parent, true)
		self:cacheUpdate(true)

	else
		self:scrollDeltaH(32 * dir) -- XXX config
	end
	return true
end


--- Called in evt_keyPressed(). Implements basic keyboard navigation.
-- @param key The key code.
-- @param scancode The scancode.
-- @param isrepeat Whether this is a key-repeat event.
-- @return true to halt keynav and further bubbling of the keyPressed event.
function wcTree.wid_defaultKeyNav(self, key, scancode, isrepeat)
	if scancode == "up" then
		self:movePrev(1, true, isrepeat)
		return true

	elseif scancode == "down" then
		self:moveNext(1, true, isrepeat)
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
		return self.TR_item_align_h == "left" and wcTree.keyBackward(self, -1)
			or self.TR_item_align_h == "right" and wcTree.keyForward(self, -1)

	elseif scancode == "right" then
		return self.TR_item_align_h == "left" and wcTree.keyForward(self, 1)
			or self.TR_item_align_h == "right" and wcTree.keyBackward(self, 1)
	end
end


function wcTree.updateItemDimensions(self, skin, item)
	-- Do not try to update the root node.
	if not item.parent then
		return
	end

	local font = skin.font

	item.w = font:getWidth(item.text) + self.TR_icon_w + skin.first_col_spacing
	item.h = math.floor((font:getHeight() * font:getLineHeight()) + skin.item_pad_v)
end


function wcTree.updateAllItemDimensions(self, skin, node)
	for i, item in ipairs(node.nodes) do
		wcTree.updateItemDimensions(self, skin, item)
		if #item.nodes > 0 then
			wcTree.updateAllItemDimensions(self, skin, item)
		end
	end
end


function wcTree.updateAllIconReferences(self, skin, node)
	for i, item in ipairs(node.nodes) do
		item.tq_icon = wcMenu.getIconQuad(self.icon_set_id, item.icon_id)
		if #item.nodes > 0 then
			wcTree.updateAllIconReferences(self, skin, item)
		end
	end
end


function wcTree.mirrorItemsHorizontal(self)
	local items = self.MN_items
	for i = 1, #items do
		local item = items[i]

		item.x = self.doc_w - item.x - item.w
	end

	return self
end


return wcTree
