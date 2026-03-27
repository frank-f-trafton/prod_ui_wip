
--[[
A menu of "card" items, which are boxes with text and optional icons.

┌─────────────────────────┬─┐
│ ╭───╮ ╭───╮ ╭───╮ ╭───╮ │^│
│ │[B]│ │[B]│ │[B]│ │[B]│ ├─┤
│ │Foo│ │Bar│ │Baz│ │Bop│ │ │
│ ╰───╯ ╰───╯ ╰───╯ ╰───╯ │ │
│ ╭───╮ ╭───╮             │ │
│ │[B]│ │[B]│             │ │
│ │Zip│ │Pop│             ├─┤
│ ╰───╯ ╰───╯             │v│
└─────────────────────────┴─┘

Card flows:

lr: Left to right
tb: Top to bottom
lrtb: Left to right, top to bottom
tblr: Top to bottom, left to right
--]]


local context = select(1, ...)


local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiDummy = require(context.conf.prod_ui_req .. "ui_dummy")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiScale = require(context.conf.prod_ui_req .. "ui_scale")
local uiSchema = require(context.conf.prod_ui_req .. "ui_schema")
local uiTable = require(context.conf.prod_ui_req .. "ui_table")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local wcIconsAndText = context:getLua("shared/wc/wc_icons_and_text")
local wcMenu = context:getLua("shared/wc/wc_menu")
local wcScrollBar = context:getLua("shared/wc/wc_scroll_bar")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "card_box1",

	user_callbacks = uiTable.newLutV(
		"cb_action",
		"cb_action2",
		"cb_action3",
		"cb_select",
		"cb_keyPressed",
		"cb_dropped"
	)
}


wcIconsAndText.attachMethods(def)
wcMenu.attachMenuMethods(def)
widShared.scrollSetMethods(def)
def.setScrollBars = wcScrollBar.setScrollBars
def.impl_scroll_bar = context:getLua("shared/impl_scroll_bar1")


local _arrangers = {
	["lr"] = wcMenu.arrangers["list-lr"],
	["tb"] = wcMenu.arrangers["list-tb"],
	["lrtb"] = wcMenu.arrangers["list-lrtb"],
	["tblr"] = wcMenu.arrangers["list-tblr"]
}


function def:arrangeItems(first, last)
	local cbs = self.skin.card_box_style
	_arrangers[self.arrange_mode](self, self.vp, true, first, last, cbs.spacing_x, cbs.spacing_y)
end


def.getInBounds = wcMenu.getItemInBoundsRect
def.selectionInView = wcMenu.selectionInView
def.getItemAtPoint = wcMenu.widgetGetItemAtPoint -- (self, px, py, first, last)
def.trySelectItemAtPoint = wcMenu.widgetTrySelectItemAtPoint -- (self, x, y, first, last)


def.movePrev = wcMenu.widgetMovePrev
def.moveNext = wcMenu.widgetMoveNext
def.moveFirst = wcMenu.widgetMoveFirst
def.moveLast = wcMenu.widgetMoveLast
def.movePageUp = wcMenu.widgetMovePageUp
def.movePageDown = wcMenu.widgetMovePageDown


-- Widget:cb_action(item, item_i)
-- Called when user double-clicks on the widget or presses "return" or "kpenter".
-- @param item The current selected item, or nil if no item is selected.
-- @param item_i Index of the current selected item, or zero if no item is selected.
def.cb_action = uiDummy.func


-- Widget:cb_action2(item, item_i)
-- Called when the user right-clicks on the widget or presses "application" or shift+F10.
-- @param item The current selected item, or nil if no item is selected.
-- @param item_i Index of the current selected item, or zero if no item is selected.
def.cb_action2 = uiDummy.func


-- Widget:cb_action3(item, item_i)
-- Called when the user middle-clicks on the widget.
-- @param item The current selected item, or nil if no item is selected.
-- @param item_i Index of the current selected item, or zero if no item is selected.
def.cb_action3 = uiDummy.func


-- Widget:cb_select(item, item_i)
-- Called when there is a change in the selected item.
-- @param item The current selected item, or nil if no item is selected.
-- @param item_i Index of the current selected item, or zero if no item is selected.
def.cb_select = uiDummy.func
-- XXX This may not be firing when going from a selected item to nothing selected.


-- Widget:cb_keyPressed(key, scancode, repeat)
-- Called in evt_keyPressed() before the default keyboard navigation checks.
-- @param key The key code.
-- @param scancode The scancode.
-- @param isrepeat Whether this is a key-repeat event.
-- @return true to halt keynav and further bubbling of the keyPressed event.
def.cb_keyPressed = uiDummy.func


