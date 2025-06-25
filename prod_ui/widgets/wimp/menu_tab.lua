
--[[
	A tabular menu with resizable column labels.
	Special menu-items are required with matching column data.

	* Assumes that all menu-items are in sequential order, from top to bottom
	* Assumes that all column categories are left-to-right. (TODO: considerations for RTL)


	┌──────────┬──────────┬────────────┬─┐
	│Name    v │Size      │Date        │^│  -- Column header bar -- visibility optional
	├──────────┴──────────┴────────────┼─┤
	│Foo               100   2023-01-02│ │  -- Menu Items (one for each row)
	│Bar                11   2018-05-14│ │
	│Baz              2400   2001-03-22│ │
	│Bop                55   2014-01-01│ │
	│                                  │ │
	│                                  ├─┤
	│                                  │v│
	├─┬──────────────────────────────┬─┼─┤
	│<│                              │>│ │  -- Optional scroll bars
	└─┴──────────────────────────────┴─┴─┘


	Column Header-box detail:

	                     Indicates ascending/descending order
                                         │
                                         v

	┌───────────────────────────────────────────┐
	│ ╔══╡        ╥                             │
	│ ║           ║                     ────    │
	│ ╠═╡ ╔═╗ ╔═╗ ╠═╗ ╔═╗ ╔═╗           ╲  ╱    │
	│ ║   ║ ║ ║ ║ ║ ║ ║ ║ ║              ╲╱     │
	│ ╨   ╚═╝ ╚═╝ ╚═╝ ╚═╩ ╨                     │
	└───────────────────────────────────────────┘

	║                                        ║     ║
	╚════════════════╦═══════════════════════╩══╦══╝
	                 ║                          ║
	                 ║                          ║
	         Left-click to sort      Left-click + drag to resize
	   Left-click + drag to re-order

	Right-click on the header-bar to toggle the visibility of categories.

--]]


local context = select(1, ...)


local lgcMenu = context:getLua("shared/lgc_menu")
local lgcScroll = context:getLua("shared/lgc_scroll")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "menu_tab1",

	default_settings = {
		icon_set_id = false, -- lookup for 'resources.icons[icon_set_id]'
	}
}


lgcMenu.attachMenuMethods(def)
widShared.scrollSetMethods(def)
def.setScrollBars = lgcScroll.setScrollBars
def.impl_scroll_bar = context:getLua("shared/impl_scroll_bar1")


function def:addColumn(label, visible, cb_sort)
	local column = {}
	table.insert(self.columns, column)

	-- The column's ID number.
	-- Important: this ID is used to look up cell tables in rows. Columns can change order
	-- in `self.columns`, but the ID should remain static. If you remove columns (not just
	-- make them invisible, but actually delete the column table from the array), then you
	-- must also delete the associated cells from rows and fix the IDs of the remaining
	-- columns.
	column.id = #self.columns

	column.x = 0
	column.y = 0
	column.w = 128
	column.h = self.skin.bar_height

	column.visible = (visible ~= nil) and not not visible or false
	column.text = label or ""
	column.cb_sort = cb_sort or false

	return column
end


local _mt_item = {selectable=true}
_mt_item.__index = _mt_item


function def:addRow()
	local item = setmetatable({x=0, y=0, w=0, h=0}, _mt_item)

	-- Every row in the menu should have as many cells as there are columns (including invisible ones).
	item.cells = {}

	table.insert(self.MN_items, item)

	return item
end


--def.getInBounds = lgcMenu.getItemInBoundsRect
def.getInBounds = lgcMenu.getItemInBoundsY
def.selectionInView = lgcMenu.selectionInView


def.getItemAtPoint = lgcMenu.widgetGetItemAtPoint -- (<self>, px, py, first, last)
def.trySelectItemAtPoint = lgcMenu.widgetTrySelectItemAtPoint -- (<self>, x, y, first, last)


def.movePrev = lgcMenu.widgetMovePrev
def.moveNext = lgcMenu.widgetMoveNext
def.moveFirst = lgcMenu.widgetMoveFirst
def.moveLast = lgcMenu.widgetMoveLast
def.movePageUp = lgcMenu.widgetMovePageUp
def.movePageDown = lgcMenu.widgetMovePageDown


