--[[
Widget Component: Menu

Usage:

* Run 'wcMenu.attachMenuMethods()' on the widget definition.

* Run 'wcMenu.setup()' on the widget instance during creation.
--]]


local context = select(1, ...)


local wcMenu = {}


local pMath = require(context.conf.prod_ui_req .. "lib.pile_math")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiTable = require(context.conf.prod_ui_req .. "ui_table")
local wcScrollBar = context:getLua("shared/wc/wc_scroll_bar")
local widShared = context:getLua("core/wid_shared")


local _signP = pMath.signP
local _clamp = pMath.clamp


local menuMethods = {}


function wcMenu.attachMenuMethods(self)
	uiTable.patch(self, menuMethods, false)
end


--- Check if the menu has any items that can be selected.
-- @return index and table of the first selectable item, or nil if there are no selectable items.
function menuMethods:menuHasAnySelectableItems()
	for i, item in ipairs(self.MN_items) do
		if item.selectable then
			return i, item
		end
	end
end


--- Check if an item index is selectable, and if not, provide a string explaining why.
-- @param index The item index to check. Must be an integer (or else the method throws an error).
-- @param return true if selectable, false plus string if not.
function menuMethods:menuCanSelect(index)
	uiAssert.integer(1, index)

	-- Permit deselection
	if index == 0 then
		return true

	-- Out of bounds check
	elseif index < 0 or index > #self.MN_items then
		return false, "list index is out of range."

	-- Requested item is not selectable
	elseif not self.MN_items[index].selectable then
		return false, "item is not selectable."
	end

	return true
end