-- Widget:cb_dropped(drop_state)
-- Called when the mouse drags and drops something onto this widget.
-- @param drop_state A DropState table that describes the nature of the drag-and-drop action.
-- @return true to clear the DropState and to stop event bubbling.
def.cb_dropped = uiDummy.func


local _nm_arrange_mode = uiTable.newNamedMapV("ArrangeMode", "tb", "lr", "lrtb", "tblr")


function def:setArrangeMode(mode)
	uiAssert.namedMap(1, mode, _nm_arrange_mode)

	self.arrange_mode = mode

	self:reshape()

	return self
end


function def:getArrangeMode()
	return self.arrange_mode
end


local function _countColumns(self)
	local cbs = self.skin.card_box_style
	local span = self.vp.w
	local item_width = cbs.card_w + cbs.spacing_x

	return math.floor(span / item_width)
end


local function _countRows(self)
	local cbs = self.skin.card_box_style
	local span = self.vp.h
	local item_height = cbs.card_h + cbs.spacing_y

	return math.floor(span / item_height)
end


--- Called in evt_keyPressed(). Implements basic keyboard navigation.
-- @param key The key code.
-- @param scancode The scancode.
-- @param isrepeat Whether this is a key-repeat event.
-- @return true to halt keynav and further bubbling of the keyPressed event.
function def:wid_defaultKeyNav(key, scancode, isrepeat)
	local a_mode = self.arrange_mode
	if scancode == "up" then
		if a_mode == "tb" or a_mode == "lr" or a_mode == "tblr" then
			self:movePrev(1, true, isrepeat)
			return true

		elseif a_mode == "lrtb" then
			self:movePrev(_countColumns(self), true, isrepeat)
			return true
		end

	elseif scancode == "down" then
		if a_mode == "tb" or a_mode == "lr" or a_mode == "tblr" then
			self:moveNext(1, true, isrepeat)
			return true

		elseif a_mode == "lrtb" then
			self:moveNext(_countColumns(self), true, isrepeat)
			return true
		end

	elseif scancode == "left" then
		if a_mode == "lr" or a_mode == "tb" or a_mode == "lrtb" then
			self:movePrev(1, true, isrepeat)
			return true

		elseif a_mode == "tblr" then
			self:movePrev(_countRows(self), true, isrepeat)
			return true
		end

	elseif scancode == "right" then
		if a_mode == "lr" or a_mode == "tb" or a_mode == "lrtb" then
			self:moveNext(1, true, isrepeat)
			return true

		elseif a_mode == "tblr" then
			self:moveNext(_countRows(self), true, isrepeat)
			return true
		end

	elseif scancode == "home" then
		self:moveFirst(true)
		return true

	elseif scancode == "end" then
		self:moveLast(true)
		return true

	elseif scancode == "pageup" then
		-- TODO: horizontal paging
		if a_mode == "tb" or a_mode == "lrtb" then
			self:movePageUp(true)
			return true
		end

	elseif scancode == "pagedown" then
		-- TODO: horizontal paging
		if a_mode == "tb" or a_mode == "lrtb" then
			self:movePageDown(true)
			return true
		end
	end
end


local function _shapeItem(self, item)
	--local scale = context.scale
	local cbs = self.skin.card_box_style

	item.w = cbs.card_w
	item.h = cbs.card_h
end


