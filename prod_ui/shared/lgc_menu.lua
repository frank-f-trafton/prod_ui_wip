-- To load: local lib = context:getLua("shared/lib")


--[[
	Shared widget logic for menus.
--]]


local context = select(1, ...)


local lgcMenu = {}


local stMenu = context:getLua("shared/st_menu")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local widShared = require(context.conf.prod_ui_req .. "common.wid_shared")


function lgcMenu.new()
	return stMenu.new()
end


-- * Plug-in methods *


--- Apply common defaults to a widget instance that is acting as a single menu. Note that this does not create an
--  embedded menu table: it just prepares the widget itself with commonly used variables. Additionally, some widgets
--  may not support all of the features that are implied by these fields, so calling this is not a requirement of
--  all menu widgets.
-- @param self The widget to configure.
-- @param setup_mark When true, setup marking state (for multiple selections).
-- @param setup_drag When true, setup drag-and-drop state.
function lgcMenu.instanceSetup(self, setup_mark, setup_drag_drop)
	-- Requires: scroll registers, viewport #1, viewport #2, document dimensions.

	-- Extends the selected item dimensions when scrolling to keep it within the bounds of the viewport.
	self.MN_selection_extend_x = 0
	self.MN_selection_extend_y = 0

	-- Used with click-sequence (cseq) state to prevent drifting double-clicks.
	self.MN_mouse_clicked_item = false

	-- Ref to currently-hovered item, or false if not hovering over any items.
	self.MN_item_hover = false

	-- When truthy, mouse-hover continuously selects the current hovered item.
	-- Only happens when mouse DX and DY are non-zero.
	-- When "auto-off", hover-off deselects any current selection.
	self.MN_hover_to_select = false

	-- How many items to jump when pressing pageup or pagedown, or equivalent gamepad buttons.
	self.MN_page_jump_size = 4
	self.MN_wheel_jump_size = 64 -- pixels

	-- Range of items that are visible and should be checked for press/hover state.
	self.MN_items_first = 0 -- max(first, 1)
	self.MN_items_last = 2^53 -- min(last, #items)

	-- Wrap selection when pressing against the last selectable item.
	self.MN_wrap_selection = true

	-- Scroll the view while dragging the mouse.
	self.MN_drag_scroll = false

	-- When true, clicking+dragging continuously selects new items.
	-- When "auto-off", dragging outside of any item box deselects.
	self.MN_drag_select = false

	-- Reorder the current selected item while dragging.
	self.MN_drag_reorder = false

	-- Note that some mark and drag settings are mutually incompatible. TODO: config methods.
	-- Multi-Selection state.
	if setup_mark then
		--[[
		false: No built-in handling of multi-selection.
		"toggle": Behaves like a set of checkboxes.
		"cursor": Behaves (somewhat) like selections in a file browser GUI.

		`item.marked` is used to denote an item that is selected independent of the current
		menu index.
		--]]
		self.MN_mark_mode = false

		-- When MN_mark_mode is "toggle": Which marking state is being applied to items as the
		-- mouse sweeps over them.
		self.MN_mark_state = false

		-- When MN_mark_mode is "cursor": The old selection index when Shift+Click dragging started.
		-- false when Shift+Click dragging is not active.
		self.MN_mark_index = false
	end

	-- Drag-and-drop state.
	if setup_drag_drop then
		-- Support drag-and-drop transactions.
		-- false: disabled.
		-- true: when dragging the mouse outside of `context.mouse_pressed_range`.
		-- "edge": when dragging the mouse outside of the widget bounding box.
		self.MN_drag_drop_mode = false
	end

	-- Optional:
	-- self.MN_auto_range: sets items_first and items_last. Values: "h", "v", or false/nil.

	-- Also used by other integrated components:
	-- self.press_busy

	-- Make your menu object at `self.menu`.
end


--- Automatically set a widget's items_first and items_last values by checking their vertical positions.
-- @param self The widget.
function lgcMenu.widgetAutoRangeV(self)
	local menu = self.menu
	local items = self.menu.items

	local first, last
	local r1 = self.vp2_y + self.scr_y
	local r2 = r1 + self.vp2_h

	-- First
	for i = 1, #items do
		local item = items[i]
		if item.y + item.h >= r1 then
			first = i
			break
		end
	end

	-- Last
	if first then
		for i = first, #items do
			local item = items[i]
			if item.y > r2 then
				last = i
				break
			end
		end
	end

	-- Assign values or 1..#items.
	self.MN_items_first = first or 1
	self.MN_items_last = last or #menu.items
end


--- Automatically set a widget's items_first and items_last values by checking their horizontal positions.
-- @param self The widget.
function lgcMenu.widgetAutoRangeH(self)
	local menu = self.menu
	local items = self.menu.items

	local first, last
	local r1 = self.vp2_x + self.scr_x
	local r2 = r1 + self.vp2_w

	-- First
	for i = 1, #items do
		local item = items[i]
		if item.x + item.w >= r1 then
			first = i
			break
		end
	end

	-- Last
	if first then
		for i = first, #items do
			local item = items[i]
			if item.x > r2 then
				last = i
				break
			end
		end
	end

	-- Assign values or 1..#items.
	self.MN_items_first = first or 1
	self.MN_items_last = last or #menu.items
end


--- Get the first item in a range that intersects the point at (px,py). The item's 'selectable' state is not checked.
-- @param items The 'client.menu.items' table.
-- @param px X coordinate to check, relative to widget top-left.
-- @param py Y coordinate to check, relative to widget top-left.
-- @param first Index of the first item in the list to check.
-- @param last Index of the last item in the list to check.
-- @return The item index and table, if successful. Otherwise, returns nil.
function lgcMenu.widgetGetItemAtPoint(self, px, py, first, last)
	-- NOTES:
	-- * Does not check if the item is selectable or actionable.
	-- * Assumes scroll bar intersect (if applicable) has been checked first.

	local items = self.menu.items

	for i = first, last do
		local item = items[i]

		if  px >= item.x and px < item.x + item.w and py >= item.y and py < item.y + item.h then
			return i, item
		end
	end

	-- return nil
end


--- Like widgetGetItemAtPoint(), but checks only the vertical axis. Intended for vertically oriented menus.
-- @param items The 'client.menu.items' table.
-- @param px Unused. Included for compatibility with variant functions.
-- @param py Y coordinate to check, relative to widget top.
-- @param first Index of the first item in the list to check (ie 1).
-- @param last Index of the last item in the list to check (ie #items).
-- @return The item index and table, if successful. Otherwise, returns nil.
function lgcMenu.widgetGetItemAtPointV(self, px, py, first, last)
	-- See widgetGetItemAtPoint() for notes.

	local items = self.menu.items

	for i = first, last do
		local item = items[i]

		if py >= item.y and py < item.y + item.h then
			return i, item
		end
	end

	return nil
end


--- Clamped version of widgetGetItemAtPointV(). Checks items at indices `1` and `#items` separately.
function lgcMenu.widgetGetItemAtPointVClamp(self, px, py, first, last)
	-- See widgetGetItemAtPoint() for notes.

	local items = self.menu.items

	local i1, i2 = items[1], items[#items]
	if i1 and py < i1.y + i1.h then
		return 1, i1

	elseif i2 and py >= i2.y then
		return #items, i2
	end

	for i = math.max(2, first), math.min(#items - 1, last) do
		local item = items[i]

		if py >= item.y and py < item.y + item.h then
			return i, item
		end
	end

	return nil
end


--- Like widgetGetItemAtPoint(), but checks only the horizontal axis. Intended for horizontally oriented menus.
-- @param items The 'client.menu.items' table.
-- @param px X coordinate to check, relative to widget left.
-- @param py Unused. Included for compatibility with variant functions.
-- @param first Index of the first item in the list to check (ie 1).
-- @param last Index of the last item in the list to check (ie #items).
-- @return The item index and table, if successful. Otherwise, returns nil.
function lgcMenu.widgetGetItemAtPointH(self, px, py, first, last)
	-- See widgetGetItemAtPoint() for notes.

	local items = self.menu.items

	for i = first, last do
		local item = items[i]

		if px >= item.x and px < item.x + item.w then
			return i, item
		end
	end

	return nil
end


--- Call the getItemAtPoint method, and if a selectable item is found, select it, update scrolling, etc.
-- @param x Mouse X position, relative to widget top-left.
-- @param y Mouse Y position, relative to widget top-left.
function lgcMenu.widgetTrySelectItemAtPoint(self, x, y, first, last)
	-- Prerequisites: widget must have a 'getItemAtPoint()' method assigned.

	local i, item = self:getItemAtPoint(x, y, first, last)

	if item and item.selectable then
		self.menu:setSelectedIndex(i)
		if self.selectionInView then
			self:selectionInView()
		end

		return i, item
	end
end


--- Use when you've already located an item and confirmed that it is selectable.
function lgcMenu.widgetSelectItemByIndex(self, item_i)
	self.menu:setSelectedIndex(item_i)

	if self.selectionInView then
		self:selectionInView()
	end
end


--[[
	Here are some built-in arrangement functions.
	These are all very basic in design. They expect the dimensions of items to already be correct,
	relative to the size of viewport #1.
--]]


-- Vertical list, top to bottom
function lgcMenu.arrangeListVerticalTB(self, first, last)
	local menu = self.menu
	local items = menu.items

	first = first or 1
	last = last or #items

	-- Empty list or invalid range: nothing to do.
	if #items == 0 or first > last then
		return
	end

	local yy = 0

	-- If there is an item before the start, piggy-back off of its location.
	local item_prev = items[first - 1]
	if item_prev then
		yy = item_prev.y + item_prev.h
	end

	for i = first, last do
		local item = items[i]

		item.x = 0
		item.y = yy

		yy = item.y + item.h
	end
end


-- Vertical list, left-to-right then top-to-bottom.
function lgcMenu.arrangeListVerticalLRTB(self, first, last)
	local menu = self.menu
	local items = menu.items

	first = first or 1
	last = last or #items

	-- Empty list or invalid range: nothing to do.
	if #menu.items == 0 or first > last then
		return
	end

	local xx, yy = 0, 0

	-- If there is an item before the start, piggy-back off of its location.
	local item_prev = items[first - 1]
	if item_prev then
		xx = item_prev.x + item_prev.w
		yy = item_prev.y
	end

	for i = first, last do
		local item = items[i]

		if xx + item.w > self.vp_w then
			xx = 0
			yy = yy + item.h
		end

		item.x = xx
		item.y = yy

		xx = item.x + item.w
	end
end


-- Horizontal list, left to right
function lgcMenu.arrangeListHorizontalLR(self, first, last)
	local menu = self.menu
	local items = menu.items

	first = first or 1
	last = last or #items

	-- Empty list or invalid range: nothing to do.
	if #menu.items == 0 or first > last then
		return
	end

	local xx = 0

	-- If there is an item before the start, piggy-back off of its location.
	local item_prev = items[first - 1]
	if item_prev then
		xx = item_prev.x + item_prev.x
	end

	for i = first, last do
		local item = items[i]

		item.x = xx
		item.y = 0

		xx = item.x + item.w
	end
end


-- Horizontal list, top to bottom then left to right.
function lgcMenu.arrangeListHorizontalTBLR(self, first, last)
	local menu = self.menu
	local items = menu.items

	first = first or 1
	last = last or #items

	-- Empty list or invalid range: nothing to do.
	if #menu.items == 0 or first > last then
		return
	end

	local xx, yy = 0, 0

	-- If there is an item before the start, piggy-back off of its location.
	local item_prev = items[first - 1]
	if item_prev then
		xx = item_prev.x
		yy = item_prev.y + item_prev.w
	end

	for i = first, last do
		local item = items[i]

		if yy + item.h > self.vp_h then
			xx = xx + item.w
			yy = 0
		end

		item.x = xx
		item.y = yy

		yy = item.y + item.h
	end
end


--[[
	Some default selection methods for widgets, assuming they support scrolling viewports.

	They expect the widget to have a single menu table at `self.menu`.

	The following optional methods may be attached to the widget:

	self:selectionInView()
	self:cacheUpdate()
--]]


--- Move the widget menu selection back by an arbitrary number of steps. If applicable: update scrolling such that the
--  selection is in view, and update the widget's visual cache.
-- @param self The widget hosting the menu table.
-- @param n (1) How many steps to move.
-- @param immediate Passed to selectionInView(). Skips scrolling animation.
-- @param id ("index") Optional alternative index key to change.
function lgcMenu.widgetMovePrev(self, n, immediate, id)
	self.menu:setPrev(n, self.MN_wrap_selection, id)

	if self.selectionInView then
		self:selectionInView(immediate)
	end
	if self.cacheUpdate then
		self:cacheUpdate(false)
	end
end


--- Move the widget menu selection forward by an arbitrary number of steps. If applicable: update scrolling such that
--  the selection is in view, and update the widget's visual cache.
-- @param self The widget hosting the menu table.
-- @param n (1) How many steps to move.
-- @param immediate Passed to selectionInView(). Skips scrolling animation.
-- @param id ("index") Optional alternative index key to change.
function lgcMenu.widgetMoveNext(self, n, immediate, id)
	self.menu:setNext(n, self.MN_wrap_selection, id)

	if self.selectionInView then
		self:selectionInView(immediate)
	end
	if self.cacheUpdate then
		self:cacheUpdate(false)
	end
end


--- Move the widget menu selection to the first selectable (or nothing, if there is no selectable item). If applicable:
--  update scrolling such that the selection is in view, and update the widget's visual cache.
-- @param self The widget hosting the menu table.
-- @param immediate Passed to selectionInView(). Skips scrolling animation.
-- @param id ("index") Optional alternative index key to change.
function lgcMenu.widgetMoveFirst(self, immediate, id)
	self.menu:setFirstSelectableIndex(id)

	if self.selectionInView then
		self:selectionInView(immediate)
	end
	if self.cacheUpdate then
		self:cacheUpdate(false)
	end
end


--- Move the widget menu selection to the last selectable (or nothing, if there is no selectable item). If applicable:
--  update scrolling such that the selection is in view, and update the widget's visual cache.
-- @param self The widget hosting the menu table.
-- @param immediate Passed to selectionInView(). Skips scrolling animation.
-- @param id ("index") Optional alternative index key to change.
function lgcMenu.widgetMoveLast(self, immediate, id)
	self.menu:setLastSelectableIndex(id)

	if self.selectionInView then
		self:selectionInView(immediate)
	end
	if self.cacheUpdate then
		self:cacheUpdate(false)
	end
end


--[[
	Some default key navigation functions.

	They expect the widget to have certain methods assigned for moving the selection which also take care
	of scrolling and updating the visual cache.
--]]


--- Default key navigation for top-to-bottom menus.
-- @param self The widget.
-- @param key, scancode, isrepeat Values from the LÖVE event.
-- @param id ("index") Optional alternative index key to change.
-- @param the isrepeat
function lgcMenu.keyNavTB(self, key, scancode, isrepeat, id)
	if scancode == "up" then
		self:movePrev(1, nil, id)
		return true

	elseif scancode == "down" then
		self:moveNext(1, nil, id)
		return true

	elseif scancode == "home" then
		self:moveFirst(id)
		return true

	elseif scancode == "end" then
		self:moveLast(id)
		return true

	elseif scancode == "pageup" then
		self:movePrev(self.MN_page_jump_size, nil, id)
		return true

	elseif scancode == "pagedown" then
		self:moveNext(self.MN_page_jump_size, nil, id)
		return true
	end
end


--- Default key navigation for left-to-right menus.
function lgcMenu.keyNavLR(self, key, scancode, isrepeat, id)
	if scancode == "left" then
		self:movePrev(1, nil, id)
		return true

	elseif scancode == "right" then
		self:moveNext(1, nil, id)
		return true

	elseif scancode == "home" then
		self:moveFirst(id)
		return true

	elseif scancode == "end" then
		self:moveLast(id)
		return true

	elseif scancode == "pageup" then
		self:movePrev(self.MN_page_jump_size, nil, id)
		return true

	elseif scancode == "pagedown" then
		self:moveNext(self.MN_page_jump_size, nil, id)
		return true
	end
end


--- For every table in an array, if a 'config' method is present, run it on the table with 'self' as an argument.
--  Use to refresh the selectable / usable state of menu items. (Depending on the use case, the tables need not be
--  fully functional menu items. They could also be shared definition tables that are copied to live items at a later
--  time.)
-- @param self Presumably the client widget that owns the menu. (Could be something else depending on the implementation.)
-- @param array The array containing menu-items or tables similar to menu-items.
function lgcMenu.widgetConfigureMenuItems(self, array)
	for i, tbl in ipairs(array) do
		if tbl.config then
			tbl:config(self)
		end
	end
end


--- Get the combined dimensions of all items in the menu. Assumes that all items have X and Y positions >= 0.
-- @param items The table of menu-items to scan.
-- @return The bounding width and height of all items.
function lgcMenu.getCombinedItemDimensions(items)
	local dw, dh = 0, 0
	for i, item in ipairs(items) do
		dw = math.max(dw, item.x + item.w)
		dh = math.max(dh, item.y + item.h)
	end
	return dw, dh
end


--- Scroll the menu so that a given item is in view. If the item is larger than the menu widget, its bottom-right
-- corner will be prioritized. The widget must have shared scrolling methods assigned.
-- @param self The menu widget.
-- @param item The item within the menu to get in view.
-- @param immediate Skip scrolling animation when true.
function lgcMenu.getItemInBoundsRect(self, item, immediate)
	--[[
	Widget must have 'MN_selection_extend_x' and 'MN_selection_extend_y' set.
	--]]

	self:scrollRectInBounds(
		item.x - self.MN_selection_extend_x,
		item.y - self.MN_selection_extend_y,
		item.x + item.w + self.MN_selection_extend_x,
		item.y + item.h + self.MN_selection_extend_y,
		immediate
	)
end


--- Like getItemInBoundsRect, but acts on the horizontal axis only.
-- @param self The menu widget.
-- @param item The item within the menu to get in view.
-- @param immediate Skip scrolling animation when true.
function lgcMenu.getItemInBoundsX(self, item, immediate)
	--[[
	Widget must have 'MN_selection_extend_x' set.
	--]]

	self:scrollXInBounds(
		item.x - self.MN_selection_extend_x,
		item.x + item.w + self.MN_selection_extend_x,
		immediate
	)
end


--- Like getItemInBoundsRect, but acts on the vertical axis only.
-- @param self The menu widget.
-- @param item The item within the menu to get in view.
-- @param immediate Skip scrolling animation when true.
function lgcMenu.getItemInBoundsY(self, item, immediate)
	--[[
	Widget must have 'MN_selection_extend_y' set.
	--]]

	self:scrollYInBounds(
		item.y - self.MN_selection_extend_y,
		item.y + item.h + self.MN_selection_extend_y,
		immediate
	)
end


--- If there is a current selection and it is not within view, scroll to it.
-- @param self The menu widget with a current selection (or none).
-- @param immediate When true, skip scrolling animation.
function lgcMenu.selectionInView(self, immediate)
	--[[
	Widget must have a 'getInBounds' method assigned. These methods usually require 'MN_selection_extend_[x|y]' to be set.
	--]]

	local menu = self.menu
	local item = menu.items[menu.index]

	-- No selection or empty list: nothing to do.
	if not item or #menu.items == 0 then
		-- XXX maybe scroll to top-left?
		--self:scrollHV(0, 0)
		return
	else
		self:getInBounds(item, immediate)
	end

	if immediate then
		self:cacheUpdate(false)
	end
end



function lgcMenu.markItemsCursorMode(self, old_index)
	if not self.MN_mark_index then
		self.MN_mark_index = old_index
	end

	local menu = self.menu
	local items = menu.items

	local first, last = math.min(self.MN_mark_index, menu.index), math.max(self.MN_mark_index, menu.index)
	first, last = math.max(1, math.min(first, #items)), math.max(1, math.min(last, #items))

	self.menu:setMarkedItemRange(true, first, last)
end


return lgcMenu
