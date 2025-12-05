--- XXX: Under construction.
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
│ [B] Baz                │ ["Twist"           ] │ │
│ [B] Qux                │ [dir/ectory        ] │ │
│                        |                      ├─┤
│                        |                      │v│
└───────────────────────────────────────────────┴─┘
--]]


local context = select(1, ...)


local pMath = require(context.conf.prod_ui_req .. "lib.pile_math")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiDummy = require(context.conf.prod_ui_req .. "ui_dummy")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiScale = require(context.conf.prod_ui_req .. "ui_scale")
local uiSchema = require(context.conf.prod_ui_req .. "ui_schema")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local wcMenu = context:getLua("shared/wc/wc_menu")
local wcScrollBar = context:getLua("shared/wc/wc_scroll_bar")
local widShared = context:getLua("core/wid_shared")


local _lerp = pMath.lerp


local def = {
	skin_id = "properties_box1",

	default_settings = {
		icon_set_id = false -- lookup for 'resources.icons[icon_set_id]'
	}
}


wcMenu.attachMenuMethods(def)
widShared.scrollSetMethods(def)
def.setScrollBars = wcScrollBar.setScrollBars
def.impl_scroll_bar = context:getLua("shared/impl_scroll_bar1")


local _arrange_tb = wcMenu.arrangers["list-tb"]
function def:arrangeItems(first, last)
	_arrange_tb(self, self.vp, true, first, last)

	local vp_x = self.vp.x

	-- position control widgets
	local items = self.MN_items
	first, last = first or 1, last or #items
	for i = first, last do
		local item = items[i]
		local wid = item.wid_ref
		if wid then
			wid.x = self.vp4.x - vp_x
			wid.y = item.y
		end
	end
end


-- * Scroll helpers *


def.getInBounds = wcMenu.getItemInBoundsY
def.selectionInView = wcMenu.selectionInView


-- * Spatial selection *


def.getItemAtPoint = wcMenu.widgetGetItemAtPointV -- (self, px, py, first, last)
def.trySelectItemAtPoint = wcMenu.widgetTrySelectItemAtPoint -- (self, x, y, first, last)


-- * Selection movement *


def.movePrev = wcMenu.widgetMovePrev
def.moveNext = wcMenu.widgetMoveNext
def.moveFirst = wcMenu.widgetMoveFirst
def.moveLast = wcMenu.widgetMoveLast
def.movePageUp = wcMenu.widgetMovePageUp
def.movePageDown = wcMenu.widgetMovePageDown


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


-- Called when there is a change in the item selection.
-- @param item The current selected item, or nil if no item is selected.
-- @param item_i Index of the current selected item, or zero if no item is selected.
function def:wid_select(item, item_i)
	-- XXX This may not be firing when going from a selected item to nothing selected.
end


--- Called in evt_keyPressed() before the default keyboard navigation checks.
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


--- Called in evt_keyPressed(). Implements basic keyboard navigation.
-- @param key The key code.
-- @param scancode The scancode.
-- @param isrepeat Whether this is a key-repeat event.
-- @return true to halt keynav and further bubbling of the keyPressed event.
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


local function updateItemDimensions(self, item)
	local skin = self.skin
	item.w = self.vp.w
	item.h = skin.item_h

	local font = skin.font
	item.text_w = font:getWidth(item.text)

	local wid = item.wid_ref
	if wid then
		wid.w = self.vp4.w
		wid.h = item.h
	end
end