function def:addItem(text, pos, icon_id)
	uiAssert.type(1, text, "string")
	uiAssert.integerEval(2, pos, "number")
	uiAssert.typeEval(3, icon_id, "string")

	local items = self.MN_items

	local item = {}

	item.selectable = true
	item.marked = false -- multi-select

	item.text = text
	item.icon_id = icon_id
	item.tq_icon = wcIconsAndText.getIconQuad(self.icon_set_id, item.icon_id) or false

	item.x, item.y = 0, 0
	_shapeItem(self, item)

	pos = pos or #items + 1

	if pos < 1 or pos > #items + 1 then
		error("position is out of range")
	end

	table.insert(items, pos, item)

	self:arrangeItems(pos, #items)

	return item
end


function def:removeItem(item_t)
	uiAssert.type(1, item_t, "table")

	local item_i = self:menuGetItemIndex(item_t)

	local removed_item = self:removeItemByIndex(item_i)
	return removed_item
end


function def:removeItemByIndex(item_i)
	uiAssert.numberNotNan(1, item_i)

	local items = self.MN_items
	local removed_item = items[item_i]
	if not removed_item then
		error("no item to remove at index: " .. tostring(item_i))
	end

	table.remove(items, item_i)

	wcMenu.removeItemIndexCleanup(self, item_i)

	self:arrangeItems(item_i, #items)

	return removed_item
end


function def:setSelection(item_t)
	uiAssert.type(1, item_t, "table")

	local item_i = self:menuGetItemIndex(item_t)
	self:setSelectionByIndex(item_i)
end


function def:setSelectionByIndex(item_i)
	uiAssert.integerGe(1, item_i, 0)

	local old_index = self.MN_index
	self:menuSetSelectedIndex(item_i)
	if old_index ~= self.MN_index then
		self:cb_select(self.MN_items[self.MN_index], self.MN_index)
	end
end


function def:evt_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 1

	widShared.setupDoc(self)
	widShared.setupScroll(self, -1, -1)
	widShared.setupViewports(self, 2)

	self.press_busy = false

	wcIconsAndText.setupInstance(self)
	wcMenu.setup(self, nil, true, true) -- with mark and drag+drop state

	self.MN_wrap_selection = false

	self.arrange_mode = "lrtb"

	self.show_icons = true

	-- State flags.
	self.enabled = true

	self:skinSetRefs()
	self:skinInstall()
end


function def:evt_reshapePre()
	-- Viewport #1 is the main content viewport.
	-- Viewport #2 separates embedded controls (scroll bars) from the content.

	local skin = self.skin
	local vp, vp2 = self.vp, self.vp2

	vp:set(0, 0, self.w, self.h)
	vp:reduceT(skin.box.border)
	wcScrollBar.arrangeScrollBars(self)

	-- 'Okay-to-click' rectangle.
	vp:copy(vp2)
	vp:reduceT(skin.box.margin)

	self:scrollClampViewport()
	wcScrollBar.updateScrollState(self)

	self:arrangeItems()

	self:cacheUpdate(true)
end



--- Updates cached display state.
-- @param refresh_dimensions When true, update doc_w and doc_h based on the combined dimensions of all items.
-- @return Nothing.
function def:cacheUpdate(refresh_dimensions)
	local skin = self.skin
	local cbs = self.skin.card_box_style

	if refresh_dimensions then
		local vp = self.vp

		local doc_w, doc_h = 0, 0

		local items = self.MN_items
		local last_item = items[#items]

		if last_item then
			if self.arrange_mode == "tb" then
				doc_w = cbs.card_w
				doc_h = last_item.y + last_item.h

			elseif self.arrange_mode == "lr" then
				doc_w = last_item.x + last_item.w
				doc_h = cbs.card_h

			elseif self.arrange_mode == "lrtb" then
				for i, item in ipairs(items) do
					if item.x + item.w <= doc_w then
						break
					end
					doc_w = math.max(doc_w, item.x + item.w)
				end

				doc_h = last_item.y + last_item.h

			elseif self.arrange_mode == "tblr" then
				doc_w = last_item.x + last_item.w

				for i, item in ipairs(items) do
					if item.y + item.h <= doc_h then
						break
					end
					doc_h = math.max(doc_h, item.y + item.h)
				end
			end
		end

		self.doc_w, self.doc_h = doc_w, doc_h

		print("new doc dimensions: ", self.doc_w, self.doc_h)
	end

	-- Set the draw ranges for items.
	if self.arrange_mode == "tb" or self.arrange_mode == "lrtb" then
		wcMenu.widgetAutoRangeV(self)
	else -- "lr", "tblr"
		wcMenu.widgetAutoRangeH(self)
	end
end


function def:evt_keyPressed(targ, key, scancode, isrepeat)
	if self == targ then
		local items = self.MN_items
		local old_index = self.MN_index
		local old_item = items[old_index]

		-- cb_action() is handled in the 'thimbleAction()' callback.

		if self.MN_mark_mode == "toggle" and key == "space" then
			if old_index > 0 and self:menuCanSelect(old_index) then
				self:menuToggleMarkedItem(self.MN_items[old_index])
				return true
			end

		elseif self:cb_keyPressed(key, scancode, isrepeat)
		or self:wid_defaultKeyNav(key, scancode, isrepeat)
		then
			if old_item ~= items[self.MN_index] then
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
				self:cb_select(items[self.MN_index], self.MN_index)
			end
			return true
		end
	end
end


function def:evt_pointerHover(targ, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == targ then
		local mx, my = self:getRelativePosition(mouse_x, mouse_y)

		wcScrollBar.widgetProcessHover(self, mx, my)

		local hover_ok = false

		if self.vp2:pointOverlap(mx, my) then
			mx, my = mx + self.scr_x, my + self.scr_y

			-- Update item hover
			local i, item = self:getItemAtPoint(mx, my, math.max(1, self.MN_items_first), math.min(#self.MN_items, self.MN_items_last))

			if item and item.selectable then
				-- Un-hover any existing hovered item
				self.MN_item_hover = item

				hover_ok = true
			end
		end

		if self.MN_item_hover and not hover_ok then
			self.MN_item_hover = false
		end
	end
end


function def:evt_pointerHoverOff(targ, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == targ then
		wcScrollBar.widgetClearHover(self)
		self.MN_item_hover = false
	end
end


function def:evt_pointerPress(targ, x, y, button, istouch, presses)
	if self == targ
	and self.enabled
	and button == self.context.mouse_pressed_button
	then
		if button <= 3 then
			self:tryTakeThimble1()
		end

		if not wcMenu.pointerPressScrollBars(self, x, y, button) then
			local mx, my = self:getRelativePosition(x, y)

			if self.vp2:pointOverlap(mx, my) then
				mx = mx + self.scr_x
				my = my + self.scr_y

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
							self:cb_select(item_t, item_i)
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
							self:cb_action(item_t, item_i)
						end

					-- Button 2 clicks invoke action 2.
					elseif button == 2 then
						self:cb_action2(item_t, item_i)

					-- Button 3 -> action 3...
					elseif button == 3 then
						self:cb_action3(item_t, item_i)
					end
				end
			end
		end
	end
end


function def:evt_pointerPressRepeat(targ, x, y, button, istouch, reps)
	if self == targ then
		wcMenu.pointerPressRepeatLogic(self, x, y, button, istouch, reps)
	end
end


function def:evt_pointerDrag(targ, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == targ and self.press_busy == "menu-drag" then
		wcMenu.menuPointerDragLogic(self, mouse_x, mouse_y)
	end
end


function def:evt_pointerUnpress(targ, x, y, button, istouch, presses)
	if self == targ
	and self.enabled
	and button == self.context.mouse_pressed_button
	then
		wcScrollBar.widgetClearPress(self)
		self.press_busy = false
	end
end


function def:evt_pointerWheel(targ, x, y)
	if self == targ then
		if widShared.checkScrollWheelScroll(self, x, y) then
			self:cacheUpdate(false)

			return true -- Stop bubbling.
		end
	end
end


function def:evt_pointerDragDestRelease(targ, x, y, button, istouch, presses)
	if self == targ then
		return wcMenu.dragDropReleaseLogic(self)
	end
end


function def:evt_thimbleAction(targ, key, scancode, isrepeat)
	if self == targ
	and self.enabled
	then
		local index = self.MN_index
		local item = self.MN_items[index]

		self:cb_action(item, index)

		return true -- Stop bubbling.
	end
end


function def:evt_thimbleAction2(targ, key, scancode, isrepeat)
	if self == targ
	and self.enabled
	then
		local index = self.MN_index
		local item = self.MN_items[index]

		self:cb_action2(item, index)

		return true -- Stop bubbling.
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


function def:evt_destroy(targ)
	if self == targ then
		widShared.removeViewports(self, 2)
	end
end


local themeAssert = context:getLua("core/res/theme_assert")


def.default_skinner = {
	validate = uiSchema.newKeysX {
		skinner_id = {uiAssert.type, "string"},

		box = themeAssert.box,
		tq_px = themeAssert.quad,
		data_scroll = themeAssert.scrollBarData,
		scr_style = themeAssert.scrollBarStyle,

		font = themeAssert.font,

		card_box_style = themeAssert.cardBoxStyle,

		default_icon_set_id = {uiAssert.types, "nil", "string"},

		sl_body = themeAssert.slice,

		color_body = uiAssert.loveColorTuple,
		color_item_text = uiAssert.loveColorTuple,
		color_item_icon = uiAssert.loveColorTuple,
		color_select_glow = uiAssert.loveColorTuple,
		color_hover_glow = uiAssert.loveColorTuple,
		color_active_glow = uiAssert.loveColorTuple,
		color_item_marked = uiAssert.loveColorTuple
	},


	--transform = function(scale, skin) -- TODO


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)

		-- Update shapes, positions, and icons of any existing items
		for i, item in ipairs(self.MN_items) do
			item.tq_icon = wcIconsAndText.getIconQuad(self.icon_set_id, item.icon_id)
			_shapeItem(self, item)
		end

		self:arrangeItems()

		-- Update the scroll bar style
		self:setScrollBars(self.scr_h, self.scr_v)
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	--refresh = function(self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		local skin, vp2 = self.skin, self.vp2
		local tq_px, sl_body = skin.tq_px, skin.sl_body
		local items = self.MN_items

		local cbs = skin.card_box_style

		local rr, gg, bb, aa = love.graphics.getColor()

		love.graphics.push("all")

		-- CardBox body
		love.graphics.setColor(skin.color_body)
		uiGraphics.drawSlice(sl_body, 0, 0, self.w, self.h)

		love.graphics.setColor(rr, gg, bb, aa)
		wcScrollBar.drawScrollBarsHV(self, skin.data_scroll)

		-- Scissor, scroll offsets for content.
		uiGraphics.intersectScissor(ox + self.x + vp2.x, oy + self.y + vp2.y, vp2.w, vp2.h)
		love.graphics.translate(-self.scr_x, -self.scr_y)

		-- Menu items.
		local font = skin.font
		love.graphics.setFont(font)
		local font_h = font:getHeight()

		local first = math.max(self.MN_items_first, 1)
		local last = math.min(self.MN_items_last, #items)

		-- Item bodies
		local slc_item_body = cbs.body_slc
		if slc_item_body then
			love.graphics.setColor(cbs.color_body)
			for i = first, last do
				local item = items[i]
				uiGraphics.drawSlice(slc_item_body, item.x, item.y, item.w, item.h)
			end
		end

		-- Hover glow.
		local item_hover = self.MN_item_hover
		if item_hover then
			love.graphics.setColor(skin.color_hover_glow)
			uiGraphics.quadXYWH(tq_px, item_hover.x, item_hover.y, item_hover.w, item_hover.h)
		end

		-- Selection glow.
		local sel_item = items[self.MN_index]
		if sel_item then
			local is_active = self == self.context.thimble1
			local col = is_active and skin.color_active_glow or skin.color_select_glow
			love.graphics.setColor(col)
			uiGraphics.quadXYWH(tq_px, sel_item.x, sel_item.y, sel_item.w, sel_item.h)
		end

		-- Item markings
		love.graphics.setColor(skin.color_item_marked)
		for i = first, last do
			local item = items[i]
			if item.marked then
				uiGraphics.quadXYWH(tq_px, 0, item.y, item.w, item.h)
			end
		end

		-- Item icons, if enabled
		if self.show_icons then
			love.graphics.setColor(skin.color_item_icon)
			for i = first, last do
				local item = items[i]
				local tq_icon = item.tq_icon
				if tq_icon then
					uiGraphics.quadShrinkOrCenterXYWH(tq_icon, item.x + cbs.icon_x, item.y + cbs.icon_y, cbs.icon_w, cbs.icon_h)
				end
			end
		end

		-- Text labels
		local text_crop = cbs.text_crop
		local sc_x = ox + self.x - self.scr_x + cbs.text_x
		local sc_y = oy + self.y - self.scr_y + cbs.text_y
		local xx, yy, ww, hh = love.graphics.getScissor()

		love.graphics.setColor(skin.color_item_text)
		for i = first, last do
			local item = items[i]
			if item.text then
				if text_crop then
					uiGraphics.intersectScissor(sc_x + item.x, sc_y + item.y, cbs.text_w, cbs.text_h)
				end

				love.graphics.printf(
					item.text,
					item.x + cbs.text_x,
					item.y + cbs.text_y,
					cbs.text_w,
					cbs.text_align_x
				)

				if text_crop then
					love.graphics.setScissor(xx, yy, ww, hh)
				end
			end
		end

		love.graphics.pop()

		--[====[
		-- Debug: show text and icon regions
		love.graphics.push("all")

		love.graphics.setColor(1, 0, 0, 0.5)
		love.graphics.rectangle("fill", 0, 0, cbs.card_w, cbs.card_h)

		love.graphics.setColor(0, 1, 0, 0.5)
		love.graphics.rectangle("fill", cbs.icon_x, cbs.icon_y, cbs.icon_w, cbs.icon_h)

		love.graphics.setColor(0, 0, 1, 0.5)
		love.graphics.rectangle("fill", cbs.text_x, cbs.text_y, cbs.text_w, cbs.text_h)

		love.graphics.pop()
		--]====]
	end,


	--renderLast = function(self, ox, oy) end,


	renderThimble = wcMenu.renderThimbleNoSelection
}


return def