--- Given an item index and a direction (previous or next), pick the closest item that is selectable (including the start index).
-- @param i The starting index (1..#self.MN_items).
-- @param dir The desired direction to move in, if the current index is not selectable. Can be 1 or -1.
-- @return The most suitable selectable item index, or nil if there were no selectable item.
function menuMethods:menuFindSelectableLanding(i, dir)
	local item
	repeat
		item = self.MN_items[i]
		if item and item.selectable then
			return i
		end
		i = i + dir
	until not item

	-- nothing is selectable
end


function menuMethods:menuGetDefaultSelection()
	if not self.MN_default_deselect then
		local first_sel_i, first_sel = false, false

		-- Prefer the first item with 'is_default_selection'.
		-- If no default is set, fall back to the first selectable item.
		for i, item in ipairs(self.MN_items) do
			if item.selectable then
				if item.is_default_selection then
					return i, item

				elseif not first_sel_i then
					first_sel_i = i
					first_sel = item
				end
			end
		end

		if first_sel_i then
			return first_sel_i, first_sel
		end
	end

	-- nothing is selectable
	return 0
end


--- Get the current selected item table. Equivalent to `local item_t = self.MN_items[self.MN_index]`.
-- @param id ("MN_index") The index key.
-- @return The selected item, or nil if there is no current selection.
function menuMethods:menuGetSelectedItem(id)
	id = id or "MN_index"

	return self.MN_items[self[id]]
end


--- Get a selection from a position.
function menuMethods:menuGetSelectionStep(pos, delta, wrap)
	delta = math.floor(delta + 0.5)

	-- Starting from no selection:
	if pos == 0 then
		-- If wrapping, depending on the direction, go to the top-most or bottom-most selectable.
		-- Default to nothing if there are no selectable items.
		-- Zero delta is treated like a positive value (forward).
		if wrap then
			if delta < 0 then
				pos = self:menuFindSelectableLanding(#self.MN_items, -1) or 0
			else
				pos = self:menuFindSelectableLanding(1, 1) or 0
			end

		-- Not wrapping: go to the top-most selection, regardless of the delta.
		-- Default to nothing if there are no selectable items.
		else
			pos = self:menuFindSelectableLanding(1, 1) or 0
		end
	-- Normal selection handling:
	else
		pos = _clamp(math.floor(pos), 1, #self.MN_items)

		-- Special handling for wrap-around. Wrapping only happens if the selection is at the edge
		-- of the list, and it always puts the selector at the first selectable item on the opposite
		-- side.
		if wrap then
			if delta < 0 and not self:menuFindSelectableLanding(pos - 1, -1) then
				pos = self:menuFindSelectableLanding(#self.MN_items, -1) or 0
				return pos

			elseif delta >= 0 and not self:menuFindSelectableLanding(pos + 1, 1) then
				pos = self:menuFindSelectableLanding(1, 1) or 0
				return pos
			end
		end

		-- Advance.
		pos = pos + delta
		pos = _clamp(math.floor(pos), 1, #self.MN_items)

		local dir = _signP(delta)

		-- If the new item is not selectable, then we need to hunt for the closest one nearby that is.
		pos = self:menuFindSelectableLanding(pos, dir) or self:menuFindSelectableLanding(pos - dir, -dir) or 0
	end

	return pos
end


--- The first selectable menu item.
function menuMethods:menuGetFirstSelectableIndex()
	return self:menuFindSelectableLanding(1, 1) or 0
end


--- The last selectable menu item.
function menuMethods:menuGetLastSelectableIndex()
	return self:menuFindSelectableLanding(#self.MN_items, -1) or 0
end


--- Get the nearest menu-item based on an XY position.
-- @param x, y Central search location. Compared with the center positions of items (item.x + item.w/2).
-- @param dx, dy Limit the search range of the first loop by blocking off items on four sides.
--   dx|dy ==  0: Don't limit.
--   dx|dy == -1: First loop only checks items to the left/top.
--   dx|dy ==  1: First loop only checks items to the right/bottom.
-- @param wrap If true, when no matches are found, run the loop again starting from the edges that were blocked off.
-- @return Closest item index and table, or nil if no match was found.
function menuMethods:menuGetNearestItem2D(pos, x, y, dx, dy, wrap) -- XXX: Untested
	local items = self.MN_items
	local item_current = items[pos]

	if not item_current then
		return
	end

	local item_closest, index_closest
	local dist = math.huge

	local min_x, min_y, max_x, max_y = -math.huge, -math.huge, math.huge, math.huge

	for wrap_loop = 1, 2 do
		for i, item in ipairs(items) do
			local ix, iy = item.x + item.w/2, item.y + item.h/2

			if item ~= item_current then
				min_x = math.max(min_x, item.x + item.w/2)
				min_y = math.max(min_y, item.y + item.h/2)
				max_x = math.min(max_x, item.x + item.w/2)
				max_y = math.min(max_y, item.y + item.h/2)

				if (dx == 0 or (dx == -1 and ix <= x) or (dx == 1 and ix >= x))
				and (dy == 0 or (dy == -1 and iy <= y) or (dy == 1 and iy >= y))
				then
					local this_dist = math.sqrt((x-cx)*(cx-x) + (y-cy)*(y-cy))

					if not item_closest or this_dist < dist then
						item_closest = item
						index_closest = i
						dist = this_dist
					end
				end
			end

			if item_closest or not wrap then
				break
			end

			-- Setup potential next loop.
			item_closest = nil
			index_closest = nil
			dist = math.huge
			x = (dx == -1) and min_x or (dx == 1) and max_x or x
			y = (dy == -1) and min_y or (dy == 1) and max_y or y
		end
	end

	return index_closest, item_closest
end


--- Get a menu item's index using a linear search.
-- @param item_t The item table. Must be populated in the menu, or else the function will raise a Lua error.
-- @return The item index.
function menuMethods:menuGetItemIndex(item_t)
	for i, item in ipairs(self.MN_items) do
		if item == item_t then
			return i
		end
	end

	error("item table is not present in this menu.")
end


function menuMethods:menuHasItem(item_t)
	for i, item in ipairs(self.MN_items) do
		if item == item_t then
			return i
		end
	end
end


--- Sets the current menu selection. If the index is invalid or the item cannot be selected, raises a Lua error.
-- @param index The index of the menu item to select.
-- @param id ("index") Specify an alternative table key, if applicable.
function menuMethods:menuSetSelectedIndex(index, id)
	id = id or "MN_index"

	local ok, err = self:menuCanSelect(index)
	if not ok then
		error(err)
	end

	self[id] = index

	return self
end


--- Sets the menu selection by item table; a wrapper for menuGetItemIndex() and menuSetSelectedIndex().
-- @param item_t The item table to select. It must be present in the menu items array.
-- @param id ("index") Specify an alternative table key, if applicable.
function menuMethods:menuSetSelectedItem(item_t, id)
	local item_i = self:menuGetItemIndex(item_t)
	self:menuSetSelectedIndex(item_i, id)

	return self
end


--- Sets the current menu selection to the default.
function menuMethods:menuSetDefaultSelection(id)
	local i, tbl = self:menuGetDefaultSelection()
	self:menuSetSelectedIndex(i, id)

	return self
end


--- Move the current menu selection index.
-- @param delta The direction to move in. 1 == forward, -1 == backward, 0 == stay put (and do the clamping and landing checks). You can move more than one step at a time.
-- @param wrap (boolean) When true, wrap around the list when at the first or last selectable item.
-- @param id ("index") Key ID for the index. Specify when using additional index variables.
function menuMethods:menuSetSelectionStep(delta, wrap, id)
	id = id or "MN_index"

	self[id] = self:menuGetSelectionStep(self[id], delta, wrap)

	return self
end


function menuMethods:menuSetFirstSelectableIndex(id)
	id = id or "MN_index"

	self[id] = self:menuGetFirstSelectableIndex()

	return self
end


function menuMethods:menuSetLastSelectableIndex(id)
	id = id or "MN_index"

	self[id] = self:menuGetLastSelectableIndex()

	return self
end


--- Move to the previous selectable menu item.
function menuMethods:menuSetPrev(n, wrap, id)
	id = id or "MN_index"

	n = n and math.max(math.floor(n), 1) or 1
	self:menuSetSelectionStep(-n, wrap, id)

	return self
end


--- Move to the next selectable menu item.
function menuMethods:menuSetNext(n, wrap, id)
	id = id or "MN_index"

	n = n and math.max(math.floor(n), 1) or 1
	self:menuSetSelectionStep(n, wrap, id)

	return self
end


function menuMethods:menuSetMarkedItem(item_t, marked)
	uiAssert.type(1, item_t, "table")

	item_t.marked = not not marked

	return self
end


function menuMethods:menuToggleMarkedItem(item_t)
	uiAssert.type(1, item_t, "table")

	item_t.marked = not item_t.marked

	return self
end


function menuMethods:menuSetMarkedItemByIndex(item_i, marked)
	uiAssert.type(1, item_i, "number")

	local item_t = self.MN_items[item_i]

	self:menuSetMarkedItem(item_t, marked)

	return self
end


--- Produces a table that contains all items that are currently marked (multi-selected).
function menuMethods:menuGetAllMarkedItems()
	local tbl = {}

	for i, item in ipairs(self.MN_items) do
		if item.marked then
			table.insert(tbl, item)
		end
	end

	return tbl
end


function menuMethods:menuClearAllMarkedItems()
	for i, item in ipairs(self.MN_items) do
		item.marked = false
	end

	return self
end


function menuMethods:menuSetMarkedItemRange(marked, first, last)
	local items = self.MN_items
	uiAssert.integerRange(2, first, 1, #items)
	uiAssert.integerRange(3, last, 1, #items)
	marked = not not marked

	for i = first, last do
		items[i].marked = marked
	end

	return self
end


function menuMethods:menuHasMarkedItems()
	for _, item in ipairs(self.MN_items) do
		if item.marked then
			return true
		end
	end

	return false
end


function menuMethods:menuCountMarkedItems()
	local c = 0

	for _, item in ipairs(self.MN_items) do
		if item.marked then
			c = c + 1
		end
	end

	return c
end


function menuMethods:menuMoveItem(i, j)
	uiTable.moveElement(self.MN_items, i, j)

	return self
end


function menuMethods:menuSwapItems(i, j)
	uiTable.swapElements(self.MN_items, i, j)

	return self
end


--- Sets up a widget to act as a menu. Note that not all widgets support all of the features
--	implied by this function.
-- @param self The widget to configure.
-- @param items An existing table of items, if applicable. When not provided, a fresh items table is created.
-- @param setup_mark When true, setup marking state (for multiple selections).
-- @param setup_drag When true, setup drag-and-drop state.
function wcMenu.setup(self, items, setup_mark, setup_drag_drop)
	-- Requires: scroll registers, viewport #1, viewport #2, document dimensions.

	self.MN_items = items or {}

	-- The main selection index.
	self.MN_index = 0

	-- When true, the default selection is nothing (0).
	self.MN_default_deselect = false

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
	-- NOTE: this value is typically used with menus that only display one item at a time.
	-- Menu widgets that show muliple items would, instead, probably use the menu viewport
	-- size to determine how far to move.
	self.MN_page_jump_size = 4

	-- Range of items that are visible, and which should be checked for hover state.
	self.MN_items_first = 0 -- max(first, 1)
	self.MN_items_last = 2^53 -- min(last, #items)

	-- Wrap selection when pressing against the last selectable item.
	-- true, false, "no-rep"
	-- "no-rep": only wrap if the input is not a repeat event.
	self.MN_wrap_selection = true

	-- Scroll the view while dragging the mouse.
	self.MN_drag_scroll = false

	-- When true, clicking+dragging continuously selects new items.
	-- When "auto-off", dragging outside of any item box deselects.
	self.MN_drag_select = false

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
end


--- Automatically set a widget's items_first and items_last values by checking their vertical positions.
-- @param self The widget.
function wcMenu.widgetAutoRangeV(self)
	local items = self.MN_items
	local vp2 = self.vp2

	local first, last
	local r1 = vp2.y + self.scr_y
	local r2 = r1 + vp2.h

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
	self.MN_items_last = last or #items
end


--- Automatically set a widget's items_first and items_last values by checking their horizontal positions.
-- @param self The widget.
function wcMenu.widgetAutoRangeH(self)
	local items = self.MN_items
	local vp2 = self.vp2

	local first, last
	local r1 = vp2.x + self.scr_x
	local r2 = r1 + vp2.w

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
	self.MN_items_last = last or #items
end


--[[
Implementations for 'wid:getItemAtPoint(px, py, first, last)'

These methods get the first item in a range that intersects the point at (px, py). Variations are provided for
checking only one axis, and to clamp to the first and last items.

Some arguments may not be checked in certain variations, but they should be supplied anyways for API compatibility.

The functions do not check the item's 'selectable' state, and they assume that scroll bar intersection tests
(if applicable) have already been checked.

-- @param items The 'client.MN_items' table.
-- @param px X position (relative to widget, with scroll offset).
-- @param py Y position (relative to widget, with scroll offset).
-- @param first Index of the first item in the list to check.
-- @param last Index of the last item in the list to check.
-- @return If successful: the item index and table, and a number indicating if clamping occurred (-1, 1 or nil).
--	If not successful: nil.
--]]
function wcMenu.widgetGetItemAtPoint(self, px, py, first, last)
	local items = self.MN_items
	for i = first, last do
		local item = items[i]
		if px >= item.x and px < item.x + item.w and py >= item.y and py < item.y + item.h then
			return i, item
		end
	end
end


function wcMenu.widgetGetItemAtPointV(self, px, py, first, last)
	local items = self.MN_items
	for i = first, last do
		local item = items[i]
		if py >= item.y and py < item.y + item.h then
			return i, item
		end
	end
end


function wcMenu.widgetGetItemAtPointVClamp(self, px, py, first, last)
	local items = self.MN_items
	local i1, i2 = items[1], items[#items]

	if i1 and py < i1.y + i1.h then
		return 1, i1, -1

	elseif i2 and py >= i2.y then
		return #items, i2, 1
	end

	for i = math.max(2, first), math.min(#items - 1, last) do
		local item = items[i]
		if py >= item.y and py < item.y + item.h then
			return i, item
		end
	end
end


function wcMenu.widgetGetItemAtPointH(self, px, py, first, last)
	local items = self.MN_items
	for i = first, last do
		local item = items[i]
		if px >= item.x and px < item.x + item.w then
			return i, item
		end
	end
end


--- Call the getItemAtPoint method, and if a selectable item is found, select it, update scrolling, etc.
-- @param x, y The position (relative to widget, with scroll offset).
-- @param first, last The first and last widgets to check.
-- @return The index and item table, or nil if no item was found.
function wcMenu.widgetTrySelectItemAtPoint(self, x, y, first, last)
	-- Prerequisites: widget must have a 'getItemAtPoint()' method assigned.

	local i, item = self:getItemAtPoint(x, y, first, last)

	if item and item.selectable then
		self:menuSetSelectedIndex(i)
		if self.selectionInView then
			self:selectionInView()
		end

		return i, item
	end
end


--- Use when you've already located an item and confirmed that it is selectable.
function wcMenu.widgetSelectItemByIndex(self, item_i)
	self:menuSetSelectedIndex(item_i)

	if self.selectionInView then
		self:selectionInView()
	end

	return self
end


--[[
	Here are some built-in arrangement functions. They expect the dimensions of items to already be correct,
	relative to the size of the viewport (or the widget, if no viewport index is provided).

	Wrap them in 'def:arrangeItems(first, last)' in your widget code.

	General notes:

	* If the list is empty or the range is invalid, do nothing.
	* If there is an item before 'first', then piggy-back off of its location.

	rel_zero: when true, the function does not account for viewport positions. This is desirable
	when the menu items are placed in a scrolling widget relative to Viewport #1 (where position
	0,0 is offset a bit from the edge, due to margins).
--]]


wcMenu.arrangers = {
	-- list, top-to-bottom
	["list-tb"] = function(self, vp, rel_zero, i1, i2)
		local items = self.MN_items
		i1, i2 = i1 or 1, i2 or #items
		if #items == 0 or i1 > i2 then
			return
		end
		local vx, vy = widShared.getViewportXYWH(self, vp, rel_zero)
		local yy = vy
		local item_prev = items[i1 - 1]
		if item_prev then
			yy = item_prev.y + item_prev.h
		end
		for i = i1, i2 do
			local item = items[i]
			item.x, item.y = vx, yy
			yy = item.y + item.h
		end
	end,

	-- list, left-to-right then top-to-bottom
	--[[
	123
	456
	…
	--]]
	["list-lrtb"] = function(self, vp, rel_zero, i1, i2)
		local items = self.MN_items
		i1, i2 = i1 or 1, i2 or #items
		if #items == 0 or i1 > i2 then
			return
		end
		local vx, vy, vw = widShared.getViewportXYWH(self, vp, rel_zero)
		local xx, yy = vx, vy
		local item_prev = items[i1 - 1]
		if item_prev then
			xx, yy = item_prev.x + item_prev.w, item_prev.y
		end
		for i = i1, i2 do
			local item = items[i]
			if xx + item.w > vw then
				xx, yy = vx, yy + item.h
			end
			item.x, item.y = xx, yy
			xx = item.x + item.w
		end
	end,

	-- list, left-to-right
	["list-lr"] = function(self, vp, rel_zero, i1, i2)
		local items = self.MN_items
		i1, i2 = i1 or 1, i2 or #items
		if #items == 0 or i1 > i2 then
			return
		end
		local vx, vy = widShared.getViewportXYWH(self, vp, rel_zero)
		local xx = vx
		local item_prev = items[i1 - 1]
		if item_prev then
			xx = item_prev.x + item_prev.x
		end
		for i = i1, i2 do
			local item = items[i]
			item.x, item.y = xx, vy
			xx = item.x + item.w
		end
	end,

	-- list, top-to-bottom then left-to-right
	--[[
	14…
	25
	36
	--]]
	["list-tblr"] = function(self, vp, rel_zero, i1, i2)
		local items = self.MN_items
		i1, i2 = i1 or 1, i2 or #items
		if #items == 0 or i1 > i2 then
			return
		end
		local vx, vy, vw, vh = widShared.getViewportXYWH(self, vp, rel_zero)
		local xx, yy = vx, vy
		local item_prev = items[i1 - 1]
		if item_prev then
			xx = item_prev.x
			yy = item_prev.y + item_prev.w
		end
		for i = i1, i2 do
			local item = items[i]
			if yy + item.h > vh then
				xx, yy = xx + item.w, vy
			end
			item.x, item.y = xx, yy
			yy = item.y + item.h
		end
	end
}


--[[
	Some default selection methods for widgets, assuming they support scrolling viewports.

	The following optional methods may be attached to the widget:

	self:selectionInView()
	self:cacheUpdate()
--]]


local function _checkAllowWrap(is_repeat, wrap_selection)
	if wrap_selection == true then
		return true

	elseif wrap_selection == "no-rep" and not is_repeat then
		return true
	end

	return false
end


--- Move the widget menu selection back by an arbitrary number of steps. If applicable: update scrolling such that the
--  selection is in view, and update the widget's visual cache.
-- @param self The menu widget.
-- @param n (1) How many steps to move.
-- @param immediate Passed to selectionInView(). Skips scrolling animation.
-- @param is_repeat True if the source event is considered a repeating action (like holding down a keyboard key).
-- @param id ("MN_index") Optional alternative index key to change.
function wcMenu.widgetMovePrev(self, n, immediate, is_repeat, id)
	self:menuSetPrev(n, _checkAllowWrap(is_repeat, self.MN_wrap_selection), id)

	if self.selectionInView then
		self:selectionInView(immediate)
	end
	if self.cacheUpdate then
		self:cacheUpdate(false)
	end

	return self
end


--- Move the widget menu selection forward by an arbitrary number of steps. If applicable: update scrolling such that
--  the selection is in view, and update the widget's visual cache.
-- @param self The menu widget.
-- @param n (1) How many steps to move.
-- @param immediate Passed to selectionInView(). Skips scrolling animation.
-- @param is_repeat True if the source event is considered a repeating action (like holding down a keyboard key).
-- @param id ("MN_index") Optional alternative index key to change.
function wcMenu.widgetMoveNext(self, n, immediate, is_repeat, id)
	self:menuSetNext(n, _checkAllowWrap(is_repeat, self.MN_wrap_selection), id)

	if self.selectionInView then
		self:selectionInView(immediate)
	end
	if self.cacheUpdate then
		self:cacheUpdate(false)
	end

	return self
end


--- Move the widget menu selection to the first selectable (or nothing, if there is no selectable item). If applicable:
--  update scrolling such that the selection is in view, and update the widget's visual cache.
-- @param self The widget hosting the menu table.
-- @param immediate Passed to selectionInView(). Skips scrolling animation.
-- @param id ("MN_index") Optional alternative index key to change.
function wcMenu.widgetMoveFirst(self, immediate, id)
	self:menuSetFirstSelectableIndex(id)

	if self.selectionInView then
		self:selectionInView(immediate)
	end
	if self.cacheUpdate then
		self:cacheUpdate(false)
	end

	return self
end


--- Move the widget menu selection to the last selectable (or nothing, if there is no selectable item). If applicable:
--  update scrolling such that the selection is in view, and update the widget's visual cache.
-- @param self The widget hosting the menu table.
-- @param immediate Passed to selectionInView(). Skips scrolling animation.
-- @param id ("MN_index") Optional alternative index key to change.
function wcMenu.widgetMoveLast(self, immediate, id)
	self:menuSetLastSelectableIndex(id)

	if self.selectionInView then
		self:selectionInView(immediate)
	end
	if self.cacheUpdate then
		self:cacheUpdate(false)
	end

	return self
end


local function _pageStep(self, index, vert, dir, dist)
	local items = self.MN_items
	local item = items[index]
	if not item then
		return
	end
	local candidate = items[index + dir]

	local pos, len
	if vert then
		pos, len = "y", "h"
	else
		pos, len = "x", "w"
	end
	local point = item[pos] + (dist * dir)

	if dir == -1 then
		for i = index - 1, 1, -1 do
			local item2 = items[i]
			if item2[pos] + item2[len] >= point then
				if item.selectable then
					candidate = item2
				end
			else
				break
			end
		end

	elseif dir == 1 then
		for i = index + 1, #items do
			local item2 = items[i]
			if item2[pos] <= point then
				if item.selectable then
					candidate = item2
				end
			else
				break
			end
		end

	else
		error("bad direction.")
	end

	return candidate
end


--- Move the widget menu selection up, preferring an item that is the distance of one "page" from the current
--	selection. Viewport #1's height is used for the page size.
function wcMenu.widgetMovePageUp(self, immediate, id)
	id = id or "MN_index"
	if self[id] == 0 then
		wcMenu.widgetMoveFirst(self, immediate, id)
		return
	end

	local dist = self.vp.h * self.context.settings.wimp.navigation.page_viewport_factor
	local new_selection = _pageStep(self, self[id], true, -1, dist)

	if new_selection then
		self:menuSetSelectedItem(new_selection)
		if self.selectionInView then
			self:selectionInView(immediate)
		end
		if self.cacheUpdate then
			self:cacheUpdate(false)
		end
	end

	return self
end


--- Move the widget menu selection down, preferring an item that is the distance of one "page" from the current
--	selection. Viewport #1's height is used for the page size.
function wcMenu.widgetMovePageDown(self, immediate, id)
	id = id or "MN_index"
	if self[id] == 0 then
		wcMenu.widgetMoveFirst(self, immediate, id)
		return
	end

	local dist = self.vp.h * self.context.settings.wimp.navigation.page_viewport_factor
	local new_selection = _pageStep(self, self[id], true, 1, dist)
	if new_selection then
		self:menuSetSelectedItem(new_selection)
		if self.selectionInView then
			self:selectionInView(immediate)
		end
		if self.cacheUpdate then
			self:cacheUpdate(false)
		end
	end

	return self
end


--[[
	Some default key navigation functions.

	They expect the widget to have certain methods assigned for moving the selection which also take care
	of scrolling and updating the visual cache.
--]]


--- Default key navigation for top-to-bottom menus.
-- @param self The widget.
-- @param key, scancode, isrepeat Values from the LÖVE event.
-- @param id ("MN_index") Optional alternative index key to change.
-- @param the isrepeat
function wcMenu.keyNavTB(self, key, scancode, isrepeat, id)
	if scancode == "up" then
		self:movePrev(1, nil, isrepeat, id)
		return true

	elseif scancode == "down" then
		self:moveNext(1, nil, isrepeat, id)
		return true

	elseif scancode == "home" then
		self:moveFirst(id)
		return true

	elseif scancode == "end" then
		self:moveLast(id)
		return true

	elseif scancode == "pageup" then
		self:movePageUp(true)
		return true

	elseif scancode == "pagedown" then
		self:movePageDown(true)
		return true
	end
end


--- Default key navigation for left-to-right menus.
function wcMenu.keyNavLR(self, key, scancode, isrepeat, id)
	if scancode == "left" then
		self:movePrev(1, nil, isrepeat, id)
		return true

	elseif scancode == "right" then
		self:moveNext(1, nil, isrepeat, id)
		return true

	elseif scancode == "home" then
		self:moveFirst(id)
		return true

	elseif scancode == "end" then
		self:moveLast(id)
		return true

	elseif scancode == "pageup" then
		self:movePageUp(true)
		return true

	elseif scancode == "pagedown" then
		self:movePageDown(true)
		return true
	end
end


--- Get the combined dimensions of all items in the menu. Assumes that all items have X and Y positions >= 0.
-- @param items The table of menu-items to scan.
-- @return The bounding width and height of all items.
function wcMenu.getCombinedItemDimensions(items)
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
function wcMenu.getItemInBoundsRect(self, item, immediate)
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

	return self
end


--- Like getItemInBoundsRect, but acts on the horizontal axis only.
-- @param self The menu widget.
-- @param item The item within the menu to get in view.
-- @param immediate Skip scrolling animation when true.
function wcMenu.getItemInBoundsX(self, item, immediate)
	--[[
	Widget must have 'MN_selection_extend_x' set.
	--]]

	self:scrollXInBounds(
		item.x - self.MN_selection_extend_x,
		item.x + item.w + self.MN_selection_extend_x,
		immediate
	)

	return self
end


--- Like getItemInBoundsRect, but acts on the vertical axis only.
-- @param self The menu widget.
-- @param item The item within the menu to get in view.
-- @param immediate Skip scrolling animation when true.
function wcMenu.getItemInBoundsY(self, item, immediate)
	--[[
	Widget must have 'MN_selection_extend_y' set.
	--]]

	self:scrollYInBounds(
		item.y - self.MN_selection_extend_y,
		item.y + item.h + self.MN_selection_extend_y,
		immediate
	)

	return self
end


--- If there is a current selection and it is not within view, scroll to it.
-- @param self The menu widget with a current selection (or none).
-- @param immediate When true, skip scrolling animation.
function wcMenu.selectionInView(self, immediate)
	--[[
	Widget must have a 'getInBounds' method assigned. These methods usually require 'MN_selection_extend_[x|y]' to be set.
	--]]

	local items = self.MN_items
	local item = items[self.MN_index]

	-- No selection or empty list: nothing to do.
	if not item or #items == 0 then
		-- XXX maybe scroll to top-left?
		--self:scrollHV(0, 0)
		return
	else
		self:getInBounds(item, immediate)
	end

	if immediate and self.cacheUpdate then
		self:cacheUpdate(false)
	end

	return self
end


function wcMenu.markItemsCursorMode(self, old_index)
	if not self.MN_mark_index then
		self.MN_mark_index = old_index
	end

	local items = self.MN_items

	local first, last = math.min(self.MN_mark_index, self.MN_index), math.max(self.MN_mark_index, self.MN_index)
	first, last = math.max(1, math.min(first, #items)), math.max(1, math.min(last, #items))

	self:menuSetMarkedItemRange(true, first, last)
end


-- For evt_pointerPress().
function wcMenu.checkItemIntersect(self, mx, my, button)
	-- Check for the cursor intersecting with a clickable item.
	local item_i, item_t = self:getItemAtPoint(mx, my, math.max(1, self.MN_items_first), math.min(#self.MN_items, self.MN_items_last))

	-- Reset click-sequence if clicking on a different item.
	if self.MN_mouse_clicked_item ~= item_t then
		self.context:forceClickSequence(self, button, 1)
	end
	return item_i, item_t
end


-- For evt_pointerPress().
function wcMenu.pointerPressButton1(self, item_t, old_index)
	if self.MN_mark_mode == "toggle" then
		item_t.marked = not item_t.marked
		self.MN_mark_state = item_t.marked

	elseif self.MN_mark_mode == "cursor" then
		local mods = self.context.key_mgr.mod

		if mods["shift"] then
			-- Unmark all items, then mark the range between the previous and current selections.
			self:menuClearAllMarkedItems()
			wcMenu.markItemsCursorMode(self, old_index)

		elseif mods["ctrl"] then
			item_t.marked = not item_t.marked
			self.MN_mark_index = false

		else
			self:menuClearAllMarkedItems()
			item_t.marked = not item_t.marked
			self.MN_mark_index = false
		end
	end
end


function wcMenu.pointerPressScrollBars(self, x, y, button)
	-- Check for pressing on scroll bar components.
	if button == 1 then
		local fixed_step = 24 -- XXX style/config
		if wcScrollBar.widgetScrollPress(self, x, y, fixed_step) then
			-- Successful mouse interaction with scroll bars should break any existing click-sequence.
			self.context:clearClickSequence()
			return true
		end
	end
end


function wcMenu.pointerPressRepeatLogic(self, x, y, button, istouch, reps)
	-- Repeat-press events for scroll bar buttons
	if wcScrollBar.press_busy_codes[self.press_busy]
	and button == 1
	and button == self.context.mouse_pressed_button
	then
		local fixed_step = 24 -- XXX style/config
		wcScrollBar.widgetScrollPressRepeat(self, x, y, fixed_step)
	end
end


function wcMenu.dragDropReleaseLogic(self)
	local root = self:nodeGetRoot()
	local drop_state = root.drop_state

	if type(drop_state) == "table" then
		local halt = self:wid_dropped(drop_state)
		if halt then
			root.drop_state = false
			return true
		end
	end
end


-- Implements click-and-drag behavior for evt_pointerDrag().
function wcMenu.menuPointerDragLogic(self, mouse_x, mouse_y)
	-- Confirm 'self.press_busy == "menu-drag"' before calling.
	-- "toggle" mark mode is incompatible with all built-in drag-and-drop features.
	-- "cursor" mark mode overrides MN_drag_drop_mode when active (hold shift while clicking and dragging).
	if self.MN_drag_drop_mode and self.MN_mark_mode ~= "toggle" and not self.MN_mark_index then
		local context = self.context
		local mpx, mpy, mpr = context.mouse_pressed_x, context.mouse_pressed_y, context.mouse_pressed_range
		if mouse_x > mpx + mpr or mouse_x < mpx - mpr or mouse_y > mpy + mpr or mouse_y < mpy - mpr then
			self.press_busy = "drag-drop"
			print("Drag it!")

			local drop_state = {}

			drop_state.from = self
			drop_state.id = "menu"
			drop_state.item = self.MN_items[self.MN_index]
			-- menu index could be outdated by the time the drag-and-drop action is completed.

			if self:menuHasMarkedItems() then
				drop_state.marked_items = self:menuGetAllMarkedItems()
			end

			-- XXX: cursor, icon or render callback...?

			context.root:setDragAndDropState(drop_state)
		end
	else
		-- Need to test the full range of items because the mouse can drag outside the bounds of the viewport.

		-- Mouse position with scroll offsets.
		local mx, my = self:getRelativePosition(mouse_x, mouse_y)
		mx = mx + self.scr_x
		my = my + self.scr_y

		local item_i, item_t = self:getItemAtPoint(mx, my, 1, #self.MN_items)
		if item_i and item_t.selectable then
			local items = self.MN_items
			local old_index = self.MN_index
			local old_item = items[old_index]

			if old_item ~= item_t then
				if self.MN_drag_select then
					self:menuSetSelectedIndex(item_i)

					local mods = self.context.key_mgr.mod
					if self.MN_mark_mode == "cursor" and self.MN_mark_index then
						self:menuClearAllMarkedItems()
						wcMenu.markItemsCursorMode(self, old_index)

					elseif self.MN_mark_mode == "toggle" then
						local first, last = math.min(old_index, item_i), math.max(old_index, item_i)
						first, last = math.max(1, first), math.max(1, last)
						self:menuSetMarkedItemRange(self.MN_mark_state, first, last)
					end

					self:wid_select(item_t, item_i)
				end
			end

			-- Turn off item_hover so that other items don't glow.
			self.MN_item_hover = false
		end
	end
end


function wcMenu.getIconQuad(icon_set_id, icon_id)
	if icon_id then
		local icon_set = context.resources.icons[icon_set_id]
		if icon_set then
			return icon_set[icon_id]
		end
	end
end


function wcMenu.setIconSetID(self, icon_set_id) -- TODO: untested
	uiAssert.type(1, icon_set_id, "string")

	self:writeSetting("icon_set_id", icon_set_id)
end


function wcMenu.getIconSetID(self) -- TODO: untested
	return self.icon_set_id
end


function wcMenu.removeItemIndexCleanup(self, item_i, id)
	-- Removed item was the last in the list, and was selected:
	if self[id] > #self.MN_items then
		local landing_i = self:menuFindSelectableLanding(#self.MN_items, -1)
		self:setSelectionByIndex(landing_i or 0, id)

	-- Removed item was not selected, and the selected item appears after the removed item in the list:
	elseif self[id] > item_i then
		self[id] = self[id] - 1
	end

	-- Handle the current selection being removed.
	if self[id] == item_i then
		local landing_i = self:menuFindSelectableLanding(#self.MN_items, -1) or self:menuFindSelectableLanding(#self.MN_items, 1)
		self[id] = landing_i or 0
	end
end


--- Picks the first selectable item, but only if there is currently no selection.
-- The widget must have the method 'setSelectionByIndex'.
function wcMenu.trySelectIfNothingSelected(self)
	if self.MN_index == 0 then
		local i, tbl = self:menuHasAnySelectableItems()
		if i then
			self:setSelectionByIndex(i)
		end
	end
end


return wcMenu
