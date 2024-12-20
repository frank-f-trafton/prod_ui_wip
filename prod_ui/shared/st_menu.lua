-- To load: local lib = context:getLua("shared/lib")


--[[
	Provides the basic guts of a 1D menu.

	Menu items are contained in the array `menu.items`. Each item is a table, and the menu checks
	the following variables when making selections:

	> item.selectable (boolean): This item can be selected by a menu cursor.
		* When moving the cursor, non-selectable items are skipped.
		* If no items are selectable, then the selection index is 0 (no selection).

	> menu.default_deselect (boolean): When true, the default menu item is nothing (index 0).

	> item.is_default_selection (boolean): The item to select by default, if 'menu.default_deselect' is false.
		* When multiple items have this set, the first such item that is selectable is chosen.
		* If no item has this set, then the default is the first selectable item (or if there are no
		  selectable items, then the cursor is set to no selection.)

	The main selection is tracked in `menu.index`. Additional indices can be used by passing in different
	`id` keys to menu methods. `menu.index` gets "camera priority" by higher-level logic.

	Arbitrary multiple selection is implemented by setting the field `marked` on a per-item basis.
	Not all menu widgets support multiple selection.
--]]


local context = select(1, ...)


local stMenu = {}


local commonMath = require(context.conf.prod_ui_req .. "common.common_math")
local pileTable = require(context.conf.prod_ui_req .. "lib.pile_table")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")


local _mt_menu = {}
_mt_menu.__index = _mt_menu


local _sign = commonMath.sign
local _clamp = commonMath.clamp


-- * API *


--- Makes a new menu.
-- @return The menu table.
function stMenu.new()
	local self = {}

	self.items = {}

	-- The main selection index.
	self.index = 0

	-- When true, the default selection is nothing (0).
	self.default_deselect = false

	setmetatable(self, _mt_menu)

	return self
end


-- * Methods *


--- Check if the menu has any items that can be selected.
-- @return index and table of the first selectable item, or false if there are no selectable items.
function _mt_menu:hasAnySelectableItems()
	local items = self.items
	for i = 1, #items do
		if items[i].selectable then
			return i, items[i]
		end
	end

	return false
end


--- Check if an item index is selectable, and if not, provide a string explaining why.
-- @param index The item index to check. Must be an integer (or else the method throws an error).
-- @param return true if selectable, false plus string if not.
function _mt_menu:canSelect(index)
	uiShared.int(1, index)

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

	-- Nothing is selectable.
end


function _mt_menu:getDefaultSelection()
	if not self.default_deselect then
		local first_sel_i, first_sel = false, false

		-- Prefer the first item with 'is_default_selection'.
		-- If no default is set, fall back to the first selectable item.
		for i, item in ipairs(self.items) do
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

	-- Nothing is selectable.
	return 0
end


--- Get the current selected item table. Equivalent to `local item_t = menu.items[menu.index]`.
-- @param id ("index") The index key.
-- @return The selected item, or nil if there is no current selection.
function _mt_menu:getSelectedItem(id)
	id = id or "index"

	return self.items[self[id]]
end


