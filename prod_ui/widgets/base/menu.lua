--[[
A base menu widget. Requires some additional setup to be useful.


* General Menu Widget Notes *

Viewport 2 is the visible window into the content. It excludes scroll bars and opaque borders.
Viewport 1 is the scrolling viewport. It excludes scroll bars, opaque borders, and margin space.
doc_w|h is the range containing menu items, and the range that Viewport 1 is allowed to scan over.


	       Viewport 2
	           ║
	╔══════════╩═════════╗
	║                    ║

	┌────────────────────┬─┐
	│                    │^│
	│ :::::::::::::::::: ├─┤  ══╗
	│ :                : │ │    ║
	│ :                : │ │    ╠══ Viewport 1 (overlapping document area)
	│ :                : │ │    ║
	│ :                : │ │    ║
	│ :................: ├─┤  ══╝
	│ '                ' │v│
	├─┬────────────────┬─┼─┤
	│<│                │>│ │
	└─┴────────────────┴─┴─┘
	  '                '
	  '                '
	  '                '
	  ''''''''''''''''''

	  ║                ║
	  ╚═══════╦════════╝
	          ║
	       doc_w|h
--]]


local context = select(1, ...)


local commonScroll = require(context.conf.prod_ui_req .. "common.common_scroll")
local itemOps = require(context.conf.prod_ui_req .. "common.item_ops")
local lgcMenu = context:getLua("shared/lgc_menu")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "menu1"
}


lgcMenu.attachMenuMethods(def)
widShared.scrollSetMethods(def)
def.setScrollBars = commonScroll.setScrollBars
def.impl_scroll_bar = context:getLua("shared/impl_scroll_bar1")


--- Override this to control how menu items are arranged.
--function def:arrangeItems(first, last)
def.arrangeItems = lgcMenu.arrangeItemsVerticalTB
--def.arrangeItems = lgcMenu.arrangeItemsVerticalLRTB
--def.arrangeItems = lgcMenu.arrangeItemsHorizontalLR
--def.arrangeItems = lgcMenu.arrangeItemsHorizontalTBLR



--- The default item render loop for menus. In some cases, users may want to override this with
--  functions that are more efficient.
-- @param items The menu items array.
-- @param first The first item index to render.
-- @param last The last item index to render.
-- @param os_x Widget X offset in screen space, to help with scissor-boxes.
-- @param os_y Widget Y offset in screen space, to help with scissor-boxes.
-- @return Nothing.
function def:renderItems(items, first, last, os_x, os_y)
	for i = first, last do
		items[i]:render(self, os_x, os_y)
	end
end


function def:uiCall_thimbleAction(inst, key, scancode, isrepeat)
	if self == inst then
		-- ...
	end
end


-- TODO: uiCall_thimbleAction2()


-- * Internal *


-- * / Internal *


-- * Scroll helpers *


def.getInBounds = lgcMenu.getItemInBoundsRect
def.selectionInView = lgcMenu.selectionInView


-- * / Scroll helpers *


-- * Spatial selection *


def.getItemAtPoint = lgcMenu.widgetGetItemAtPointV -- (self, px, py, first, last)
def.trySelectItemAtPoint = lgcMenu.widgetTrySelectItemAtPoint -- (self, x, y, first, last)


-- * / Spatial selection *


-- * Selection movement *


def.movePrev = lgcMenu.widgetMovePrev
def.moveNext = lgcMenu.widgetMoveNext
def.moveFirst = lgcMenu.widgetMoveFirst
def.moveLast = lgcMenu.widgetMoveLast


-- * / Selection movement *


-- * Item management *


