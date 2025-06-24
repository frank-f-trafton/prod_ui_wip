
--[[
wimp/dropdown_pop: The "drawer" component of a dropdown menu.

'self.wid_ref' points to the invoking dropdown base widget.

These are not real OS widgets, so they are limited to the boundaries of the window.
They may act strangely if the window is too small for the menu contents.

See `wimp/dropdown_box.lua` for more notes.
--]]


local context = select(1, ...)


local lgcMenu = context:getLua("shared/lgc_menu")
local lgcPopUps = context:getLua("shared/lgc_pop_ups")
local lgcScroll = context:getLua("shared/lgc_scroll")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "dropdown_pop1",

	default_settings = {
		icon_side = "left", -- "left", "right"
		show_icons = false,
		text_align_h = "left", -- "left", "center", "right"
		icon_set_id = false, -- lookup for 'resources.icons[icon_set_id]'
	},

	trickle = {}
}


def.setBlocking = lgcPopUps.setBlocking


lgcMenu.attachMenuMethods(def)
widShared.scrollSetMethods(def)
def.setScrollBars = lgcScroll.setScrollBars
def.impl_scroll_bar = context:getLua("shared/impl_scroll_bar1")
def.arrangeItems = lgcMenu.arrangeItemsVerticalTB


-- * Scroll helpers *


def.getInBounds = lgcMenu.getItemInBoundsY
def.selectionInView = lgcMenu.selectionInView


-- * Spatial selection *


def.getItemAtPoint = lgcMenu.widgetGetItemAtPointVClamp -- (self, px, py, first, last)
def.trySelectItemAtPoint = lgcMenu.widgetTrySelectItemAtPoint -- (self, x, y, first, last)


-- * Selection movement *


def.movePrev = lgcMenu.widgetMovePrev
def.moveNext = lgcMenu.widgetMoveNext
def.moveFirst = lgcMenu.widgetMoveFirst
def.moveLast = lgcMenu.widgetMoveLast
def.movePageUp = lgcMenu.widgetMovePageUp
def.movePageDown = lgcMenu.widgetMovePageDown


