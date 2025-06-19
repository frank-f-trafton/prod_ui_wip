-- XXX: Under construction.
--[[
A flat list of properties with embedded controls.

               Drag to resize columns
                         │
Optional icons (bijoux)  │
   │                     │
   │ Labels              │       Controls
   │   │                 │          │
   V   V                 V          V
┌───────────────────────────────────────────────┬─┐
│ [B] Foo                |                  [x] │^│
│:[B]:Bar::::::::::::::::│:[              0.02]:├─┤
│ [B] Baz                │ ["Twist"           ]:│ │
│ [B] Qux                │ [dir/ectory        ] │ │
│                        |                      ├─┤
│                        |                      │v│
└───────────────────────────────────────────────┴─┘
--]]


--[[
Stuff to fix:

* The function attached to 'self:arrangeItems()' doesn't use the viewport argument.
  Might need to write a custom one for this widget.

* 'items' should be its own array of tables with linked widgets. As it is, item
  selection is mixed into the control widget tables.

* Fix how icon resources are loaded.
--]]


local context = select(1, ...)


local lgcMenu = context:getLua("shared/lgc_menu")
local lgcScroll = context:getLua("shared/lgc_scroll")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "properties_box1"
}


lgcMenu.attachMenuMethods(def)
widShared.scrollSetMethods(def)
def.setScrollBars = lgcScroll.setScrollBars
def.impl_scroll_bar = context:getLua("shared/impl_scroll_bar1")

def.arrangeItems = lgcMenu.arrangeItemsVerticalTB


-- * Scroll helpers *


def.getInBounds = lgcMenu.getItemInBoundsY
def.selectionInView = lgcMenu.selectionInView


-- * Spatial selection *


def.getItemAtPoint = lgcMenu.widgetGetItemAtPointV -- (self, px, py, first, last)
def.trySelectItemAtPoint = lgcMenu.widgetTrySelectItemAtPoint -- (self, x, y, first, last)


-- * Selection movement *


def.movePrev = lgcMenu.widgetMovePrev
def.moveNext = lgcMenu.widgetMoveNext
def.moveFirst = lgcMenu.widgetMoveFirst
def.moveLast = lgcMenu.widgetMoveLast
def.movePageUp = lgcMenu.widgetMovePageUp
def.movePageDown = lgcMenu.widgetMovePageDown


--- Called when user double-clicks on the widget or presses "return" or "kpenter".
--	An active control widget may swallow the events that trigger this callback.
-- @param item The current selected item, or nil if no item is selected.
-- @param item_i Index of the current selected item, or zero if no item is selected.
function def:wid_action(item, item_i)

end


--- Called when the user right-clicks on the widget or presses "application" or shift+F10.
--	An active control widget may swallow the events that trigger this callback.
-- @param item The current selected item, or nil if no item is selected.
-- @param item_i Index of the current selected item, or zero if no item is selected.
function def:wid_action2(item, item_i)

end


--- Called when the user middle-clicks on the widget.
--	An active control widget may swallow the events that trigger this callback.
-- @param item The current selected item, or nil if no item is selected.
-- @param item_i Index of the current selected item, or zero if no item is selected.
function def:wid_action3(item, item_i)

end


-- Called when there is a change in the selected item.
-- @param item The current selected item, or nil if no item is selected.
-- @param item_i Index of the current selected item, or zero if no item is selected.
function def:wid_select(item, item_i)
	-- XXX This may not be firing when going from a selected item to nothing selected.
end


--- Called in uiCall_keyPressed() before the default keyboard navigation checks.
-- @param key The key code.
-- @param scancode The scancode.
-- @param isrepeat Whether this is a key-repeat event.
-- @return true to halt keynav and further bubbling of the keyPressed event.
function def:wid_keyPressed(key, scancode, isrepeat)

end


--- Called when the mouse drags and drops something onto this widget.
-- @param drop_state A DropState table that describes the nature of the drag-and-drop action.
-- @return true to clear the DropState and to stop event bubbling.
function def:wid_dropped(drop_state)

end