--[[
	These 'add' and 'remove' methods are pretty basic. You may have to wrap them in functions that
	are more aware of the kind of menu in use.

	You also need to call self:menuChangeCleanup() when you are done adding or removing. (When handling
	many items at once, it doesn't make sense to call it over and over.)
--]]


--- Adds an item instance to the menu.
-- @param item_instance The item instance (not the def!) to add.
-- @param index (default: #items + 1) Where to add the item in the list.
-- @return Nothing.
function def:addItem(item_instance, index)
	local items = self.items
	index = index or #items + 1

	table.insert(items, index, item_instance)

	item_instance:reshape()

	-- Call self:menuChangeCleanup() when you are done.
end


--- Removes an item from the menu at the specified index.
-- @param index (default: #items) Index of the item to remove. Must point to a valid table.
-- @return The removed item instance.
function def:removeItem(index)
	local items = self.items
	index = index or #items

	-- Catch attempts to remove invalid item indexes (Lua's table.remove() is okay with empty indexes 0 and 1)
	if not items[index] then
		error("Menu has no item at index: " .. tostring(index))
	end

	local removed = table.remove(self.items, index)

	return removed

	-- Call self:menuChangeCleanup() when you are done.
	-- No cleanup callback is run on the removed item, so any manual resource freeing needs to be handled by the caller.
end


--- Removes an item from the menu, using the item table reference instead of the index.
-- @param item The item table in the menu.
-- @return The removed item. Raises an error if the item is not found in the menu.
function def:removeItemTable(item) -- XXX untested
	local index
	for i, check in ipairs(self.items) do
		if check == item then
			index = i
			break
		end
	end

	if not index then
		error("couldn't find item table in menu.")
	else
		return self:removeItem(index)
	end

	-- Call self:menuChangeCleanup() when you are done.
end


function def:menuChangeCleanup()
	self:menuSetSelectionStep(0, false)
	if self.arrangeItems then
		self:arrangeItems()
	end
	self:scrollClampViewport()
	self:selectionInView()

	self:cacheUpdate(false)
end


-- * / Item management *


function def:uiCall_initialize()
	self.visible = true

	self.allow_hover = true
	self.can_have_thimble = true
	--self.allow_focus_capture = true

	widShared.setupDoc(self)
	widShared.setupScroll(self, -1, -1)
	widShared.setupViewports(self, 2)

	self.press_busy = false

	lgcMenu.setup(self)

	self.MN_auto_range = "v"

	-- When true, reshapes and arranges menu-items when this widget is reshaped.
	-- When "conditional", only do so if the widget dimensions have changed.
	self.auto_reshape_items = false

	-- Used with 'auto_reshape_items == "conditional"'
	--self.auto_reshape_w = 0
	--self.auto_reshape_h = 0

	self:skinSetRefs()
	self:skinInstall()
end


function def:uiCall_reshapePre()
	local skin = self.skin

	widShared.resetViewport(self, 1)

	-- Border and scroll bars
	widShared.carveViewport(self, 1, skin.box.border)
	commonScroll.arrangeScrollBars(self)

	-- 'Okay-to-click' rectangle.
	widShared.copyViewport(self, 1, 2)

	-- Margin.
	widShared.carveViewport(self, 1, skin.box.margin)

	-- Optional: reshape all menu items
	if self.auto_reshape_items == true
	or self.auto_reshape_items == "conditional" and (self.auto_reshape_w ~= self.w or self.auto_reshape_h ~= self.h)
	then
		for i, item in ipairs(self.items) do
			if item.reshape then
				item:reshape()
			end
		end

		if self.arrangeItems then
			self:arrangeItems()
		end

		self:cacheUpdate(true)
	end

	if self.auto_reshape_items == "conditional" then
		self.auto_reshape_w = self.w
		self.auto_reshape_h = self.h
	end

	self:scrollClampViewport()
	commonScroll.updateScrollState(self)

	return true
end


--- Updates cached display state.
-- @param refresh_dimensions When true, update doc_w and doc_h based on the combined dimensions of all items.
-- @return Nothing.
function def:cacheUpdate(refresh_dimensions)
	if refresh_dimensions then
		self.doc_w, self.doc_h = lgcMenu.getCombinedItemDimensions(self.items)
	end

	-- Option: automatically set the draw ranges for items.
	local auto_range = self.MN_auto_range -- XXX untested
	if auto_range == "h" then
		lgcMenu.widgetAutoRangeH(self)

	elseif auto_range == "v" then
		lgcMenu.widgetAutoRangeV(self)
	end
end


--- User-defined key-press handler for the widget.
--function def:wid_keyPressed(key, scancode, isrepeat)

--- The default navigational key input.
def.wid_defaultKeyNav = lgcMenu.keyNavTB


function def:uiCall_keyPressed(inst, key, scancode, isrepeat)
	if self == inst then
		-- The selected menu item gets a chance to handle keyboard input before the menu widget.

		local sel_item = self.items[self.index]
		if sel_item and sel_item.menuCall_keyPressed and sel_item:menuCall_keyPressed(self, key, scancode, isrepeat) then
			return true

		elseif self.wid_keyPressed and self:wid_keyPressed(key, scancode, isrepeat) then
			return true

		-- Run the default navigation checks.
		elseif self.wid_defaultKeyNav and self:wid_defaultKeyNav(key, scancode, isrepeat) then
			return true
		end
	end
end


function def:uiCall_pointerDrag(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		-- Implement Drag-to-select and menuCall_pointerDrag.
		if self.press_busy == "menu-drag" then
			-- Need to test the full range of items because the mouse can drag outside the bounds of the viewport.

			-- Mouse position relative to viewport #1
			local mx = mouse_x - self.vp_x
			local my = mouse_y - self.vp_y

			-- And with scroll offsets
			local s_mx = mx + self.scr_x
			local s_my = my + self.scr_y

			local ax, ay = self:getAbsolutePosition()

			local item_i, item_t = self:getItemAtPoint(s_mx - ax, s_my - ay, 1, #self.items)
			if item_i and item_t.selectable then
				self:menuSetSelectedIndex(item_i)
				-- Turn off item_hover so that other items don't glow.
				self.MN_item_hover = false

				--self:selectionInView()

				if item_t.menuCall_pointerDrag then
					item_t:menuCall_pointerDrag(self, self.context.mouse_pressed_button)
				end

			elseif self.MN_drag_select == "auto-off" then
				self:menuSetSelectedIndex(0)
			end
		end
	end
end


function def:uiCall_pointerHover(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		local ax, ay = self:getAbsolutePosition()
		mouse_x = mouse_x - ax
		mouse_y = mouse_y - ay

		commonScroll.widgetProcessHover(self, mouse_x, mouse_y)

		local xx = mouse_x + self.scr_x - self.vp_x
		local yy = mouse_y + self.scr_y - self.vp_y

		local hover_ok = false

		-- Inside of viewport #2
		if mouse_x >= self.vp2_x
		and mouse_x < self.vp2_x + self.vp2_w
		and mouse_y >= self.vp2_y
		and mouse_y < self.vp2_y + self.vp2_h
		then
			-- Update item hover
			local i, item = self:getItemAtPoint(xx, yy, math.max(1, self.MN_items_first), math.min(#self.items, self.MN_items_last))

			if item and item.selectable then
				-- Un-hover any existing hovered item
				if self.MN_item_hover ~= item then
					if self.MN_item_hover and self.MN_item_hover.menuCall_hoverOff then
						self.MN_item_hover:menuCall_hoverOff(self, mouse_x, mouse_y)
					end

					self.MN_item_hover = item

					if item.menuCall_hoverOn then
						item:menuCall_hoverOn(self, mouse_x, mouse_y)
					end
				end

				if item.menuCall_hoverMove then
					item:menuCall_hoverMove(self, mouse_x, mouse_y, mouse_dx, mouse_dy)
				end

				-- Implement mouse hover-to-select.
				if self.MN_hover_to_select and (mouse_dx ~= 0 or mouse_dy ~= 0) then
					local selected_item = self.items[self.index]
					if item ~= selected_item then
						self:menuSetSelectedIndex(i)
					end
				end

				hover_ok = true
			end
		end

		if self.MN_item_hover and not hover_ok then
			if self.MN_item_hover.menuCall_hoverOff then
				self.MN_item_hover:menuCall_hoverOff(self, mouse_x, mouse_y)
			end
			self.MN_item_hover = false

			if self.MN_hover_to_select == "auto-off" then
				self:menuSetSelectedIndex(0)
			end
		end
	end
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		commonScroll.widgetClearHover(self)

		if self.MN_item_hover and self.MN_item_hover.menuCall_hoverOff then
			local ax, ay = self:getAbsolutePosition()
			self.MN_item_hover:menuCall_hoverOff(self, mouse_x - ax, mouse_y - ay)
		end

		self.MN_item_hover = false

		if self.MN_hover_to_select == "auto-off" then
			self:menuSetSelectedIndex(0)
		end
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self == inst then
		if button == self.context.mouse_pressed_button then
			if button <= 3 then
				self:tryTakeThimble1()
			end

			local handled_scroll_bars = false

			-- Check for pressing on scroll bar components.
			if button == 1 then
				local fixed_step = 24 -- XXX style/config

				handled_scroll_bars = commonScroll.widgetScrollPress(self, x, y, fixed_step)
			end

			if not handled_scroll_bars then
				local ax, ay = self:getAbsolutePosition()
				local mouse_x = x - ax
				local mouse_y = y - ay

				-- Check if pointer was inside of viewport #2
				local in_port_2 = (mouse_x >= self.vp2_x
					and mouse_x < self.vp2_x + self.vp2_w
					and mouse_y >= self.vp2_y
					and mouse_y < self.vp2_y + self.vp2_h)

				if not in_port_2 then
					-- Successful mouse interaction with scroll bars should break any existing click-sequence.
					self.context:forceClickSequence(false, button, 1)
				else

					x = x - ax + self.scr_x - self.vp_x
					y = y - ay + self.scr_y - self.vp_y

					-- Check for click-able items.
					if not self.press_busy then
						local item_i, item_t = self:trySelectItemAtPoint(x, y, math.max(1, self.MN_items_first), math.min(#self.items, self.MN_items_last))

						if self.MN_drag_select then
							self.press_busy = "menu-drag"
						end

						-- Reset click-sequence if clicking on a different item.
						if self.MN_mouse_clicked_item ~= item_t then
							self.context:forceClickSequence(self, button, 1)
						end

						self.MN_mouse_clicked_item = item_t

						if item_t and item_t.menuCall_pointerPress then
							item_t.menuCall_pointerPress(item_t, self, button, self.context.cseq_presses)
						end
					end
				end
			end
		end
	end
end


function def:uiCall_pointerPressRepeat(inst, x, y, button, istouch, reps)
	if self == inst then
		-- Repeat-press events for items
		if self.MN_mouse_clicked_item and self.MN_mouse_clicked_item.menuCall_pointerPressRepeat then
			local ax, ay = self:getAbsolutePosition()
			local mouse_x = x - ax
			local mouse_y = y - ay

			local context = self.context
			self.MN_mouse_clicked_item:menuCall_pointerPressRepeat(self, button, context.cseq_presses, context.mouse_pressed_rep_n)
		else
			-- Repeat-press events for scroll bar buttons
			lgcMenu.pointerPressRepeatLogic(self, x, y, button, istouch, reps)
		end
	end
end


function def:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)
	if self == inst then
		if button == self.context.mouse_pressed_button then
			commonScroll.widgetClearPress(self)

			self.press_busy = false

			-- If mouse is over the selected item and it has a pointerRelease callback, run it.
			local item_selected = self.items[self.index]
			if item_selected and item_selected.selectable then
				local ax, ay = self:getAbsolutePosition()
				local mouse_x = x - ax
				local mouse_y = y - ay

				-- XXX safety precaution: ensure mouse position is within widget viewport #2?
				if mouse_x >= item_selected.x and mouse_x < item_selected.x + item_selected.w
				and mouse_y >= item_selected.y and mouse_y < item_selected.y + item_selected.h
				then
					if item_selected.menuCall_pointerRelease then
						item_selected:menuCall_pointerRelease(self, button)
					end
				end
			end
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

		-- XXX menuCall_pointerWheel() callback for items.

		if widShared.checkScrollWheelScroll(self, x, y) then
			self:cacheUpdate(false)
			return true
		end
	end
end


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

	elseif commonScroll.press_busy_codes[self.press_busy] then
		if self.context.mouse_pressed_ticks > 1 then
			local mx, my = self.context.mouse_x, self.context.mouse_y
			local ax, ay = self:getAbsolutePosition()
			local button_step = 350 -- XXX style/config
			commonScroll.widgetDragLogic(self, mx - ax, my - ay, button_step*dt)
		end
	end

	self:scrollUpdate(dt)

	-- Force a cache update if the external scroll position is different.
	if scr_x_old ~= self.scr_x or scr_y_old ~= self.scr_y then
		needs_update = true
	end

	-- Update scroll bar registers and thumb position
	local scr_h = self.scr_h
	if scr_h then
		commonScroll.updateRegisters(scr_h, math.floor(0.5 + self.scr_x), self.vp_w, self.doc_w)

		self.scr_h:updateThumb()
	end

	local scr_v = self.scr_v
	if scr_v then
		commonScroll.updateRegisters(scr_v, math.floor(0.5 + self.scr_y), self.vp_h, self.doc_h)

		self.scr_v:updateThumb()
	end

	commonScroll.updateScrollBarShapes(self)

	-- Per-widget and per-selected-item update callbacks.
	if self.wid_update then
		self:wid_update(dt)
	end
	local selected = self.items[self.index]
	if selected and selected.menuCall_selectedUpdate then
		selected:menuCall_selectedUpdate(self, dt) -- XXX untested
	end

	if needs_update then
		self:cacheUpdate(false)
	end
end


--function def:uiCall_destroy(inst)


--function def:renderThimble(os_x, os_y)


local check, change = uiTheme.check, uiTheme.change


def.default_skinner = {
	validate = function(skin)
		check.box(skin, "box")

		check.colorTuple(skin, "color_background")
		check.colorTuple(skin, "color_outline")
		check.colorTuple(skin, "color_item_text")
		check.colorTuple(skin, "color_select_glow")
		check.colorTuple(skin, "color_hover_glow")

		check.scrollBarData(skin, "data_scroll")
		check.integer(skin, "outline_width", 0)
		check.loveType(skin, "font_item", "Font")
	end,


	transform = function(skin, scale)
		change.integerScaled(skin, "outline_width", scale)
	end,


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)
		-- Update the scroll bar style
		self:setScrollBars(self.scr_h, self.scr_v)
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	--refresh = function(self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		local skin = self.skin
		local items = self.items
		local font = skin.font_item

		-- Back panel body
		love.graphics.setColor(skin.color_background)
		love.graphics.rectangle("fill", 0, 0, self.w, self.h)

		-- Don't draw menu contents outside of the widget bounding box.
		love.graphics.push("all")

		-- Scroll offsets
		love.graphics.translate(-self.scr_x + self.vp_x, -self.scr_y + self.vp_y)
		uiGraphics.intersectScissor(ox + self.vp2_x, oy + self.vp2_y, self.vp2_w, self.vp2_h)

		-- Draw hover glow, if applicable
		local item_hover = self.MN_item_hover
		if item_hover then
			love.graphics.setColor(skin.color_hover_glow)
			love.graphics.rectangle("fill", item_hover.x, item_hover.y, item_hover.w, item_hover.h)
		end

		-- Draw selection glow, if applicable
		local sel_item = items[self.index]
		if sel_item then
			local is_active = self:hasAnyThimble()
			local col = is_active and skin.color_active_glow or skin.color_select_glow
			love.graphics.setColor(col)
			love.graphics.rectangle("fill", sel_item.x, sel_item.y, sel_item.w, sel_item.h)
		end

		-- Draw each menu item in range
		love.graphics.setColor(skin.color_item_text)
		love.graphics.setFont(font)

		--print("self.MN_items_first", self.MN_items_first, "self.MN_items_last", self.MN_items_last)

		self:renderItems(items, math.max(self.MN_items_first, 1), math.min(self.MN_items_last, #items), ox, oy)

		love.graphics.pop()

		-- Draw the embedded scroll bars, if present and active.

		--love.graphics.setScissor() -- XXX debug

		commonScroll.drawScrollBarsHV(self, skin.data_scroll)

		-- Outline for the back panel
		love.graphics.setColor(skin.color_outline)
		love.graphics.setLineWidth(skin.outline_width)
		love.graphics.rectangle("line", 0.5, 0.5, self.w - 1, self.h - 1)
	end,


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy) end,
}


return def