-- * Pop-up menu setup (for columns) *


-- Needs to be rewritten for every call
local cat_pop_up_def = {}


local function callback_toggleCategoryVisibility(self, item)
	local column = self.columns[item.column_index]
	if column then
		column.visible = not column.visible
	end

	self:refreshColumnBar()
	self:cacheUpdate(true)
end


local function setupCategoryPopUp(self)
	for i = #cat_pop_up_def, 1, -1 do
		cat_pop_up_def[i] = nil
	end

	for i, column in ipairs(self.columns) do
		local tbl = {}

		tbl.type = "command"
		tbl.bijou = column.visible and "check_on" or "check_off"
		tbl.text = column.text ~= "" and column.text or "(Column #" .. i .. ")"

		tbl.callback = callback_toggleCategoryVisibility
		tbl.selectable = true
		tbl.actionable = not column.lock_visibility
		tbl.column_index = i

		table.insert(cat_pop_up_def, tbl)
	end
end


local function invokePopUpMenu(self, x, y)
	setupCategoryPopUp(self)

	local root = self:getRootWidget()

	local lgcWimp = self.context:getLua("shared/lgc_wimp")
	local pop_up = lgcWimp.makePopUpMenu(self, cat_pop_up_def, x, y)
	root:sendEvent("rootCall_doctorCurrentPressed", self, pop_up, "menu-drag")

	pop_up:tryTakeThimble2()
end


-- * / Pop-up menu setup (for columns) *


local function _findVisibleColumn(columns, first, last, delta)
	for i = first, last, delta do
		local column = columns[i]
		if column.visible then
			return i, column
		end
	end
end


-- Move a column within the array based on the column table and a destination index.
local function _moveColumn(self, col, dest_i)
	-- Locate column table in the array
	local columns = self.columns
	local src_i = false
	for i, check in ipairs(columns) do
		if check == col then
			src_i = i
			break
		end
	end

	if not src_i then
		error("couldn't locate column table in array.")
	end

	table.remove(columns, src_i)
	table.insert(columns, dest_i, col)
end


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 1

	widShared.setupDoc(self)
	widShared.setupScroll(self, -1, -1)
	widShared.setupViewports(self, 3)

	self.press_busy = false

	lgcMenu.setup(self)

	-- Array of header category columns.
	self.columns = {}

	-- Column bar visibility.

	-- Column bar rectangle. Column positions are not relative to these XY values, but they do define
	-- placement and are used in broad intersect tests.
	self.col_bar_visible = true

	-- Location of initial click when dragging column headers. Only valid between
	-- uiCall_pointerPress and uiCall_pointerUnpress.
	self.col_click = false
	self.col_click_x = 0
	self.col_click_y = 0

	-- Half square range of where row sorting is permitted by clicking on column squares.
	self.col_click_threshold = 16 -- XXX config, scale

	-- Reference(s) to the currently-hovered and currently-pressed column header.
	-- Hovered should only be considered if pressed is false.
	self.column_hovered = false
	self.column_pressed = false

	-- Reference to the column which is currently being used for sorting.
	-- Should be false when there are no columns or when no explicit sorting is being
	-- applied.
	self.column_primary = false

	-- Columns at indices less than or equal to this number cannot be reordered.
	-- We assume that affected columns never move: that their indices always equal
	-- their column.id fields (so ID #1 is at index 1, ID #2 is at index 2, and so
	-- on).
	self.reorder_limit = 0

	-- The sorting direction for the primary column. True == ascending (arrow down).
	self.column_sort_ascending = true

	self:skinSetRefs()
	self:skinInstall()
	self:applyAllSettings()
end