--- Called in uiCall_keyPressed(). Implements basic keyboard navigation.
-- @param key The key code.
-- @param scancode The scancode.
-- @param isrepeat Whether this is a key-repeat event.
-- @return true to halt keynav and further bubbling of the keyPressed event.
function def:wid_defaultKeyNav(key, scancode, isrepeat)
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
		self:scrollDeltaH(-32) -- XXX config
		return true

	elseif scancode == "right" then
		self:scrollDeltaH(32) -- XXX config
		return true
	end
end


local function updateItemDimensions(self, v, item)
	local skin = self.skin
	local vx, vy, vw, vh = widShared.getViewportXYWH(self, v)
	item.w = vw
	item.h = skin.item_h
end


function def:addControl(wid_id, text, pos, bijou_id)
	uiShared.type1(2, text, "string")
	uiShared.intEval(3, pos, "number")
	uiShared.typeEval1(4, bijou_id, "string")

	local wid = self:addChild(wid_id, pos)
	wid:initialize()

	wid.selectable = true
	wid.marked = false -- multi-select
	wid.x, wid.y = 0, 0
	updateItemDimensions(self, 4, wid)
	wid.text = text
	wid.bijou_id = bijou_id
	wid.tq_bijou = self.context.resources.quads["atlas"][bijou_id] -- TODO: fix this up

	self:arrangeItems(nil, pos, #self.children)

	print("addControl text:", wid.text, "xywh: ", wid.x, wid.y, wid.w, wid.h)

	return wid
end


function def:removeControl(wid)
	uiShared.type1(1, wid, "table")

	local wid_i = self:menuGetItemIndex(wid)

	self:removeControlByIndex(wid_i)
end


function def:removeControlByIndex(wid_i)
	uiShared.numberNotNaN(1, wid_i)

	local children = self.children
	local to_remove = children[wid_i]
	if not to_remove then
		error("no control to remove at index: " .. tostring(wid_i))
	end

	to_remove:remove()

	-- Removed control was the last in the list, and was selected:
	if self.index > #children then
		local landing_i = self:menuFindSelectableLanding(#children, -1)
		self:setSelectionByIndex(landing_i or 0)

	-- Removed control was not selected, and the selected control appears after the removed control in the list:
	elseif self.index > wid_i then
		self.index = self.index - 1
	end

	self:arrangeItems(nil, wid_i, #children)
end


function def:setSelection(wid)
	uiShared.type1(1, wid, "table")

	local wid_i = self:menuGetItemIndex(wid)
	self:setSelectionByIndex(wid_i)
end


function def:setSelectionByIndex(wid_i)
	uiShared.intGE(1, wid_i, 0)

	self:menuSetSelectedIndex(wid_i)
end


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true
	self.can_have_thimble = true

	widShared.setupDoc(self)
	widShared.setupScroll(self, -1, -1)
	widShared.setupViewports(self, 5)

	self.press_busy = false

	-- (self.items == self.children)
	lgcMenu.setup(self, self.children, true, true) -- with mark and drag+drop state
	self.MN_wrap_selection = false

	self.sash_enabled = true

	-- Column X positions and widths.
	self.col_icon_x = 0
	self.col_icon_w = 0

	self.col_text_x = 0
	self.col_text_w = 0

	-- State flags.
	self.enabled = true

	-- Shows a column of icons when true.
	self.show_icons = false

	self:skinSetRefs()
	self:skinInstall()
end


function def:uiCall_reshapePre()
	-- Viewport #1 is the main content viewport.
	-- Viewport #2 separates embedded controls (scroll bars) from the content.
	-- Viewport #3 is the area for item labels.
	-- Viewport #4 is the area for item controls (child widgets).
	-- Viewport #5 is a sash that is placed between the labels and controls.
	-- * The sash viewport overlaps and straddles #3 and #4.

	local skin = self.skin

	widShared.resetViewport(self, 1)

	-- Border and scroll bars.
	widShared.carveViewport(self, 1, skin.box.border)
	lgcScroll.arrangeScrollBars(self)

	-- 'Okay-to-click' rectangle.
	widShared.copyViewport(self, 1, 2)

	-- Margin.
	widShared.carveViewport(self, 1, skin.box.margin)

	-- Label and control areas.
	widShared.copyViewport(self, 1, 3)
	widShared.partitionViewport(self, 3, 4, self.vp3_w / 2, "right")

	-- Sash.
	self.vp5_w = skin.sash_w
	widShared.straddleViewport(self, 3, 5, "right", 0.5)

	self:scrollClampViewport()
	lgcScroll.updateScrollState(self)

	-- Resize and reposition controls.
	local yy = self.vp_y
	for i, wid in ipairs(self.items) do
		wid.x = self.vp4_x - self.vp_x
		wid.y = yy
		updateItemDimensions(self, 4, wid)
		yy = yy + wid.h
	end
	--self:arrangeItems()

	self:cacheUpdate(true)
end


--- Updates cached display state.
-- @param refresh_dimensions When true, update doc_w and doc_h based on the combined dimensions of all controls.
-- @return Nothing.
function def:cacheUpdate(refresh_dimensions)
	local skin = self.skin

	if refresh_dimensions then
		self.doc_w, self.doc_h = 0, 0

		local children = self.items

		-- Document height is based on the last control in the menu.
		local last_wid = children[#children]
		if last_wid then
			self.doc_h = last_wid.y + last_wid.h
		end

		-- Calculate column widths.
		if self.show_icons then
			self.col_icon_w = skin.icon_spacing
		else
			self.col_icon_w = 0
		end

		self.col_text_w = 0
		local font = skin.font
		for i, wid in ipairs(children) do
			self.col_text_w = math.max(self.col_text_w, wid.x + wid.w)
		end

		-- Additional text padding.
		self.col_text_w = self.col_text_w + skin.pad_text_x
		self.col_text_w = math.max(self.col_text_w, self.vp3_w - self.col_icon_w)

		-- Get column left positions.
		if skin.icon_side == "left" then
			self.col_icon_x = 0
			self.col_text_x = self.col_icon_w
		else
			self.col_icon_x = self.col_text_w
			self.col_text_x = 0
		end

		self.doc_w = math.max(self.vp_w, self.col_icon_w + self.col_text_w)
	end

	-- Set the draw ranges for controls.
	lgcMenu.widgetAutoRangeV(self)
end


local function updateSelectedControl(self, control)
	local old_item = self.items[self.index]

	self:menuClearAllMarkedItems()
	self:menuSetSelectedItem(control)

	if old_item ~= control then
		self:wid_select(control, self:menuGetItemIndex(control))
	end
end


function def:uiCall_keyPressed(inst, key, scancode, isrepeat)
	local items = self.items
	local old_index = self.index
	local old_item = items[old_index]

	-- wid_action() is handled in the 'thimbleAction()' callback.

	-- Escape: take thimble1 from embedded child widget
	if self ~= inst and inst == self.context.thimble1 and key == "escape" then
		self:tryTakeThimble1()
		return true

	elseif self == inst then
		-- NOTE: This code path for 'toggle' MN_mark_mode won't work if the widget can
		-- take thimble1 (see thimbleAction()).
		if self.MN_mark_mode == "toggle" and key == "space" then
			if old_index > 0 and self:menuCanSelect(old_index) then
				self:menuToggleMarkedItem(items[old_index])
				return true
			end

		elseif self:wid_keyPressed(key, scancode, isrepeat)
		or self:wid_defaultKeyNav(key, scancode, isrepeat)
		then
			local control = items[self.index]
			if old_item ~= control then
				if self.MN_mark_mode == "cursor" then
					local mods = self.context.key_mgr.mod
					if mods["shift"] then
						self:menuClearAllMarkedItems()
						lgcMenu.markItemsCursorMode(self, old_index)
					else
						self.MN_mark_index = false
						self:menuClearAllMarkedItems()
						self:menuSetMarkedItemByIndex(self.index, true)
					end
				end

				self:wid_select(control, self.index)
			end
			return true
		end
	end
end


function def:uiCall_keyReleased(inst, keycode, scancode)
	if self == inst then
		-- If there is a selected child widget, forward keyboard events to it first.
		local control = self.items[self.index]
		if control and control:sendEvent("uiCall_keyReleased", control, keycode, scancode) then
			return true
		end
	end
end


function def:uiCall_textInput(inst, text)
	if self == inst then
		-- If there is a selected child widget, forward keyboard events to it first.
		local control = self.items[self.index]
		if control and control:sendEvent("uiCall_textInput", control, text) then
			return true
		end
	end
end


function def:uiCall_pointerHover(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		local mx, my = self:getRelativePosition(mouse_x, mouse_y)

		lgcScroll.widgetProcessHover(self, mx, my)

		local hover_ok = false

		-- Hovering over an active sash
		if self.sash_enabled and widShared.pointInViewport(self, 5, mx, my) then
			self.cursor_hover = self.skin.cursor_sash

		-- Hovering over labels and controls
		elseif widShared.pointInViewport(self, 2, mx, my) then
			self.cursor_hover = nil

			mx = mx + self.scr_x
			my = my + self.scr_y

			-- Update item hover
			local i, item = self:getItemAtPoint(mx, my, math.max(1, self.MN_items_first), math.min(#self.items, self.MN_items_last))

			if item and item.selectable then
				-- Un-hover any existing hovered item
				self.MN_item_hover = item

				hover_ok = true
			end

		else
			-- Clear the sash cursor
			self.cursor_hover = nil
		end

		if self.MN_item_hover and not hover_ok then
			self.MN_item_hover = false
		end
	end
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		lgcScroll.widgetClearHover(self)
		self.cursor_hover = nil
		self.MN_item_hover = false
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self.enabled
	and button == self.context.mouse_pressed_button
	then
		if button <= 3 then
			-- The user clicked on a child widget
			if self ~= inst then
				updateSelectedControl(self, inst)
			end
		end

		-- The user clicked somewhere on the menu, outside of child widgets (or "through"
		-- an inactive child widget)
		if self == inst then
			if button <= 3 then
				self:tryTakeThimble1()
			end
			if not lgcMenu.pointerPressScrollBars(self, x, y, button) then
				local mx, my = self:getRelativePosition(x, y)

				if widShared.pointInViewport(self, 2, mx, my) then
					mx, my = mx + self.scr_x, my + self.scr_y

					local item_i, item_t = lgcMenu.checkItemIntersect(self, mx, my, button)

					if item_t and item_t.selectable then
						local old_index = self.index
						local old_item = self.items[old_index]

						-- Buttons 1, 2 and 3 all select an item.
						-- Only button 1 updates the item mark state.
						if button <= 3 then
							lgcMenu.widgetSelectItemByIndex(self, item_i)
							self.MN_mouse_clicked_item = item_t

							if button == 1 then
								lgcMenu.pointerPressButton1(self, item_t, old_index)
							end

							if old_item ~= item_t then
								self:wid_select(item_t, item_i)
							end
						end

						-- All Button 1 clicks initiate click-drag.
						if button == 1 then

							self.press_busy = "menu-drag"

							-- Double-clicking Button 1 invokes action 1.
							if self.context.cseq_button == 1
							and self.context.cseq_widget == self
							and self.context.cseq_presses % 2 == 0
							then
								self:wid_action(item_t, item_i)
							end

						-- Button 2 clicks invoke action 2.
						elseif button == 2 then
							self:wid_action2(item_t, item_i)

						-- Button 3 -> action 3...
						elseif button == 3 then
							self:wid_action3(item_t, item_i)
						end
					end
				end
			end
		end
	end
end


function def:uiCall_pointerPressRepeat(inst, x, y, button, istouch, reps)
	if self == inst then
		lgcMenu.pointerPressRepeatLogic(self, x, y, button, istouch, reps)
	end
end


function def:uiCall_pointerDrag(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst and self.press_busy == "menu-drag" then
		lgcMenu.menuPointerDragLogic(self, mouse_x, mouse_y)
	end
end


function def:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)
	if self == inst
	and self.enabled
	and button == self.context.mouse_pressed_button
	then
		lgcScroll.widgetClearPress(self)
		self.press_busy = false
	end
end


function def:uiCall_pointerWheel(inst, x, y)
	if self == inst then
		if widShared.checkScrollWheelScroll(self, x, y) then
			self:cacheUpdate(false)

			return true -- Stop bubbling.
		end
	end
end


function def:uiCall_pointerDragDestRelease(inst, x, y, button, istouch, presses)
	if self == inst then
		return lgcMenu.dragDropReleaseLogic(self)
	end
end


function def:uiCall_thimble1Take(inst)
	if self ~= inst then
		updateSelectedControl(self, inst)
	end
end


function def:uiCall_thimbleAction(inst, key, scancode, isrepeat)
	if self == inst
	and self.enabled
	then
		-- If there is an active, selected control widget, then try to give it the thimble.
		local control = self.items[self.index]
		if control and control:tryTakeThimble1() then
			return true
		end

		self:wid_action(control, self.index)

		return true
	end
end


function def:uiCall_thimbleAction2(inst, key, scancode, isrepeat)
	if self == inst
	and self.enabled
	then
		local control = self.items[self.index]
		self:wid_action2(control, self.index)

		return true
	end
end


function def:uiCall_update(dt)
	dt = math.min(dt, 1.0)

	local scr_x_old, scr_y_old = self.scr_x, self.scr_y
	local needs_update = false

	-- Clear click-sequence item.
	if self.MN_mouse_clicked_item and self.context.cseq_widget ~= self then
		self.MN_mouse_clicked_item = false
	end

	-- Handle update-time drag-scroll.
	if self.MN_drag_scroll
	and self.press_busy == "menu-drag"
	and widShared.dragToScroll(self, dt)
	then
		needs_update = true

	elseif lgcScroll.press_busy_codes[self.press_busy] then
		if self.context.mouse_pressed_ticks > 1 then
			local mx, my = self:getRelativePosition(self.context.mouse_x, self.context.mouse_y)
			local button_step = 350 -- XXX style/config
			lgcScroll.widgetDragLogic(self, mx, my, button_step*dt)
		end
	end

	self:scrollUpdate(dt)

	-- Force a cache update if the external scroll position is different.
	if scr_x_old ~= self.scr_x or scr_y_old ~= self.scr_y then
		needs_update = true
	end

	-- Update scroll bar registers and thumb position.
	lgcScroll.updateScrollBarShapes(self)
	lgcScroll.updateScrollState(self)

	if needs_update then
		self:cacheUpdate(false)
	end
end


local check, change = uiTheme.check, uiTheme.change


def.default_skinner = {
	validate = function(skin)
		check.box(skin, "box")
		check.quad(skin, "tq_px")
		check.scrollBarData(skin, "data_scroll")
		check.scrollBarStyle(skin, "scr_style")
		check.loveType(skin, "font", "Font")
		check.type(skin, "cursor_sash", "nil", "string")
		check.integer(skin, "sash_w", 0)
		check.integer(skin, "item_h", 0)
		check.slice(skin, "sl_body")

		-- Alignment of property name text:
		check.exact(skin, "text_align_h", "left", "center", "right")
		-- Vertical text alignment is centered.

		-- Property name icon column width and positioning, if active.
		check.integer(skin, "icon_spacing", 0)
		check.exact(skin, "icon_side", "left", "right")

		-- Additional padding for left or right-aligned text. No effect with center alignment.
		check.integer(skin, "pad_text_x", 0)

		check.colorTuple(skin, "color_item_text")
		check.colorTuple(skin, "color_select_glow")
		check.colorTuple(skin, "color_active_glow")
		check.colorTuple(skin, "color_item_marked")
	end,


	transform = function(skin, scale)
		change.integerScaled(skin, "sash_w", scale)
		change.integerScaled(skin, "item_h", scale)
		change.integerScaled(skin, "icon_spacing", scale)
		change.integerScaled(skin, "pad_text_x", scale)
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
		local data_icon = skin.data_icon

		local tq_px = skin.tq_px
		local sl_body = skin.sl_body

		local items = self.items

		-- XXX: pick resources for enabled or disabled state, etc.
		--local res = (self.active) and skin.res_active or skin.res_inactive

		-- PropertiesBox body
		love.graphics.setColor(1, 1, 1, 1)
		uiGraphics.drawSlice(sl_body, 0, 0, self.w, self.h)

		lgcScroll.drawScrollBarsHV(self, skin.data_scroll) -- maybe do vertical bars only?

		love.graphics.push("all")

		-- Scissor, scroll offsets for content.
		uiGraphics.intersectScissor(ox + self.x + self.vp2_x, oy + self.y + self.vp2_y, self.vp2_w, self.vp2_h)
		love.graphics.translate(-self.scr_x, -self.scr_y)

		-- No hover glow.

		-- Selection glow.
		local sel_item = items[self.index]
		if sel_item then
			local is_active = self == self.context.thimble1 or sel_item == self.context.thimble1
			local col = is_active and skin.color_active_glow or skin.color_select_glow
			love.graphics.setColor(col)
			uiGraphics.quadXYWH(tq_px, 0, sel_item.y, self.doc_w, sel_item.h)
		end

		-- Menu items.
		love.graphics.setColor(skin.color_item_text)
		local font = skin.font
		love.graphics.setFont(font)
		local font_h = font:getHeight()

		local first = math.max(self.MN_items_first, 1)
		local last = math.min(self.MN_items_last, #items)

		-- 1: Item markings
		local rr, gg, bb, aa = love.graphics.getColor()
		love.graphics.setColor(skin.color_item_marked)
		for i = first, last do
			local item = items[i]
			if item.marked then
				uiGraphics.quadXYWH(tq_px, 0, item.y, self.doc_w, item.h)
			end
		end

		-- 2: Bijou icons, if enabled
		love.graphics.setColor(rr, gg, bb, aa)
		if self.show_icons then
			for i = first, last do
				local item = items[i]
				local tq_bijou = item.tq_bijou
				if tq_bijou then
					uiGraphics.quadShrinkOrCenterXYWH(tq_bijou, self.col_icon_x, item.y, self.col_icon_w, item.h)
				end
			end
		end

		-- 3: Text labels
		for i = first, last do
			local item = items[i]
			-- ugh
			--[[
			love.graphics.push("all")
			love.graphics.setColor(1, 0, 0, 1)
			love.graphics.setLineWidth(1)
			love.graphics.setLineStyle("rough")
			love.graphics.setLineJoin("miter")
			love.graphics.rectangle("line", item.x + 0.5, item.y + 0.5, item.w - 1, item.h - 1)
			love.graphics.pop()
			--]]

			if item.text then
				-- Need to align manually to prevent long lines from wrapping.
				local text_x
				if skin.text_align_h == "left" then
					text_x = self.col_text_x + skin.pad_text_x

				elseif skin.text_align_h == "center" then
					text_x = self.col_text_x + math.floor((self.col_text_w - item.w) * 0.5)

				elseif skin.text_align_h == "right" then
					text_x = self.col_text_x + math.floor(self.col_text_w - item.w - skin.pad_text_x)
				end

				love.graphics.print(
					item.text,
					text_x,
					item.y + math.floor((item.h - font_h) * 0.5)
				)
			end
		end

		love.graphics.pop()

		love.graphics.push("all")

		-- (WIP) Sash
		--love.graphics.setColor(1.0, 1.0, 1.0, 0.5)
		--love.graphics.rectangle("fill", self.vp5_x, self.vp5_y, self.vp5_w, self.vp5_h)
		love.graphics.setColor(1.0, 1.0, 1.0, 0.25)
		local xx = math.floor(self.vp5_x + self.vp5_w / 2)
		love.graphics.setLineStyle("smooth")
		love.graphics.setLineWidth(1.0)
		love.graphics.line(xx, self.vp5_y, xx, self.vp5_y + self.vp5_h)

		love.graphics.pop()
	end,

	--renderLast = function(self, ox, oy) end,

	-- Do not render a standard thimble outline for this widget.
	-- We change the color of the current selection glow instead.
	renderThimble = uiShared.dummyFunc,
}


return def
