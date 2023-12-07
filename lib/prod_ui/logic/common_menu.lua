--[[
	Provides the basic guts of a 1D menu, plus some auxiliary helper functions and plug-in methods
	for widgets.

	Menu items are contained in the array `menu.items`. Each item is a table, and the menu checks
	the following variables when making selections:

	item.selectable (boolean): This item can be selected by the menu cursor.
		* When moving the cursor, non-selectable items are skipped.
		* If no items are selectable, then the selection index is 0 (no selection).

	menu.default_deselect (boolean): When true, the default menu item is nothing (index 0).

	item.is_default_selection (boolean): The item to select by default, if 'menu.default_deselect' is false.
		* If multiple items have this set, then only the first selectable item in the list is considered.
		* If no item has this set, then the default is the first selectable item (or if there are no
		  selectable items, then the cursor is set to no selection.)


	To make menus with multiple selections, use the selected / index state as a cursor position, and store a
	secondary selected state in each menu item table.
--]]


local commonMenu = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local widShared = require(REQ_PATH .. "wid_shared")


local _mt_menu = {}
_mt_menu.__index = _mt_menu


--- Makes a new menu.
-- @return The menu table.
function commonMenu.new()

	local menu = {}

	menu.items = {}

	-- Currently selected item index. 0 == no selection.
	menu.index = 0

	-- Wrap selection when pressing against the last selectable item.
	menu.wrap_selection = true

	-- When true, the default selection is nothing (0).
	menu.default_deselect = false

	setmetatable(menu, _mt_menu)

	return menu
end


-- * Internal *


local function sign(n)

	-- Treats zero as positive.
	return n < 0 and -1 or 1
end