function def:uiCall_reshapePre()
	-- Viewport #1 is the scrollable tabular content (excluding the column header).
	-- Viewport #2 separates embedded controls (scroll bars) from the content.
	-- Viewport #3 is the column header.

	local skin = self.skin

	widShared.resetViewport(self, 1)

	-- Border and scroll bars.
	widShared.carveViewport(self, 1, skin.box.border)
	lgcScroll.arrangeScrollBars(self)

	-- 'Okay-to-click' rectangle.
	widShared.copyViewport(self, 1, 2)

	-- Margin.
	widShared.carveViewport(self, 1, skin.box.margin)

	if self.col_bar_visible then
		widShared.partitionViewport(self, 1, 3, skin.bar_height, "top")
	else
		widShared.resetViewport(self, 3)
	end

	self:scrollClampViewport()
	lgcScroll.updateScrollState(self)

	self:refreshColumnBar()
	self:cacheUpdate(true)

	return true
end


-- Updates the positions of column header boxes
function def:refreshColumnBar()
	local cx = 0
	local bar_height = self.skin.bar_height
	for i, column in ipairs(self.columns) do
		if column.visible then
			column.x = cx
			column.y = 0
			column.h = bar_height
			cx = cx + column.w
		end
	end

	self:refreshRows()
end


function def:refreshRows()
	local skin = self.skin

	local column_bar_x2 = self.vp_w

	local last_vis_column
	for i = #self.columns, 1, -1 do
		if self.columns[i].visible then
			last_vis_column = self.columns[i]
			break
		end
	end

	if last_vis_column then
		column_bar_x2 = last_vis_column.x + last_vis_column.w
	end

	local yy = 0
	for i, item in ipairs(self.MN_items) do
		item.x = 0
		item.y = yy
		item.w = column_bar_x2
		item.h = skin.item_h

		for j, cell in ipairs(item.cells) do
			if cell.reshape then
				cell:reshape(self)
			else
				error("no reshape callback?")
			end
		end

		yy = item.y + item.h
	end
end