local function _updateDocumentHeight(self)
	local last_item = self.MN_items[#self.MN_items]

	self.doc_h = last_item and last_item.y + last_item.h or 0
end


local function _updateDocumentWidth(self, w)
	self.doc_w = math.max(self.doc_w, w)
end


local function _recalculateDocumentWidth(self)
	local max_w = 0
	for i, item in ipairs(self.MN_items) do
		max_w = math.max(max_w, item.w)
	end
	self.doc_w = max_w
end


local function _shapeItem(self, item)
	local skin = self.skin
	local font = skin.font

	item.w = font:getWidth(item.text)
	item.h = math.floor((font:getHeight() * font:getLineHeight()) + skin.item_pad_v)
	item.tq_icon = lgcMenu.getIconQuad(self.icon_set_id, item.icon_id)
end


function def:_closeSelf(update_chosen)
	if not self._dead then
		local wid_ref = self.wid_ref
		if wid_ref and not wid_ref._dead then
			wid_ref.wid_drawer = false

			if update_chosen then
				-- Confirm that the linked source item still exists in the main widget.
				local chosen = self.MN_items[self.MN_index]
				if chosen and type(chosen.source_item) == "table" then
					local source_i = wid_ref:menuHasItem(chosen.source_item)
					if source_i then
						wid_ref:setSelectionByIndex(source_i)
					end
				end
			end
		end

		local root = self:getRootWidget()
		if root.pop_up_menu == self then
			root:sendEvent("rootCall_destroyPopUp", self, "concluded")
		end
	end
end


local _mt_item = {selectable=true}
_mt_item.__index = _mt_item


function def:addItem(text, pos, icon_id, suppress_select)
	local skin = self.skin
	local font = skin.font
	local items = self.MN_items

	uiShared.type1(1, text, "string")
	uiShared.intRangeEval(2, pos, 1, #items + 1)
	uiShared.typeEval1(3, icon_id, "string")

	pos = pos or #items + 1

	local item = setmetatable({x=0, y=0, w=0, h=0}, _mt_item)

	item.text = text
	item.icon_id = icon_id
	item.tq_icon = false

	-- 'item.source_item' is set by the caller for later reference.

	table.insert(items, pos, item)

	_shapeItem(self, item)
	self:arrangeItems(1, pos, #items)
	_updateDocumentWidth(self, item.w)
	_updateDocumentHeight(self)

	if not suppress_select then
		lgcMenu.trySelectIfNothingSelected(self)
	end

	return item
end


function def:removeItem(item_t)
	uiShared.type1(1, item_t, "table")

	local item_i = self:menuGetItemIndex(item_t)
	local removed_item = self:removeItemByIndex(item_i)
	return removed_item
end


function def:removeItemByIndex(item_i)
	uiShared.intGE(1, item_i, 0)

	local items = self.MN_items
	local removed_item = items[item_i]
	if not removed_item then
		error("no item to remove at index: " .. tostring(item_i))
	end

	local removed = table.remove(items, item_i)

	lgcMenu.removeItemIndexCleanup(self, item_i, "MN_index")

	_recalculateDocumentWidth(self)
	_updateDocumentHeight(self)

	return removed_item
end


function def:setSelection(item_t)
	uiShared.type1(1, item_t, "table")

	local item_i = self:menuGetItemIndex(item_t)
	self:setSelectionByIndex(item_i)
end


function def:setSelectionByIndex(item_i)
	uiShared.intGE(1, item_i, 0)

	local index_old = self.MN_index

	self:menuSetSelectedIndex(item_i)

	if index_old ~= self.MN_index then
		if self.wid_ref then
			self.wid_ref:wid_drawerSelection(self, self.MN_index, self.MN_items[self.MN_index])
		end
	end
end


def.keepInBounds = widShared.keepInBoundsOfParent


function def:menuChangeCleanup()
	for i, item in ipairs(self.MN_items) do
		_shapeItem(self, item)
	end
	self:arrangeItems()
	_recalculateDocumentWidth(self)
	_updateDocumentHeight(self)

	self:menuSetSelectionStep(0, false)
	self:selectionInView(true)
	self:scrollClampViewport()
	self:cacheUpdate()
end


function def:cacheUpdate()
	lgcMenu.widgetAutoRangeV(self)
end


function def:centerSelectedItem(immediate)
	local selected = self.MN_items[self.MN_index]
	if selected then
		self:scrollV(math.floor(0.5 + selected.y + selected.h / 2 - self.vp_h / 2), immediate)
		self:cacheUpdate()
	end
end


def.setIconSetID = lgcMenu.setIconSetID
def.getIconSetID = lgcMenu.getIconSetID


function def:uiCall_initialize()
	if not self.wid_ref then
		error("no owner widget assigned to this menu.")
	end

	self.visible = true
	self.allow_hover = true
	self.can_have_thimble = true
	self.clip_scissor = true

	self.sort_id = 7

	lgcPopUps.setupInstance(self)

	widShared.setupDoc(self)
	widShared.setupScroll(self, -1, -1)
	widShared.setupViewports(self, 4)

	self.widest_width = 0

	self.press_busy = false

	lgcMenu.setup(self)
	self.MN_wrap_selection = false

	self:setScrollBars(false, true)

	self:skinSetRefs()
	self:skinInstall()
end


function def:uiCall_reshapePre()
	-- Viewport #1 is the main content viewport.
	-- Viewport #2 separates embedded controls (scroll bars) from the content.
	-- Viewport #3 represents the size and horizontal position of one item.
	-- Viewport #4 is the area for text.
	-- Viewport #5 is the area for icons.

	local skin = self.skin
	local wid_ref = self.wid_ref
	local root = self:getRootWidget()

	if not wid_ref or wid_ref._dead then
		return true
	end

	-- We assume that the root widget's dimensions match the display area.

	self.w = math.min(root.w, math.max(wid_ref.w, self.doc_w))
	self.h = math.min(root.h, (skin.item_height * math.min(skin.max_visible_items, #self.MN_items)))

	self:keepInBounds()

	widShared.resetViewport(self, 1)

	-- Border and scroll bars.
	widShared.carveViewport(self, 1, skin.box.border)
	lgcScroll.arrangeScrollBars(self)

	-- 'Okay-to-click' rectangle.
	widShared.copyViewport(self, 1, 2)

	-- Margin.
	widShared.carveViewport(self, 1, skin.box.margin)

	-- Dimensions and horizontal position for one menu item.
	widShared.setViewport(self, 3, self.vp_x, 0, self.vp_w, skin.item_height)

	-- Area for text
	widShared.copyViewport(self, 3, 4)

	-- Area for the icon
	local icon_spacing = self.show_icons and skin.icon_spacing or 0
	widShared.partitionViewport(self, 4, 5, icon_spacing, skin.icon_side, true)

	-- Additional text padding
	widShared.carveViewport(self, 4, skin.box.margin)

	self:scrollClampViewport()
	lgcScroll.updateScrollState(self)

	self:cacheUpdate()

	return true
end


function def:uiCall_keyPressed(key, scancode, isrepeat)
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

	elseif scancode == "escape" then
		self:_closeSelf(false)
		return true

	-- Enter toggles the pop-up, closing it here. Update the chosen selection.
	elseif scancode == "return" or scancode == "kpenter" then
		self:_closeSelf(true)
		return true
	end
end


function def:uiCall_pointerDrag(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		local rolled = false

		if self.press_busy == "menu-drag" then

			-- Implement Drag-to-select.
			-- Need to test the full range of items because the mouse can drag outside the bounds of the viewport.

			-- Mouse position relative to viewport #1
			local mx, my = self:getRelativePosition(mouse_x, mouse_y)

			-- test: Only update the selection via dragging if the mouse is within range horizontally.
			--if mx >= 0 and mx < self.w then
				mx = mx - self.vp_x
				my = my - self.vp_y

				local item_i, item_t = self:getItemAtPoint(mx + self.scr_x, my + self.scr_y, 1, #self.MN_items)
				if item_i and item_t.selectable then
					self:menuSetSelectedIndex(item_i)

				else
					self:menuSetSelectedIndex(0)
				end
			--end
		end
	end
end


function def:uiCall_pointerHover(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		local mx, my = self:getRelativePosition(mouse_x, mouse_y)

		lgcScroll.widgetProcessHover(self, mx, my)

		local xx = mx + self.scr_x - self.vp_x
		local yy = my + self.scr_y - self.vp_y

		if widShared.pointInViewport(self, 2, mx, my) then
			-- Update item hover
			local i, item = self:getItemAtPoint(xx, yy, math.max(1, self.MN_items_first), math.min(#self.MN_items, self.MN_items_last))

			if item and item.selectable then
				self.MN_item_hover = item

				--print("item", item, "MN_index", self.MN_index, "xx|yy", xx, yy, "item.xywh", item.x, item.y, item.w, item.h)

				-- Implement mouse hover-to-select.
				if (mouse_dx ~= 0 or mouse_dy ~= 0) then
					local selected_item = self.MN_items[self.MN_index]
					if item ~= selected_item then
						self:menuSetSelectedIndex(i)
					end
				end
			end
		end
	end
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		lgcScroll.widgetClearHover(self)
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self == inst then
		local mx, my, ax, ay = self:getRelativePosition(x, y)

		if self.is_blocking_clicks then
			if not (mx >= 0 and my >= 0 and mx < self.w and my < self.h) then
				local root = self:getRootWidget()
				root:sendEvent("rootCall_destroyPopUp", self, "concluded")
				return
			end
		end

		local handled_scroll_bars

		-- Check for pressing on scroll bar components.
		if button == 1 then
			local fixed_step = 24 -- XXX style/config
			handled_scroll_bars = lgcScroll.widgetScrollPress(self, x, y, fixed_step)
		end

		-- Successful mouse interaction with scroll bars should break any existing click-sequence.
		if handled_scroll_bars then
			self.context:clearClickSequence()
		else
			if widShared.pointInViewport(self, 2, mx, my) then

				x = x - ax + self.scr_x - self.vp_x
				y = y - ay + self.scr_y - self.vp_y

				-- Check for click-able items.
				if not self.press_busy then
					local item_i, item_t = self:trySelectItemAtPoint(x, y, math.max(1, self.MN_items_first), math.min(#self.MN_items, self.MN_items_last))

					self.press_busy = "menu-drag"
					self:cacheUpdate()
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


function def:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)
	if self == inst
	and button == self.context.mouse_pressed_button
	then
		lgcScroll.widgetClearPress(self)

		local old_press_busy = self.press_busy
		self.press_busy = false

		if old_press_busy == "menu-drag" then
			-- Handle mouse unpressing over the selected item.
			if button == 1 then
				local item_selected = self.MN_items[self.MN_index]

				if item_selected and item_selected.selectable then
					self:_closeSelf(true)
					return true
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

		if widShared.checkScrollWheelScroll(self, x, y) then
			self:cacheUpdate()
			return true
		end
	end
end


function def:uiCall_update(dt)
	-- This widget cannot operate if the owner that it extends is gone.
	local wid_ref = self.wid_ref
	if not wid_ref then
		self:remove()
		return
	end

	local scr_x_old, scr_y_old = self.scr_x, self.scr_y

	local needs_update = false

	-- Handle update-time drag-scroll.
	if self.press_busy == "menu-drag" and widShared.dragToScroll(self, dt) then
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
		self:cacheUpdate()
	end
end


function def:uiCall_destroy(inst)
	if self == inst then
		self:_closeSelf(false)
	end
end


local check, change = uiTheme.check, uiTheme.change


def.default_skinner = {
	validate = function(skin)
		check.box(skin, "box")
		check.loveType(skin, "font", "Font")
		check.scrollBarData(skin, "data_scroll")
		check.scrollBarStyle(skin, "scr_style")

		check.exact(skin, "text_align", "left", "center", "right")

		check.exact(skin, "icon_side", "left", "right")
		check.integer(skin, "icon_spacing", 0)

		check.integer(skin, "item_height", 0)
		check.integer(skin, "item_pad_v", 0)

		-- The drawer's maximum height, as measured by the number of visible items (plus margins).
		-- Drawer height is limited by the size of the application window.
		check.integer(skin, "max_visible_items")

		check.slice(skin, "slice")
		check.colorTuple(skin, "color_body")
		check.colorTuple(skin, "color_text")
		check.colorTuple(skin, "color_selected")
	end,


	transform = function(skin, scale)
		change.integerScaled(skin, "icon_spacing", scale)
		change.integerScaled(skin, "item_height", scale)
		change.integerScaled(skin, "item_pad_v", scale)
	end,


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)
		-- Update the scroll bar style
		self:setScrollBars(self.scr_h, self.scr_v)

		-- Fix item dimensions, icon references, etc.
		self:menuChangeCleanup()
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	--refresh = function(self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		local skin = self.skin
		local font = skin.font
		local items = self.MN_items

		love.graphics.push("all")

		local old_r, old_g, old_b, old_a = love.graphics.getColor()

		uiGraphics.intersectScissor(ox + self.x, oy + self.y, self.w, self.h)

		-- Back panel body.
		love.graphics.setColor(skin.color_body)
		uiGraphics.drawSlice(skin.slice, 0, 0, self.w, self.h)

		lgcScroll.drawScrollBarsV(self, self.skin.data_scroll)

		-- Scroll offsets.
		--love.graphics.translate(-self.scr_x + self.vp_x, -self.scr_y + self.vp_y)
		love.graphics.translate(-self.scr_x, -self.scr_y)
		uiGraphics.intersectScissor(ox + self.x + self.vp_x, oy + self.y + self.vp_y, self.vp_w, self.vp_h)

		-- Dropdown drawers do not render hover-glow.

		-- Selection glow.
		local selected_item = self.MN_items[self.MN_index]
		if selected_item then
			love.graphics.setColor(skin.color_selected)
			love.graphics.rectangle("fill", 0, selected_item.y, self.vp3_w, selected_item.h)
		end


		local i_min, i_max = math.max(1, self.MN_items_first), math.min(#items, self.MN_items_last)

		-- Item icons.
		if self.vp5_w > 0 then
			love.graphics.setColor(old_r, old_g, old_b, old_a)
			for i = i_min, i_max do
				local item = items[i]
				local tq_icon = item.tq_icon
				if tq_icon then
					uiGraphics.quadShrinkOrCenterXYWH(tq_icon, self.vp5_x, item.y + self.vp5_y, self.vp5_w, self.vp5_h)
				end
			end
		end

		-- Item text.
		love.graphics.setColor(skin.color_text)
		love.graphics.setFont(font)

		for i = i_min, i_max do
			local item = items[i]
			local xx = self.vp4_x + textUtil.getAlignmentOffset(item.text, font, skin.text_align, self.vp4_w)
			love.graphics.print(item.text, xx, item.y)
		end

		love.graphics.pop()

		-- Debug: draw viewports
		--[[
		widShared.debug.debugDrawViewport(self, 1)
		widShared.debug.debugDrawViewport(self, 2)
		widShared.debug.debugDrawViewport(self, 3)
		widShared.debug.debugDrawViewport(self, 4)
		widShared.debug.debugDrawViewport(self, 5)
		--]]
	end,


	--renderLast = function(self, ox, oy) end,


	renderThimble = function(self, ox, oy)
		-- Don't render thimble focus.
	end
}


return def