--- Get a selection from a position.
function _mt_menu:getSelectionStep(pos, delta, wrap)
	delta = math.floor(delta + 0.5)

	-- Starting from no selection:
	if pos == 0 then
		-- If wrapping, depending on the direction, go to the top-most or bottom-most selectable.
		-- Default to nothing if there are no selectable items.
		-- Zero delta is treated like a positive value (forward).
		if wrap then
			if delta < 0 then
				pos = self:findSelectableLanding(#self.items, -1) or 0
			else
				pos = self:findSelectableLanding(1, 1) or 0
			end

		-- Not wrapping: go to the top-most selection, regardless of the delta.
		-- Default to nothing if there are no selectable items.
		else
			pos = self:findSelectableLanding(1, 1) or 0
		end
	-- Normal selection handling:
	else
		pos = _clamp(math.floor(pos), 1, #self.items)

		-- Special handling for wrap-around. Wrapping only happens if the selection is at the edge
		-- of the list, and it always puts the selector at the first selectable item on the opposite
		-- side.
		if wrap then
			if delta < 0 and not self:findSelectableLanding(pos - 1, -1) then
				pos = self:findSelectableLanding(#self.items, -1) or 0
				return pos

			elseif delta >= 0 and not self:findSelectableLanding(pos + 1, 1) then
				pos = self:findSelectableLanding(1, 1) or 0
				return pos
			end
		end

		-- Advance.
		pos = pos + delta
		pos = _clamp(math.floor(pos), 1, #self.items)

		local dir = _sign(delta)

		-- If the new item is not selectable, then we need to hunt for the closest one nearby that is.
		pos = self:findSelectableLanding(pos, dir) or self:findSelectableLanding(pos - dir, -dir) or 0
	end

	return pos
end


--- The first selectable menu item.
function _mt_menu:getFirstSelectableIndex()
	return self:findSelectableLanding(1, 1) or 0
end


--- The last selectable menu item.
function _mt_menu:getLastSelectableIndex()
	return self:findSelectableLanding(#self.items, -1) or 0
end


--- Get the nearest menu-item based on an XY position.
-- @param x, y Central search location. Compared with the center positions of items (item.x + item.w/2).
-- @param dx, dy Limit the search range of the first loop by blocking off items on four sides.
--   dx|dy ==  0: Don't limit.
--   dx|dy == -1: First loop only checks items to the left/top.
--   dx|dy ==  1: First loop only checks items to the right/bottom.
-- @param wrap If true, when no matches are found, run the loop again starting from the edges that were blocked off.
-- @return Closest item index and table, or nil if no match was found.
function _mt_menu:getNearest2D(pos, x, y, dx, dy, wrap) -- XXX: Untested
	local items = self.items
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


--- Sets the current menu selection. If the index is invalid or the item cannot be selected, raises a Lua error.
-- @param index The index of the menu item to select.
-- @param id ("index") Specify an alternative table key, if applicable.
function _mt_menu:setSelectedIndex(index, id)
	id = id or "index"

	local ok, err = self:canSelect(index)
	if not ok then
		error(err)
	end

	self[id] = index
end


--- Sets the menu selection by item table; a wrapper for getItemIndex() and setSelectedIndex().
-- @param item_t The item table to select. It must be present in the menu items array.
-- @param id ("index") Specify an alternative table key, if applicable.
function _mt_menu:setSelectedItem(item_t, id)
	local item_i = self:getItemIndex(item_t)
	self:setSelectedIndex(item_i, id)
end


--- Sets the current menu selection to the default.
function _mt_menu:setDefaultSelection(id)
	local i, tbl = self:getDefaultSelection()
	self:setSelectedIndex(i, id)
end


--- Move the current menu selection index.
-- @param delta The direction to move in. 1 == forward, -1 == backward, 0 == stay put (and do the clamping and landing checks). You can move more than one step at a time.
-- @param wrap (boolean) When true, wrap around the list when at the first or last selectable item.
-- @param id ("index") Key ID for the index. Specify when using additional index variables.
function _mt_menu:setSelectionStep(delta, wrap, id)
	id = id or "index"

	self[id] = self:getSelectionStep(self[id], delta, wrap)
end


function _mt_menu:setFirstSelectableIndex(id)
	id = id or "index"

	self[id] = self:getFirstSelectableIndex()
end


function _mt_menu:setLastSelectableIndex(id)
	id = id or "index"

	self[id] = self:getLastSelectableIndex()
end


--- Move to the previous selectable menu item.
function _mt_menu:setPrev(n, wrap, id)
	id = id or "index"

	n = n and math.max(math.floor(n), 1) or 1
	self:setSelectionStep(-n, wrap, id)
end


--- Move to the next selectable menu item.
function _mt_menu:setNext(n, wrap, id)
	id = id or "index"

	n = n and math.max(math.floor(n), 1) or 1
	self:setSelectionStep(n, wrap, id)
end


function _mt_menu:setMarkedItem(item_t, marked)
	uiShared.type1(1, item_t, "table")

	item_t.marked = not not marked
end


function _mt_menu:toggleMarkedItem(item_t)
	uiShared.type1(1, item_t, "table")

	item_t.marked = not item_t.marked
end


function _mt_menu:setMarkedItemByIndex(item_i, marked)
	uiShared.type1(1, item_i, "number")

	local item_t = self.items[item_i]

	self:setMarkedItem(item_t, marked)
end


--- Produces a table that contains all items that are currently marked (multi-selected).
function _mt_menu:getAllMarkedItems()
	local tbl = {}

	for i, item in ipairs(self.items) do
		if item.marked then
			table.insert(tbl, item)
		end
	end

	return tbl
end


function _mt_menu:clearAllMarkedItems()
	for i, item in ipairs(self.items) do
		item.marked = false
	end
end


function _mt_menu:setMarkedItemRange(marked, first, last)
	local items = self.items
	uiShared.intRange(2, first, 1, #items)
	uiShared.intRange(3, last, 1, #items)
	marked = not not marked

	for i = first, last do
		items[i].marked = marked
	end
end


function _mt_menu:hasMarkedItems()
	for _, item in ipairs(self.items) do
		if item.marked then
			return true
		end
	end

	return false
end


function _mt_menu:countMarkedItems()
	local c = 0

	for _, item in ipairs(self.items) do
		if item.marked then
			c = c + 1
		end
	end

	return c
end


function _mt_menu:moveItem(i, j)
	pileTable.moveElement(self.items, i, j)
end


function _mt_menu:swapItems(i, j)
	pileTable.swapElements(self.items, i, j)
end



return stMenu