local function clampIndex(self)

	-- Assumes the menu has at least one item, and does not account for no selection (index 0).
	-- Check that the index is acceptable after calling.

	self.index = math.max(1, math.min(math.floor(self.index), #self.items))
end


-- * Menu Methods *


--- Check if the menu has any items that can be selected.
-- @return true if any item is selectable, false otherwise.
function _mt_menu:hasAnySelectableItems()

	local items = self.items
	for i = 1, #items do
		if items[i].selectable then
			return true
		end
	end

	return false
end


--- Check if an item index is selectable, and if not, provide a string explaining why.
-- @param index The item index to check.
-- @param return true if selectable, false plus string if not.
function _mt_menu:canSelect(index)

	-- Permit deselection
	if index == 0 then
		return true

	-- Out of bounds check
	elseif index < 0 or index > #self.items then
		return false, "list index is out of range."

	-- Requested item is not selectable
	elseif not self.items[index].selectable then
		return false, "item is not selectable."
	end

	return true
end


--- Given an item index and a direction (previous or next), pick the closest item that is selectable (including the start index).
-- @param i The starting index (1..#self.items).
-- @param dir The desired direction to move in, if the current index is not selectable. Can be 1 or -1.
-- @return The most suitable selectable item index, or nil if there were no selectable item.
function _mt_menu:findSelectableLanding(i, dir)

	local item
	repeat
		item = self.items[i]
		if item and item.selectable then
			return i
		end
		i = i + dir
	until not item

	return nil
end


--- Sets the current menu selection. If the index is invalid or the item cannot be selected, raises a Lua error.
-- @param index The index of the menu item to select.
function _mt_menu:setSelectedIndex(index)

	local ok, err = self:canSelect(index)
	if not ok then
		error(err)
	end

	self.index = index
end


--- Sets the current menu selection to the default.
function _mt_menu:setSelectedDefault()

	if self.default_deselect then
		self.index = 0

	else
		local first_sel_i = false

		-- Prefer the first item marked as the default.
		-- If no default is set, fall back to the first selectable item.
		for i, item in ipairs(self.items) do

			if item.selectable then
				if item.is_default_selection then
					self:setSelectedIndex(i)
					return

				elseif not first_sel_i then
					first_sel_i = i
				end
			end
		end

		if first_sel_i then
			self:setSelectedIndex(first_sel_i)

		-- Nothing selectable: deselect
		else
			self.index = 0
		end
	end
end


--- Get the current selected item table. Equivalent to `local item_t = menu.items[menu.index]`.
-- @return The selected item, or nil if there is no current selection.
function _mt_menu:getSelectedItem()
	return self.items[self.index]
end


--- Move the current menu selection index.
-- @param delta The direction to move in. 1 == down, -1 == up, 0 == stay put (and do the clamping and landing checks). You can move more than one step at a time.
-- @param wrap (boolean) When true, wrap around the list when at the first or last selectable item. Pass `self.wrap_selection` here unless you have a reason to override it.
function _mt_menu:stepSelected(delta, wrap)

	delta = math.floor(delta + 0.5)

	-- Starting from no selection:
	if self.index == 0 then
		-- If wrapping, depending on the direction, go to the top-most or bottom-most selectable.
		-- Default to nothing if there are no selectable items.
		-- Zero delta is treated like a positive value (forward).
		if wrap then
			if delta < 0 then
				self.index = self:findSelectableLanding(#self.items, -1) or 0

			else
				self.index = self:findSelectableLanding(1, 1) or 0
			end

		-- Not wrapping: go to the top-most selection, regardless of the delta.
		-- Default to nothing if there are no selectable items.
		else
			self.index = self:findSelectableLanding(1, 1) or 0
		end

	-- Normal selection handling:
	else
		clampIndex(self)

		-- Special handling for wrap-around. Wrapping only happens if the selection is at the edge
		-- of the list, and it always puts the selector at the first selectable item on the opposite
		-- side.
		if wrap then
			if delta < 0 and not self:findSelectableLanding(self.index - 1, -1) then
				self.index = self:findSelectableLanding(#self.items, -1) or 0
				return 

			elseif delta >= 0 and not self:findSelectableLanding(self.index + 1, 1) then
				self.index = self:findSelectableLanding(1, 1) or 0
				return
			end
		end

		-- Advance.
		self.index = self.index + delta

		clampIndex(self)

		local dir = sign(delta)

		-- If the new item is not selectable, then we need to hunt for the closest one nearby that is.
		self.index = self:findSelectableLanding(self.index, dir) or self:findSelectableLanding(self.index - dir, -dir) or 0
	end
end


--- Move to the first selectable menu item.
function _mt_menu:setSelectedIndexFirst()
	self.index = self:findSelectableLanding(1, 1) or 0
end


--- Move to the last selectable menu item.
function _mt_menu:setSelectedIndexLast()
	self.index = self:findSelectableLanding(#self.items, -1) or 0
end


--- Move to the previous selectable menu item, wrapping depending on the menu config.
function _mt_menu:setSelectedPrev(n)
	n = n and math.max(math.floor(n), 1) or 1
	self:stepSelected(-n, self.wrap_selection)
end


--- Move to the next selectable menu item, wrapping depending on the menu config.
function _mt_menu:setSelectedNext(n) -- XXX setSelectionNext
	n = n and math.max(math.floor(n), 1) or 1
	self:stepSelected(n, self.wrap_selection)
end


--- Stepping backwards, select the first item whose bottom edge is <= the current item's top edge and whose left edge
--  is <= the current item's left edge. If no suitable item is found, try again starting from the bottom. If there is
--  no selection, follow the standard behavior of stepSelected(). Intended for 2D grids of menu-items arranged
--  left-to-right, top-to-bottom.
function _mt_menu:moveSelectedGridUp() -- XXX needs testing

	local items = self.items
	local item_current = items[self.index]

	-- Handle no current selection or invalid index.
	if not item_current then
		self:stepSelected(-1, self.wrap_selection)

	else
		local current_x = item_current.x
		local current_y = item_current.y

		local i = self.index
		local looped = false

		while true do
			i = i - 1
			local item = items[i]

			if not item then
				-- Try again, from the bottom
				if not looped then
					i = #items + 1
					current_y = math.huge
					looped = true

				-- Give up
				else
					--self:stepSelected(-1, self.wrap_selection)
					return
				end

			elseif item.selectable and item.y + item.h <= current_y and item.x <= current_x then
				self:setSelectedIndex(i)
				return
			end
		end
	end
end


--- Stepping forwards, select the first item whose top edge is >= the current item's bottom edge and whose right edge
--  is >= the current item's right edge. If no suitable item is found, try again starting from the top. If there is
--  no selection, follow the standard behavior of stepSelected(). Intended for 2D grids of menu-items arranged
--  left-to-right, top-to-bottom.
function _mt_menu:moveSelectedGridDown() -- XXX needs testing

	local items = self.items
	local item_current = items[self.index]

	-- Handle no current selection or invalid index.
	if not item_current then
		self:stepSelected(1, self.wrap_selection)

	else
		local current_x = item_current.x + item_current.w
		local current_y = item_current.y + item_current.h

		local i = self.index
		local looped = false

		while true do
			i = i + 1
			local item = items[i]

			if not item then
				-- Try again, from the bottom
				if not looped then
					i = 0
					current_y = -math.huge
					looped = true

				-- Give up
				else
					--self:stepSelected(1, self.wrap_selection)
					return
				end

			elseif item.selectable and item.y >= current_y and item.x + item.w >= current_x then
				self:setSelectedIndex(i)
				return
			end
		end
	end
end


--- Stepping backwards, select the first item at the same Y position whose right edge is <= the current item's left
--  edge. If no suitable item is found, try again starting from the end of the row. If there is no selection, follow
--  the standard behavior of stepSelected(). Intended for 2D grids of menu-items arranged left-to-right, top-to-bottom.
function _mt_menu:moveSelectedGridLeft() -- XXX needs testing

	local items = self.items
	local item_current = items[self.index]

	-- Handle no current selection or invalid index.
	if not item_current then
		self:stepSelected(-1, self.wrap_selection)

	else
		local current_x = item_current.x
		local current_y = item_current.y

		local i = self.index
		local i_start = i
		local looped = false

		while true do
			i = i - 1
			local item = items[i]

			if not item or item.y < current_y then
				-- Try again from the end of the row.
				if not looped then
					i = i_start
					while true do
						local item2 = items[i]
						if item2 and item2.y <= current_y then
							i = i + 1
						else
							break
						end
					end
					looped = true

				-- Give up
				else
					--self:stepSelected(-1, self.wrap_selection)
					return
				end

			elseif item.selectable and item.x + item.w <= current_x then
				self:setSelectedIndex(i)
				return
			end
		end
	end
end


--- Stepping forwards, select the first item at the same Y position whose left edge is >= the current item's right
--  edge. If no suitable item is found, try again starting from the beginning of the row. If there is no selection,
--  follow the standard behavior of stepSelected(). Intended for 2D grids of menu-items arranged left-to-right,
--  top-to-bottom.
function _mt_menu:moveSelectedGridRight() -- XXX needs testing

	local items = self.items
	local item_current = items[self.index]

	-- Handle no current selection or invalid index.
	if not item_current then
		self:stepSelected(1, self.wrap_selection)

	else
		local current_x = item_current.x
		local current_y = item_current.y

		local i = self.index
		local i_start = i
		local looped = false

		while true do
			i = i + 1
			local item = items[i]

			if not item or item.y > current_y then
				-- Try again from the start of the row.
				if not looped then
					i = i_start
					while true do
						local item2 = items[i]
						if item2 and item2.y >= current_y then
							i = i - 1
						else
							break
						end
					end
					looped = true

				-- Give up
				else
					--self:stepSelected(-1, self.wrap_selection)
					return
				end

			elseif item.selectable and item.x + item.w >= current_x then
				self:setSelectedIndex(i)
				return
			end
		end
	end
end


--- Get a menu item's index using a linear search.
-- @param item_t The item table. Must be populated in the menu, or else the function will raise a Lua error.
-- @return The item index.
function _mt_menu:getItemIndex(item_t)

	for i, item in ipairs(self.items) do
		if item == item_t then
			return i
		end
	end

	error("item table is not present in this menu.")
end


function _mt_menu:hasItem(item_t)

	for i, item in ipairs(self.items) do
		if item == item_t then
			return i
		end
	end

	return false
end


-- * Plug-in methods *


--- Apply common defaults to a widget instance that is acting as a single menu. Note that this does not create an
--  embedded menu table: it just prepares the widget itself with commonly used variables. Additionally, some widgets
--  may not support all of the features that are implied by these fields, so calling this is not a requirement of
--  all menu widgets.
-- @param self The widget to configure.
function commonMenu.instanceSetup(self)

	-- Requires: scroll registers, viewport #1, viewport #2, document dimensions.

	-- Extends the selected item dimensions when scrolling to keep it within the bounds of the viewport.
	self.selection_extend_x = 0
	self.selection_extend_y = 0

	-- Used with click-sequence (cseq) state to prevent drifting double-clicks.
	self.mouse_clicked_item = false

	-- Ref to currently-hovered item, or false if not hovering over any items.
	self.item_hover = false

	-- When true, clicking+dragging continuously selects new items.
	-- When "auto-off", dragging outside of any item box deselects.
	self.drag_select = false

	-- When truthy, mouse-hover continuously selects the current hovered item.
	-- Only happens when mouse DX and DY are non-zero.
	-- When "auto-off", hover-off deselects any current selection.
	self.hover_to_select = false

	-- How many items to jump when pressing pageup or pagedown, or equivalent gamepad buttons.
	self.page_jump_size = 4
	self.wheel_jump_size = 64 -- pixels

	-- Range of items that are visible and should be checked for press/hover state.
	self.items_first = 0 -- max(first, 1)
	self.items_last = 2^53 -- min(last, #items)

	-- Optional:
	-- self.auto_range ("h" or "v") -> sets items_first and items_last.

	-- Also used by other integrated components:
	-- self.press_busy

	-- Make your menu object at `self.menu`.
end


--- Automatically set a widget's items_first and items_last values by checking their vertical positions.
-- @param self The widget.
function commonMenu.widgetAutoRangeV(self)

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
	self.items_first = first or 1
	self.items_last = last or #menu.items
end


--- Automatically set a widget's items_first and items_last values by checking their horizontal positions.
-- @param self The widget.
function commonMenu.widgetAutoRangeH(self)

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
	self.items_first = first or 1
	self.items_last = last or #menu.items
end


--- Get the first item in a range that intersects the point at (px,py). The item's 'selectable' state is not checked.
-- @param items The 'client.menu.items' table.
-- @param px X coordinate to check, relative to widget top-left.
-- @param py Y coordinate to check, relative to widget top-left.
-- @param first Index of the first item in the list to check.
-- @param last Index of the last item in the list to check.
-- @return The item index and table, if successful. Otherwise, returns nil.
function commonMenu.widgetGetItemAtPoint(self, px, py, first, last)

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

	return nil
end


--- Like widgetGetItemAtPoint(), but checks only the vertical axis. Intended for vertically oriented menus.
-- @param items The 'client.menu.items' table.
-- @param px Unused. Included for compatibility with variant functions.
-- @param py Y coordinate to check, relative to widget top.
-- @param first Index of the first item in the list to check (ie 1).
-- @param last Index of the last item in the list to check (ie #items).
-- @return The item index and table, if successful. Otherwise, returns nil.
function commonMenu.widgetGetItemAtPointV(self, px, py, first, last)

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
function commonMenu.widgetGetItemAtPointVClamp(self, px, py, first, last)

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
function commonMenu.widgetGetItemAtPointH(self, px, py, first, last)

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
function commonMenu.widgetTrySelectItemAtPoint(self, x, y, first, last)

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
function commonMenu.widgetSelectItemByIndex(self, item_i)

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
function commonMenu.arrangeListVerticalTB(self, first, last)

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
function commonMenu.arrangeListVerticalLRTB(self, first, last)

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
function commonMenu.arrangeListHorizontalLR(self, first, last)

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
function commonMenu.arrangeListHorizontalTBLR(self, first, last)

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
	They were originally built into the generic menu widget, but have been moved here so that other widgets can
	access them.

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
function commonMenu.widgetMovePrev(self, n, immediate)

	self.menu:setSelectedPrev(n)

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
function commonMenu.widgetMoveNext(self, n, immediate)

	self.menu:setSelectedNext(n)

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
function commonMenu.widgetMoveFirst(self, immediate)

	self.menu:setSelectedIndexFirst()

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
function commonMenu.widgetMoveLast(self, immediate)

	self.menu:setSelectedIndexLast()

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
function commonMenu.keyNavTB(self, key, scancode, isrepeat)

	if scancode == "up" then
		self:movePrev(1)
		return true

	elseif scancode == "down" then
		self:moveNext(1)
		return true

	elseif scancode == "home" then
		self:moveFirst()
		return true

	elseif scancode == "end" then
		self:moveLast()
		return true

	elseif scancode == "pageup" then
		self:movePrev(self.page_jump_size)
		return true

	elseif scancode == "pagedown" then
		self:moveNext(self.page_jump_size)
		return true
	end
end


--- Default key navigation for left-to-right menus.
function commonMenu.keyNavLR(self, key, scancode, isrepeat)

	if scancode == "left" then
		self:movePrev(1)
		return true

	elseif scancode == "right" then
		self:moveNext(1)
		return true

	elseif scancode == "home" then
		self:moveFirst()
		return true

	elseif scancode == "end" then
		self:moveLast()
		return true

	elseif scancode == "pageup" then
		self:movePrev(self.page_jump_size)
		return true

	elseif scancode == "pagedown" then
		self:moveNext(self.page_jump_size)
		return true
	end
end


--- For every table in an array, if a 'config' method is present, run it on the table with 'self' as an argument.
--  Use to refresh the selectable / usable state of menu items. (Depending on the use case, the tables need not be
--  fully functional menu items. They could also be shared definition tables that are copied to live items at a later
--  time.)
-- @param self Presumably the client widget that owns the menu. (Could be something else depending on the implementation.)
-- @param array The array containing menu-items or tables similar to menu-items.
function commonMenu.widgetConfigureMenuItems(self, array)

	for i, tbl in ipairs(array) do
		if tbl.config then
			tbl:config(self)
		end
	end
end


--- Get the combined dimensions of all items in the menu. Assumes that all items have X and Y positions >= 0.
-- @param items The table of menu-items to scan.
-- @return The bounding width and height of all items.
function commonMenu.getCombinedItemDimensions(items)

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
function commonMenu.getItemInBoundsRect(self, item, immediate)

	--[[
	Widget must have 'selection_extend_x' and 'selection_extend_y' set.
	--]]

	self:scrollRectInBounds(
		item.x - self.selection_extend_x,
		item.y - self.selection_extend_y,
		item.x + item.w + self.selection_extend_x,
		item.y + item.h + self.selection_extend_y,
		immediate
	)
end


--- Like getItemInBoundsRect, but acts on the horizontal axis only.
-- @param self The menu widget.
-- @param item The item within the menu to get in view.
-- @param immediate Skip scrolling animation when true.
function commonMenu.getItemInBoundsX(self, item, immediate)

	--[[
	Widget must have 'selection_extend_x' set.
	--]]

	self:scrollXInBounds(
		item.x - self.selection_extend_x,
		item.x + item.w + self.selection_extend_x,
		immediate
	)
end


--- Like getItemInBoundsRect, but acts on the vertical axis only.
-- @param self The menu widget.
-- @param item The item within the menu to get in view.
-- @param immediate Skip scrolling animation when true.
function commonMenu.getItemInBoundsY(self, item, immediate)

	--[[
	Widget must have 'selection_extend_y' set.
	--]]

	self:scrollYInBounds(
		item.y - self.selection_extend_y,
		item.y + item.h + self.selection_extend_y,
		immediate
	)
end


--- If there is a current selection and it is not within view, scroll to it.
-- @param self The menu widget with a current selection (or none).
-- @param immediate When true, skip scrolling animation.
function commonMenu.selectionInView(self, immediate)

	--[[
	Widget must have a 'getInBounds' method assigned. These methods usually require 'selection_extend_[x|y]' to be set.
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


return commonMenu