--- Updates cached display state.
-- @param refresh_dimensions When true, update doc_w and doc_h based on the combined dimensions of all items.
-- @return Nothing.
function def:cacheUpdate(refresh_dimensions)
	if refresh_dimensions then
		self.doc_w, self.doc_h = 0, 0

		-- Document height is based on the last item in the menu.
		local last_item = self.MN_items[#self.MN_items]
		if last_item then
			self.doc_h = last_item.y + last_item.h
		end

		-- Document width is based on the rightmost column in the header.
		local last_col = self.columns[#self.columns]
		if last_col then
			self.doc_w = last_col.x + last_col.w
		end
	end

	-- Set the draw ranges for items.
	lgcMenu.widgetAutoRangeV(self)
end


function def:wid_defaultKeyNav(key, scancode, isrepeat)
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
		self:scrollDeltaH(-32) -- XXX config
		return true

	elseif scancode == "right" then
		self:scrollDeltaH(32) -- XXX config
		return true
	end
end


function def:uiCall_keyPressed(inst, key, scancode, isrepeat)
	if self == inst then
		-- The selected menu item gets a chance to handle keyboard input before the menu widget.

		if self.wid_keyPressed and self:wid_keyPressed(key, scancode, isrepeat) then
			return true

		-- Run the default navigation checks.
		elseif self.wid_defaultKeyNav and self:wid_defaultKeyNav(key, scancode, isrepeat) then
			return true
		end
		--[[
		-- Visibility pop-up menu
		-- XXX: Might interfere with other actions associated with the menu...
		elseif key == "application" then
			local x, y = self:getAbsolutePosition()
			invokePopUpMenu(self, x, y)
		end
		--]]
	end
end


function def:uiCall_pointerDrag(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		local mx, my = self:getRelativePosition(mouse_x, mouse_y)

		-- Activate the column re-ordering action when the mouse has moved far enough from
		-- the initial click point.
		if self.col_click then
			if mx < self.col_click_x - self.col_click_threshold
			or mx >= self.col_click_x + self.col_click_threshold
			or my < self.col_click_y - self.col_click_threshold
			or my >= self.col_click_y + self.col_click_threshold
			then
				self.col_click = false
			end
		end

		-- Move the to-be-reordered column.
		local column_box = self.column_pressed
		if column_box
		and column_box.id > self.reorder_limit
		and self.press_busy == "column-press"
		and not self.col_click
		then
			column_box.x = mx - math.floor(column_box.w/2)
		end

		-- Implement column resizing by dragging the edge.
		if column_box and self.press_busy == "column-edge" then
			local mx2 = mx - column_box.x + self.scr_x
			local my2 = my - column_box.y

			local column_min_w = 4 -- XXX config
			column_box.w = math.max(column_min_w, mx2)

			self:refreshColumnBar()
			self:cacheUpdate(true)

		-- Implement Drag-to-select
		elseif self.press_busy == "menu-drag" then
			-- Need to test the full range of items because the mouse can drag outside the bounds of the viewport.

			local smx, smy = mx + self.scr_x, my + self.scr_y
			local item_i, item_t = self:getItemAtPoint(smx, smy, 1, #self.MN_items)
			if item_i and item_t.selectable then
				self:menuSetSelectedIndex(item_i)
				-- Turn off item_hover so that other items don't glow.
				self.MN_item_hover = false

				--self:selectionInView()

			elseif self.MN_drag_select == "auto-off" then
				self:menuSetSelectedIndex(0)
			end
		end
	end
end


local function testColumnMouseOverlapWithEdges(self, mx, my)
	local drag_thresh = 4 -- XXX configurable edge threshold

	-- Broad check
	if widShared.pointInViewport(self, 3, mx, my) then
		-- Take horizontal scrolling into account only.
		local s2x = self.scr_x
		for i, column in ipairs(self.columns) do
			local col_x = self.vp3_x + column.x
			local col_y = self.vp3_y + column.y
			if column.visible and my >= col_y and my < col_y + column.h then

				-- Check the drag-edge first.
				if mx >= col_x + column.w - drag_thresh - s2x and mx < col_x + column.w + drag_thresh - s2x then
					return "column-edge", i, column

				elseif mx >= col_x - s2x and mx < col_x + column.w - s2x then
					return "column-press", i, column
				end
			end
		end
	end
end


-- Doesn't check the edges (for resizing).
local function testColumnMouseOverlap(self, mx, my)
	-- Assumes mx and my are relative to widget top-left.

	-- Broad check
	if widShared.pointInViewport(self, 3, mx, my) then
		-- Take horizontal scrolling into account only.
		local s2x = self.scr_x
		for i, column in ipairs(self.columns) do
			local col_x = self.vp3_x + column.x
			local col_y = self.vp3_y + column.y
			if column.visible and mx >= col_x - s2x and mx < col_x + column.w - s2x
			and my >= col_y and my < col_y + column.h
			then
				return "column-press", i, column
			end
		end
	end
end


function def:uiCall_pointerHover(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		local mx, my = self:getRelativePosition(mouse_x, mouse_y)
		lgcScroll.widgetProcessHover(self, mx, my)

		-- Test for hover over column header boxes
		local header_box_hovered = false
		local press_code, _, column = testColumnMouseOverlapWithEdges(self, mx, my)
		if press_code == "column-press" then
			self.column_hovered = column
			header_box_hovered = true
			self.cursor_hover = nil

		elseif press_code == "column-edge" then
			self.cursor_hover = "sizewe"

		else
			self.cursor_hover = nil
		end

		if not header_box_hovered then
			self.column_hovered = false
		end

		local smx, smy = mx + self.scr_x, my + self.scr_y

		local hover_ok = false

		if widShared.pointInViewport(self, 1, mx, my) then
			-- Update item hover
			--print("self.MN_items_first", self.MN_items_first, "self.MN_items_last", self.MN_items_last)
			local i, item = self:getItemAtPoint(smx, smy, math.max(1, self.MN_items_first), math.min(#self.MN_items, self.MN_items_last))
			print("i", i, "item", item)

			if item and item.selectable then
				self.MN_item_hover = item

				-- Implement mouse hover-to-select.
				if self.MN_hover_to_select and (mouse_dx ~= 0 or mouse_dy ~= 0) then
					local selected_item = self.MN_items[self.MN_index]
					if item ~= selected_item then
						self:menuSetSelectedIndex(i)
					end
				end

				hover_ok = true
			end
		end

		if self.MN_item_hover and not hover_ok then
			self.MN_item_hover = false

			if self.MN_hover_to_select == "auto-off" then
				self:menuSetSelectedIndex(0)
			end
		end
	end
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		lgcScroll.widgetClearHover(self)

		self.column_hovered = false
		self.cursor_hover = nil

		self.MN_item_hover = false

		if self.MN_hover_to_select == "auto-off" then
			self:menuSetSelectedIndex(0)
		end
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self == inst
	and button == self.context.mouse_pressed_button
	then
		if button <= 3 then
			self:tryTakeThimble1()
		end

		local mx, my = self:getRelativePosition(x, y)

		if lgcMenu.pointerPressScrollBars(self, x, y, button) then
			-- Successful mouse interaction with scroll bars should break any existing click-sequence.
			self.context:forceClickSequence(false, button, 1)

		-- Header bar
		elseif self.col_bar_visible and widShared.pointInViewport(self, 3, mx, my) then
			-- Main column interactions
			if button == 1 then
				local press_code, _, column = testColumnMouseOverlapWithEdges(self, mx, my)
				if press_code then
					self.column_hovered = false
					self.column_pressed = column

					self.press_busy = press_code

					-- Help prevent unwanted double-clicks on menu-items
					self.MN_mouse_clicked_item = false
				end
				if press_code == "column-press" then
					self.col_click = true
					self.col_click_x = mx
					self.col_click_y = my
				end

			elseif button == 2 then
				invokePopUpMenu(self, x, y)

				-- Halt propagation
				return true
			end

		-- Item content
		elseif widShared.pointInViewport(self, 1, mx, my) then
			if button == 1 then
				local smx, smy = mx + self.scr_x, my + self.scr_y

				if not self.press_busy then
					local item_i, item_t = self:trySelectItemAtPoint(
						smx,
						smy,
						math.max(1, self.MN_items_first),
						math.min(#self.MN_items, self.MN_items_last)
					)

					if self.MN_drag_select then
						self.press_busy = "menu-drag"
					end

					-- Reset click-sequence if clicking on a different item.
					if self.MN_mouse_clicked_item ~= item_t then
						self.context:forceClickSequence(self, button, 1)
					end

					self.MN_mouse_clicked_item = item_t
				end
			end
		end
	end
end


function def:uiCall_pointerPressRepeat(inst, x, y, button, istouch, reps)
	if self == inst then
		if not self.MN_mouse_clicked_item then
			-- Repeat-press events for scroll bar buttons
			lgcMenu.pointerPressRepeatLogic(self, x, y, button, istouch, reps)
		end
	end
end


function def:sort()
	local success = false
	local column = self.column_primary
	if column and column.cb_sort then
		success = column.cb_sort(self, column)
	end

	self:refreshRows()

	return success
end


function def:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)
	if self == inst then
		if button == self.context.mouse_pressed_button then
			lgcScroll.widgetClearPress(self)

			local old_press_busy = self.press_busy
			self.press_busy = false

			local mx, my = self:getRelativePosition(x, y)
			local smx, smy = mx + self.scr_x, my + self.scr_y

			local old_col_press = self.column_pressed
			self.column_pressed = false

			-- Clamp scrolling if click-releasing after resizing or moving column header boxes.
			-- It's less jarring to do this here rather than in the drag callback.
			if old_press_busy == "column-edge" then
				self:scrollClampViewport()
			end

			-- Check for click-releasing a column header-box.
			if old_col_press
			and self.col_click
			and self.col_bar_visible
			and old_press_busy == "column-press"
			and smx >= old_col_press.x and smx < old_col_press.x + old_col_press.w
			and my >= old_col_press.y and my < old_col_press.y + old_col_press.h
			then
				-- Handle release event
				if old_col_press == self.column_primary then
					self.column_sort_ascending = not self.column_sort_ascending

				else
					self.column_sort_ascending = true
				end

				self.column_primary = old_col_press

				-- Try to maintain the old selection
				local old_selected_item = self.MN_items[self.MN_index]

				self:sort()

				if not old_selected_item then
					self:menuSetSelectedIndex(0)
				else
					for i, item in ipairs(self.MN_items) do
						if item == old_selected_item then
							self:menuSetSelectedIndex(self:menuGetItemIndex(old_selected_item))
						end
					end
				end

				self:selectionInView(true)
			end

			if old_press_busy == "column-press"
			and old_col_press
			and old_col_press.id > self.reorder_limit
			and not self.col_click
			then
				local columns = self.columns

				if #columns > 1 then
					local i_start = math.max(1, self.reorder_limit + 1)
					--print("i_start", i_start)
					local i1, col_first = _findVisibleColumn(columns, i_start, #columns, 1)
					local i2, col_last = _findVisibleColumn(columns, #columns, i_start, -1)

					if col_first and col_first ~= old_col_press and mx < col_first.x + col_first.w then
						_moveColumn(self, old_col_press, i1)

					elseif col_last and col_last ~= old_col_press and mx >= col_last.x then
						_moveColumn(self, old_col_press, i2)

					elseif i1 and i2 then
						for i = i1 + 1, i2 - 1 do
							local other = self.columns[i]
							if other.visible
							and other ~= old_col_press
							and mx >= other.x and mx < other.x + other.w
							then
								_moveColumn(self, old_col_press, i)
								break
							end
						end
					end
				end
				self:refreshColumnBar()
				self:cacheUpdate(true)
			end

			self.col_click = false
		end
	end
end


function def:uiCall_pointerWheel(inst, x, y)
	if self == inst then
		-- (Positive Y == rolling wheel upward.)
		-- Only scroll if we are not at the edge of the scrollable area. Otherwise, the wheel
		-- event should bubble up.

		-- XXX support mapping single-dimensional wheel to horizontal scroll motion
		-- XXX support horizontal wheels

		if widShared.checkScrollWheelScroll(self, x, y) then
			self:cacheUpdate(false)
			return true
		end
	end
end


function def:uiCall_thimbleAction(inst, key, scancode, isrepeat)
	if self == inst then
		-- ...
	end
end


-- TODO: uiCall_thimbleAction2()


function def:uiCall_update(dt)
	dt = math.min(dt, 1.0)

	local scr_x_old, scr_y_old = self.scr_x, self.scr_y

	local needs_update = false

	-- Clear click-sequence item
	if self.MN_mouse_clicked_item and self.context.cseq_widget ~= self then
		self.MN_mouse_clicked_item = false
	end

	-- Handle update-time drag-scroll.
	if self.press_busy == "menu-drag" and widShared.dragToScroll(self, dt) then
		needs_update = true

	elseif lgcScroll.press_busy_codes[self.press_busy] then
		if self.context.mouse_pressed_ticks > 1 then
			local mx, my = self.context.mouse_x, self.context.mouse_y
			local ax, ay = self:getAbsolutePosition()
			local button_step = 350 -- XXX style/config
			lgcScroll.widgetDragLogic(self, mx - ax, my - ay, button_step*dt)
		end
	end

	self:scrollUpdate(dt)

	-- Force a cache update if the external scroll position is different.
	if scr_x_old ~= self.scr_x or scr_y_old ~= self.scr_y then
		needs_update = true
	end

	-- Update scroll bar registers and thumb position
	lgcScroll.updateScrollBarShapes(self)
	lgcScroll.updateScrollState(self)

	-- Per-widget and per-selected-item update callbacks.
	if self.wid_update then
		self:wid_update(dt)
	end

	if needs_update then
		self:cacheUpdate(false)
	end
end


--function def:uiCall_destroy(inst)


local function drawWholeColumn(self, column, backfill, ox, oy)
	local skin = self.skin
	local tq_px = skin.tq_px
	local font = skin.font

	local state = (self.column_pressed == column) and "press"
		or (self.column_hovered == column) and "hover"
		or "idle"

	local bijou_id = false
	if self.column_primary == column then
		bijou_id = self.column_sort_ascending and "ascending" or "descending"
	end

	local res = state == "idle" and skin.res_column_idle
		or state == "hover" and skin.res_column_hover
		or state == "press" and skin.res_column_press

	love.graphics.push("all")

	uiGraphics.intersectScissor(
		ox + column.x - self.scr_x,
		oy + self.vp3_y + column.y,
		column.w,
		column.h
	)
	love.graphics.translate(column.x - self.scr_x, self.vp3_y + column.y)

	-- Header box body.
	love.graphics.setColor(res.color_body)
	uiGraphics.drawSlice(res.sl_body, 0, 0, column.w, column.h)

	-- Header box text.
	local text_x = skin.category_h_pad
	local text_y = math.floor(column.h / 2 - font:getHeight() / 2)

	love.graphics.setColor(res.color_text)
	love.graphics.setFont(font)
	love.graphics.print(
		column.text,
		text_x + res.offset_x,
		text_y + res.offset_y
	)

	-- Header box bijou.
	if bijou_id then
		local text_w = font:getWidth(column.text)
		local bx = 0 + math.max(text_w + skin.category_h_pad*2, column.w - skin.bijou_w - skin.category_h_pad)
		local by = math.floor(0.5 + column.h / 2 - skin.bijou_h / 2)

		local bijou_quad = (bijou_id == "ascending") and skin.tq_arrow_up or skin.tq_arrow_down
		uiGraphics.quadXYWH(
			bijou_quad,
			bx + res.offset_x,
			by + res.offset_y,
			skin.bijou_w,
			skin.bijou_h
		)
	end

	love.graphics.pop()

	love.graphics.push("all")

	uiGraphics.intersectScissor(
		ox + column.x - self.scr_x,
		oy + self.vp_y,
		column.w,
		self.vp_h
	)
	love.graphics.translate(column.x - self.scr_x, -self.scr_y)

	-- Optional backfill. Used to indicate a dragged column.
	if backfill then
		love.graphics.setColor(skin.color_drag_col_bg)
		uiGraphics.quadXYWH(tq_px, 0, 0, column.w, self.vp2_h)
	end

	-- Thin vertical separators between columns
	-- [XXX] This is kind of iffy. It might be better to draw a mosaic body for every column.
	love.graphics.setColor(skin.color_column_sep)
	uiGraphics.quadXYWH(tq_px, column.w - skin.column_sep_width, self.scr_y, skin.column_sep_width, self.h)

	-- Draw each menu item in range.
	love.graphics.setColor(skin.color_item_text)

	local items = self.MN_items

	local first = math.max(self.MN_items_first, 1)
	local last = math.min(self.MN_items_last, #items)

	for j = first, last do
		local item = items[j]
		local cell = item.cells[column.id]
		if cell then
			cell:render(item, column, self, ox, oy)
		end
	end

	love.graphics.pop()
end


local check, change = uiTheme.check, uiTheme.change


local function _checkRes(skin, k)
	uiTheme.pushLabel(k)

	local res = check.getRes(skin, k)
	check.slice(res, "sl_body")
	check.colorTuple(res, "color_body")
	check.colorTuple(res, "color_text")
	check.integer(res, "offset_x")
	check.integer(res, "offset_y")

	uiTheme.popLabel()
end


local function _changeRes(skin, k, scale)
	uiTheme.pushLabel(k)

	local res = check.getRes(skin, k)
	change.integerScaled(res, "offset_x", scale)
	change.integerScaled(res, "offset_y", scale)

	uiTheme.popLabel()
end


def.default_skinner = {
	validate = function(skin)
		-- settings
		check.type(skin, "icon_set_id", "nil", "string")
		-- /settings

		check.box(skin, "box")
		check.quad(skin, "tq_px")
		check.scrollBarData(skin, "data_scroll")
		check.scrollBarStyle(skin, "scr_style")
		check.loveType(skin, "font", "Font")

		check.colorTuple(skin, "color_header_body")
		check.colorTuple(skin, "color_background")
		check.colorTuple(skin, "color_item_text")
		check.colorTuple(skin, "color_select_glow")
		check.colorTuple(skin, "color_hover_glow")
		check.colorTuple(skin, "color_column_sep")
		check.colorTuple(skin, "color_drag_col_bg")

		check.integer(skin, "item_h", 0)
		check.integer(skin, "column_sep_width", 0)

		-- Some default data for cell implementations.
		check.colorTuple(skin, "color_cell_icon")
		check.colorTuple(skin, "color_cell_text")
		check.loveType(skin, "cell_font", "Font")

		check.integer(skin, "bar_height", 0)
		check.integer(skin, "col_sep_line_width", 0)
		check.integer(skin, "bijou_w", 0)
		check.integer(skin, "bijou_h", 0)

		check.quad(skin, "tq_arrow_up")
		check.quad(skin, "tq_arrow_down")

		-- Padding between:
		-- * Category panel left and label text
		-- * Category panel right and sorting badge
		check.integer(skin, "category_h_pad")

		_checkRes(skin, "res_column_idle")
		_checkRes(skin, "res_column_hover")
		_checkRes(skin, "res_column_press")
	end,


	transform = function(skin, scale)
		change.integerScaled(skin, "item_h", scale)
		change.integerScaled(skin, "column_sep_width", scale)
		change.integerScaled(skin, "bar_height", scale)
		change.integerScaled(skin, "col_sep_line_width", scale)
		change.integerScaled(skin, "bijou_w", scale)
		change.integerScaled(skin, "bijou_h", scale)
		change.integerScaled(skin, "category_h_pad", scale)

		_changeRes(skin, "res_column_idle", scale)
		_changeRes(skin, "res_column_hover", scale)
		_changeRes(skin, "res_column_press", scale)
	end,


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)
		-- Update the scroll bar style
		self:setScrollBars(self.scr_h, self.scr_v)

		self:refreshColumnBar()
		self:cacheUpdate(true)
		self:scrollClampViewport()
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	--refresh = function(self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		local skin = self.skin
		local font = skin.font
		local tq_px = skin.tq_px

		local items = self.MN_items

		uiGraphics.intersectScissor(ox + self.x, oy + self.y, self.w, self.h)

		love.graphics.push("all")

		-- Widget body fill.
		love.graphics.setColor(skin.color_background)
		uiGraphics.quadXYWH(tq_px, 0, 0, self.w, self.h)

		-- Column bar body (spanning the top of the widget).
		love.graphics.setColor(skin.color_header_body)
		uiGraphics.quadXYWH(tq_px, self.vp3_x, self.vp3_y, self.vp3_w, self.vp3_h)

		uiGraphics.intersectScissor(
			ox + self.x + self.vp2_x,
			oy + self.y + self.vp2_y,
			self.vp2_w,
			self.vp2_h
		)

		-- Draw columns.
		local col_pres = self.column_pressed

		for i, column in ipairs(self.columns) do
			if column.visible
			and col_pres ~= column
			and self.vp3_x + column.x - self.scr_x < self.vp2_x + self.vp2_w
			and self.vp3_x + column.x + column.w - self.scr_x >= self.vp2_x
			then
				drawWholeColumn(self, column, false, ox, oy)
			end
		end

		-- If there is a column that is currently being dragged, draw it last.
		if col_pres then
			drawWholeColumn(self, col_pres, true, ox, oy)
		end

		love.graphics.translate(-self.scr_x, -self.scr_y)

		uiGraphics.intersectScissor(ox + self.vp_x, oy + self.vp_y, self.vp_w, self.vp_h)

		-- Draw hover glow, if applicable
		local item_hover = self.MN_item_hover
		if item_hover then
			love.graphics.setColor(skin.color_hover_glow)
			uiGraphics.quadXYWH(tq_px, item_hover.x, item_hover.y, item_hover.w, item_hover.h)
		end

		-- Draw selection glow, if applicable
		local sel_item = items[self.MN_index]
		if sel_item then
			love.graphics.setColor(skin.color_select_glow)
			uiGraphics.quadXYWH(tq_px, sel_item.x, sel_item.y, sel_item.w, sel_item.h)
		end

		love.graphics.pop()

		lgcScroll.drawScrollBarsHV(self, self.skin.data_scroll)
	end,


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy) end,
}


return def