function def:addItem(wid_id, text, pos, icon_id)
	uiAssert.type(2, text, "string")
	uiAssert.integerEval(3, pos, "number")
	uiAssert.typeEval(4, icon_id, "string")

	local items = self.MN_items

	local item = {}

	item.selectable = true
	item.marked = false -- multi-select
	item.x, item.y, item.w, item.h = 0, 0, 0, 0
	item.text = text
	item.icon_id = icon_id
	item.tq_icon = wcMenu.getIconQuad(self.icon_set_id, item.icon_id) or false

	pos = pos or #items + 1

	if pos < 1 or pos > #items + 1 then
		error("addItem: insert position is out of range.")
	end

	local wid = self:addChild(wid_id, nil, pos) -- XXX: fit in skin_id?

	item.wid_ref = wid

	table.insert(items, pos, item)

	updateItemDimensions(self, item)
	self:arrangeItems(1, pos, #items)
	wid:reshape()

	--print("addItem text:", item.text, "y: ", item.y)

	return item
end


function def:removeItem(item_t)
	uiAssert.type(1, item_t, "table")

	local item_i = self:menuGetItemIndex(item_t)

	local removed_item = self:removeItemByIndex(item_i)
	return removed_item
end


function def:removeItemByIndex(item_i)
	uiAssert.numberNotNaN(1, item_i)

	local items = self.MN_items
	local item_t = items[item_i]
	if not item_t then
		error("no item to remove at index: " .. tostring(item_i))
	end

	table.remove(items, item_i)

	-- clean up the control widget
	local wid_ref = item_t.wid_ref
	if wid_ref then
		wid_ref:destroy()
	end
	item_t.wid_ref = false

	wcMenu.removeItemIndexCleanup(self, item_i, "MN_index")

	self:arrangeItems(1, item_i, #items)

	return item_t
end


function def:setSelection(wid)
	uiAssert.type(1, wid, "table")

	local wid_i = self:menuGetItemIndex(wid)
	self:setSelectionByIndex(wid_i)
end


function def:setSelectionByIndex(wid_i)
	uiAssert.integerGE(1, wid_i, 0)

	self:menuSetSelectedIndex(wid_i)
end


local function _enforceMinCol1Width(self)
	self.col_1_w = math.max(self.col_1_w, self.skin.col_1_min_w)
end


local function _updateCol1Scaled(self) -- col_1_w -> col_1_ws
	-- Viewport #1 must be correctly sized before calling.
	local skin = self.skin
	local sash_total_width = skin.sash_margin_1 + skin.sash_style.breadth_half*2 + skin.sash_margin_2
	local max_w = self.vp.w - sash_total_width - skin.col_2_min_w
	self.col_1_ws = math.floor(math.min(max_w, self.col_1_w * context.scale))
	self.col_1_w_max = math.floor(max_w * (1 / math.max(0.1, context.scale)))
end


function def:evt_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 1

	widShared.setupDoc(self)
	widShared.setupScroll(self, -1, -1)
	widShared.setupViewports(self, 5)

	self.press_busy = false

	wcMenu.setup(self, nil, true, true) -- with mark and drag+drop state
	self.MN_wrap_selection = false

	self.sash_enabled = true
	self.sash_hovered = false
	self.sash_att_x = 0

	-- Positions of text and icons within the label column.
	-- (pos_text_w == the width alotted for text, not the width of the text itself.)
	self.pos_icon_x = 0
	self.pos_icon_w = 0

	self.pos_text_x = 0
	self.pos_text_w = 0

	-- State flags.
	self.enabled = true

	-- Shows a column of icons when true.
	self.show_icons = false

	self:skinSetRefs()
	self:skinInstall()

	-- Width of the label column.
	self.col_1_w = self.skin.col_1_def_w

	-- Sets:
	-- * self.col_1_ws: A scaled version of 'col_1_w', to be used when setting viewport #5.
	-- * self.col_1_w_max: The max allowed column width when dragging
	_updateCol1Scaled(self)

	-- The value of 'col_1_w' when the sash was clicked.
	self.col_1_w_click = 0
end


local _side_oppo = {left="right", right="left"}


function def:evt_reshapePre()
	-- Viewport #1 is the main content viewport.
	-- Viewport #2 separates embedded controls (scroll bars) from the content.
	-- Viewport #3 is the area for item labels.
	-- Viewport #4 is the area for item controls (child widgets).
	-- Viewport #5 is a sash that is placed between the labels and controls.

	local skin = self.skin
	local vp, vp2, vp3, vp4, vp5 = self.vp, self.vp2, self.vp3, self.vp4, self.vp5
	local sash_style = skin.sash_style
	local sm1, sm2 = skin.sash_margin_1, skin.sash_margin_2

	vp:set(0, 0, self.w, self.h)

	-- Border and scroll bars.
	vp:reduceT(skin.box.border)
	wcScrollBar.arrangeScrollBars(self)

	-- 'Okay-to-click' rectangle.
	vp:copy(vp2)

	-- Margin.
	vp:reduceT(skin.box.margin)

	_enforceMinCol1Width(self)
	_updateCol1Scaled(self)

	vp:copy(vp4)
	vp4:split(vp3, _side_oppo[skin.control_side], self.col_1_ws)
	vp4:split(vp5, _side_oppo[skin.control_side], sm1 + sash_style.breadth_half*2 + sm2)
	vp5:reduceHorizontal(sm1, sm2)

	self:scrollClampViewport()
	wcScrollBar.updateScrollState(self)

	for i, item in ipairs(self.MN_items) do
		updateItemDimensions(self, item)
	end
	self:arrangeItems()

	self:cacheUpdate(true)

	-- don't allow child widget gfx to spill out of the control column.
	widShared.setClipScissorToViewport(self, vp4)
end


--- Updates cached display state.
-- @param refresh_dimensions When true, update doc_w and doc_h based on the combined dimensions of all controls.
-- @return Nothing.
function def:cacheUpdate(refresh_dimensions)
	local skin = self.skin

	if refresh_dimensions then
		self.doc_w, self.doc_h = 0, 0

		-- Document height is based on the last control in the menu.
		local children = self.nodes
		local last_wid = children[#children]
		if last_wid then
			self.doc_h = last_wid.y + last_wid.h
		end

		-- Calculate icon and text positions within the label column.
		if skin.icon_side == "left" then
			self.pos_icon_x = 0
			self.pos_icon_w = self.show_icons and skin.icon_spacing or 0
			self.pos_text_x = self.pos_icon_x + self.pos_icon_w
			self.pos_text_w = math.max(0, self.vp3.w - self.pos_text_x)
		else -- "right"
			self.pos_text_x = 0
			self.pos_text_w = math.max(0, self.vp3.w - self.pos_text_x)
			self.pos_icon_x = self.pos_text_x + self.pos_text_w
			self.pos_icon_w = self.show_icons and skin.icon_spacing or 0
		end

		self.doc_w = self.vp.w
	end

	-- Set the draw ranges for controls.
	wcMenu.widgetAutoRangeV(self)
end


local function updateSelectedControl(self, control)
	local old_item = self.MN_items[self.MN_index]

	self:menuClearAllMarkedItems()

	local new_item
	for i, item in ipairs(self.MN_items) do
		if item.wid_ref == control then
			self:menuSetSelectedItem(item)
			new_item = item
			break
		end
	end

	if old_item ~= new_item then
		self:wid_select(new_item, self:menuGetItemIndex(new_item))
	end
end


function def:evt_keyPressed(inst, key, scancode, isrepeat)
	local items = self.MN_items
	local old_index = self.MN_index
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
			local new_item = items[self.MN_index]
			if old_item ~= new_item then
				if self.MN_mark_mode == "cursor" then
					local mods = self.context.key_mgr.mod
					if mods["shift"] then
						self:menuClearAllMarkedItems()
						wcMenu.markItemsCursorMode(self, old_index)
					else
						self.MN_mark_index = false
						self:menuClearAllMarkedItems()
						self:menuSetMarkedItemByIndex(self.MN_index, true)
					end
				end

				self:wid_select(new_item, self.MN_index)
			end
			return true
		end
	end
end


function def:evt_keyReleased(inst, keycode, scancode)
	if self == inst then
		-- If there is a selected child widget, forward keyboard events to it first.
		local item = self.MN_items[self.MN_index]
		local control = item and item.wid_ref
		if control and control:eventSend("evt_keyReleased", control, keycode, scancode) then
			return true
		end
	end
end


function def:evt_textInput(inst, text)
	if self == inst then
		-- If there is a selected child widget, forward keyboard events to it first.
		local item = self.MN_items[self.MN_index]
		local control = item and item.wid_ref
		if control and control:eventSend("evt_textInput", control, text) then
			return true
		end
	end
end


function def:evt_pointerHover(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		local mx, my = self:getRelativePosition(mouse_x, mouse_y)

		wcScrollBar.widgetProcessHover(self, mx, my)

		-- Sash hover logic
		if self.sash_enabled then
			local vp5 = self.vp5
			local sash_style = self.skin.sash_style
			-- hover on
			if not self.sash_hovered then
				local con_x, con_y = sash_style.contract_x, sash_style.contract_y
				if mx >= vp5.x + con_x
				and mx < vp5.x + vp5.w - con_x
				and my >= vp5.y + con_y
				and my < vp5.y + vp5.h - con_y
				then
					self.sash_hovered = true
					self.cursor_hover = self.skin.sash_style.cursor_hover_h
				end
			-- hover off
			else
				local exp_x, exp_y = sash_style.expand_x, sash_style.expand_y

				if not (mx >= vp5.x - exp_x
				and mx < vp5.x + vp5.w + exp_x
				and my >= vp5.y - exp_y
				and my < vp5.y + vp5.h + exp_y)
				then
					self.sash_hovered = false
					self.cursor_hover = nil
				end
			end
		else
			self.sash_hovered = false
			self.cursor_hover = nil
		end

		local hover_ok = false

		if not self.sash_hovered then
			-- Hovering over labels and controls
			if self.vp2:pointOverlap(mx, my) then
				local mxs, mys = mx + self.scr_x, my + self.scr_y

				-- Update item hover
				local i, item = self:getItemAtPoint(mxs, mys, math.max(1, self.MN_items_first), math.min(#self.MN_items, self.MN_items_last))

				if item and item.selectable then
					-- Un-hover any existing hovered item
					self.MN_item_hover = item

					hover_ok = true
				end
			end
		end

		if self.MN_item_hover and not hover_ok then
			self.MN_item_hover = false
		end
	end
end


function def:evt_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		wcScrollBar.widgetClearHover(self)
		self.sash_hovered = false
		self.cursor_hover = nil
		self.MN_item_hover = false
	end
end


function def:evt_pointerPress(inst, x, y, button, istouch, presses)
	if self.enabled
	and button == self.context.mouse_pressed_button
	then
		if button <= 3 then
			-- The user clicked on a child widget
			if self ~= inst then
				updateSelectedControl(self, inst)
			end
		end

		if self == inst then
			if button <= 3 then
				self:tryTakeThimble1()
			end
			if not wcMenu.pointerPressScrollBars(self, x, y, button) then
				local mx, my = self:getRelativePosition(x, y)

				-- Clicked on sash?
				if self.sash_enabled and self.sash_hovered and not self.press_busy then
					self.press_busy = "sash"
					self.sash_att_x = x
					self.col_1_w_click = self.col_1_w
					self.cursor_press = self.skin.sash_style.cursor_drag_h

				-- The user clicked somewhere on the menu, outside of child widgets (or "through"
				-- an inactive child widget)
				elseif self.vp2:pointOverlap(mx, my) then
					mx, my = mx + self.scr_x, my + self.scr_y

					local item_i, item_t = wcMenu.checkItemIntersect(self, mx, my, button)

					if item_t and item_t.selectable then
						local old_index = self.MN_index
						local old_item = self.MN_items[old_index]

						-- Buttons 1, 2 and 3 all select an item.
						-- Only button 1 updates the item mark state.
						if button <= 3 then
							wcMenu.widgetSelectItemByIndex(self, item_i)
							self.MN_mouse_clicked_item = item_t

							if button == 1 then
								wcMenu.pointerPressButton1(self, item_t, old_index)
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


function def:evt_pointerPressRepeat(inst, x, y, button, istouch, reps)
	if self == inst then
		wcMenu.pointerPressRepeatLogic(self, x, y, button, istouch, reps)
	end
end


function def:evt_pointerDrag(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		if self.press_busy == "sash" then
			local x_diff = mouse_x - self.sash_att_x
			if self.skin.control_side == "left" then
				x_diff = -x_diff
			end
			local width_old = self.col_1_w

			self.col_1_w = self.col_1_w_click + x_diff * (1 / math.max(0.1, context.scale))
			_enforceMinCol1Width(self)
			self.col_1_w = math.min(self.col_1_w, self.col_1_w_max)
			_updateCol1Scaled(self)

			if self.col_1_w ~= width_old then
				self:reshape()
			end

		elseif self.press_busy == "menu-drag" then
			wcMenu.menuPointerDragLogic(self, mouse_x, mouse_y)
		end
	end
end


function def:evt_pointerUnpress(inst, x, y, button, istouch, presses)
	if self == inst
	and self.enabled
	and button == self.context.mouse_pressed_button
	then
		wcScrollBar.widgetClearPress(self)
		self.press_busy = false
		self.cursor_press = nil
	end
end


function def:evt_pointerWheel(inst, x, y)
	if self == inst then
		if widShared.checkScrollWheelScroll(self, x, y) then
			self:cacheUpdate(false)

			return true -- Stop bubbling.
		end
	end
end


function def:evt_pointerDragDestRelease(inst, x, y, button, istouch, presses)
	if self == inst then
		return wcMenu.dragDropReleaseLogic(self)
	end
end


function def:evt_thimble1Take(inst)
	if self ~= inst then
		updateSelectedControl(self, inst)
	end
end


function def:evt_thimbleAction(inst, key, scancode, isrepeat)
	if self == inst
	and self.enabled
	then
		-- If there is an active, selected control widget, then try to give it the thimble.
		local item = self.MN_items[self.MN_index]
		local control = item and item.wid_ref
		if control and control:tryTakeThimble1() then
			return true
		end

		self:wid_action(control, self.MN_index)

		return true
	end
end


function def:evt_thimbleAction2(inst, key, scancode, isrepeat)
	if self == inst
	and self.enabled
	then
		local item = self.MN_items[self.MN_index]
		local control = item and item.wid_ref
		self:wid_action2(control, self.MN_index)

		return true
	end
end


function def:evt_update(dt)
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

	elseif wcScrollBar.press_busy_codes[self.press_busy] then
		if self.context.mouse_pressed_ticks > 1 then
			local mx, my = self:getRelativePosition(self.context.mouse_x, self.context.mouse_y)
			local button_step = 350 -- XXX style/config
			wcScrollBar.widgetDragLogic(self, mx, my, button_step*dt)
		end
	end

	self:scrollUpdate(dt)

	-- Force a cache update if the external scroll position is different.
	if scr_x_old ~= self.scr_x or scr_y_old ~= self.scr_y then
		needs_update = true
	end

	-- Update scroll bar registers and thumb position.
	wcScrollBar.updateScrollBarShapes(self)
	wcScrollBar.updateScrollState(self)

	if needs_update then
		self:cacheUpdate(false)
	end
end


function def:evt_destroy(inst)
	if self == inst then
		widShared.removeViewports(self, 5)
	end
end


local themeAssert = context:getLua("core/res/theme_assert")


def.default_skinner = {
	validate = uiSchema.newKeysX {
		skinner_id = {uiAssert.type, "string"},

		-- Settings
		icon_set_id = {uiAssert.types, "nil", "string"},
		-- / Settings

		box = themeAssert.box,
		tq_px = themeAssert.quad,
		data_scroll = themeAssert.scrollBarData,
		scr_style = themeAssert.scrollBarStyle,
		sash_style = themeAssert.sashStyle,
		font = themeAssert.font,

		item_h = {uiAssert.integerGE, 0},

		-- The minimum preferred label column width
		col_1_min_w = {uiAssert.integerGE, 0},

		-- The default label column width
		col_1_def_w = {uiAssert.integerGE, 0},

		-- The minimum preferred control column width.
		-- Used when clamping the width of the label column.
		col_2_min_w = {uiAssert.integerGE, 0},

		-- Which side to place the label column: "left", "right"
		control_side = {uiAssert.oneOf, "left", "right"},

		sash_margin_1 = {uiAssert.integerGE, 0},
		sash_margin_2 = {uiAssert.integerGE, 0},

		sl_body = themeAssert.slice,

		-- Alignment of property name text:
		text_align_h = {uiAssert.numberRange, 0.0, 1.0},
		-- Vertical text alignment is centered.

		-- Property name icon column width and positioning, if active.
		icon_spacing = {uiAssert.integerGE, 0},
		icon_side = {uiAssert.oneOf, "left", "right"},

		-- Additional padding for left or right-aligned text. No effect with center alignment.
		pad_text_x = {uiAssert.integerGE, 0},

		color_item_text = uiAssert.loveColorTuple,
		color_select_glow = uiAssert.loveColorTuple,
		color_active_glow = uiAssert.loveColorTuple,
		color_item_marked = uiAssert.loveColorTuple
	},


	transform = function(scale, skin)
		uiScale.fieldInteger(scale, skin, "item_h")
		uiScale.fieldInteger(scale, skin, "col_1_min_w")
		uiScale.fieldInteger(scale, skin, "col_1_def_w")
		uiScale.fieldInteger(scale, skin, "col_2_min_w")
		uiScale.fieldInteger(scale, skin, "sash_margin_1")
		uiScale.fieldInteger(scale, skin, "sash_margin_2")

		uiScale.fieldInteger(scale, skin, "icon_spacing")
		uiScale.fieldInteger(scale, skin, "pad_text_x")
	end,


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)

		-- Update shapes, positions, and icons of any existing items
		for i, item in ipairs(self.MN_items) do
			item.tq_icon = wcMenu.getIconQuad(self.icon_set_id, item.icon_id)
			updateItemDimensions(self, item)
		end

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
		local vp2, vp3, vp5 = self.vp2, self.vp3, self.vp5
		local data_icon = skin.data_icon

		local tq_px = skin.tq_px
		local sl_body = skin.sl_body

		local items = self.MN_items

		-- XXX: pick resources for enabled or disabled state, etc.
		--local res = (self.active) and skin.res_active or skin.res_inactive

		-- PropertiesBox body
		love.graphics.setColor(1, 1, 1, 1)
		uiGraphics.drawSlice(sl_body, 0, 0, self.w, self.h)

		wcScrollBar.drawScrollBarsHV(self, skin.data_scroll) -- maybe do vertical bars only?

		-- Sash
		local s_style = skin.sash_style
		local s_res = not self.sashes_enabled and s_style["res_disabled"]
			or self.press_busy == "sash" and s_style["res_press"]
			or self.sash_hovered and s_style["res_hover"]
			or s_style["res_idle"]

		love.graphics.setColor(s_res.col_body)
		uiGraphics.drawSlice(s_res.slc_tb, vp5.x, vp5.y, vp5.w, vp5.h)

		love.graphics.push("all")

		-- Scissor, scroll offsets for content.
		uiGraphics.intersectScissor(ox + self.x + vp2.x, oy + self.y + vp2.y, vp2.w, vp2.h)
		love.graphics.translate(-self.scr_x, -self.scr_y)

		-- No hover glow.

		-- Selection glow.
		local sel_item = items[self.MN_index]
		local sel_control = sel_item and sel_item.wid_ref
		if sel_control then
			local is_active = self == self.context.thimble1 or sel_control == self.context.thimble1
			local col = is_active and skin.color_active_glow or skin.color_select_glow
			love.graphics.setColor(col)
			uiGraphics.quadXYWH(tq_px, 0, sel_control.y, self.doc_w, sel_control.h)
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

		--local sx, sy, sw, sh = love.graphics.getScissor()
		uiGraphics.intersectScissor(ox + self.x + vp3.x, oy + self.y + vp3.y, vp3.w, vp3.h)

		-- 2: Icons, if enabled
		love.graphics.setColor(rr, gg, bb, aa)
		if self.show_icons then
			for i = first, last do
				local item = items[i]
				local tq_icon = item.tq_icon
				if tq_icon then
					uiGraphics.quadShrinkOrCenterXYWH(tq_icon, self.pos_icon_x, item.y, self.pos_icon_w, item.h)
				end
			end
		end

		-- 3: Text labels
		for i = first, last do
			local item = items[i]
			local text_x = math.floor(0.5 + _lerp(0, self.pos_text_w - item.text_w, skin.text_align_h))
			love.graphics.print(
				item.text,
				vp3.x + self.pos_text_x + text_x,
				item.y + math.floor((item.h - font_h) * 0.5)
			)
		end

		love.graphics.pop()
	end,

	--renderLast = function(self, ox, oy) end,

	-- Do not render a standard thimble outline for this widget.
	-- We change the color of the current selection glow instead.
	renderThimble = uiDummy.func,
}


return def
