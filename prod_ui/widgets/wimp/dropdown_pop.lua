
--[[
wimp/dropdown_pop: The pop-up (or "drawer") component of a dropdown menu.

'self.wid_ref' points to the invoking dropdown base widget.

These are not real OS widgets, so they are limited to the boundaries of the window.
They may act strangely if the window is too small for the menu contents.

See `wimp/dropdown_box.lua` for more notes.
--]]


local context = select(1, ...)


local commonScroll = require(context.conf.prod_ui_req .. "common.common_scroll")
local lgcMenu = context:getLua("shared/lgc_menu")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = require(context.conf.prod_ui_req .. "common.wid_shared")


local def = {
	skin_id = "dropdown_pop1",
	click_repeat_oob = true, -- Helps with integrated scroll bar buttons
}


widShared.scrollSetMethods(def)
def.setScrollBars = commonScroll.setScrollBars
def.impl_scroll_bar = context:getLua("shared/impl_scroll_bar1")
def.arrange = lgcMenu.arrangeListVerticalTB


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


function def:_closeSelf(update_chosen)
	if not self._dead then
		local wid_ref = self.wid_ref
		if wid_ref and not wid_ref._dead then
			wid_ref.wid_drawer = false

			if update_chosen then
				wid_ref:setSelectionByIndex(self.menu.index, "chosen_i")
			end
		end

		local root = self:getTopWidgetInstance()
		if root.pop_up_menu == self then
			root:sendEvent("rootCall_destroyPopUp", self, "concluded")
		end
	end
end


--[=[
--- Changes the widget dimensions based on its menu contents.
function def:updateDimensions()

	--[[
	We need to:

	* Handle vertical item layout
	* Calculate item width by finding the widest single item
	* Reshape the widget to correctly set viewport rectangles
	* Set the width of all items to the width of viewport #1, and then reshape all items
	--]]
	-- XXX: We will just be using the maximum of (dropdown_box.w, widest item).

	local skin = self.skin
	local menu = self.menu
	local items = menu.items

	local font = skin.font_item

	-- Update item heights.
	for i, item in ipairs(items) do

		local font = skin.font_item

		local text_h, bijou_h = 1, 1
		text_h = font:getHeight() + self.pad_text_y1 + self.pad_text_y2
		if self.bijou then
			bijou_h = self.pad_bijou_y1 + self.bijou_draw_h + self.pad_bijou_y2
		end

		item.h = math.max(text_h, bijou_h)
	end

	-- Arrange the items vertically.
	self:arrange()

	-- The work-in-progress widget dimensions.
	local w = 1
	local h = items and (items[#items].y + items[#items].h) or 1

	print("#items", #items, "h", h, "items[#items].y", items[#items].y, "items[#items].h", items[#items].h)

	-- Find the widest item text.
	local w_text = 0
	for i, item in ipairs(items) do
		if item.text_int then
			w_text = math.max(w_text, font:getWidth(item.text_int))
		end
	end
	w = (
		self.pad_bijou_x1 +
		self.bijou_draw_w +
		self.pad_bijou_x2 +
		self.pad_text_x1 +
		w_text +
		self.pad_text_x2
	)

	-- (We assume that the top-level widget's dimensions match the display area.)
	local wid_top = self:getTopWidgetInstance()

	self.w = math.min(w, wid_top.w)
	self.h = math.min(h, wid_top.h)

	self:reshape()

	-- Update item widths and then reshape their internals.
	for i, item in ipairs(self.menu.items) do
		item.w = self.vp_w
		item:reshape(self)
	end

	-- Refresh document size.
	self.doc_w, self.doc_h = lgcMenu.getCombinedItemDimensions(menu.items)

	print(
		"self.w", self.w,
		"self.h", self.h,
		"self.vp_w", self.vp_w,
		"self.vp_h", self.vp_h,
		"self.doc_w", self.doc_w,
		"self.doc_h", self.doc_h
	)
end
--]=]


def.keepInBounds = widShared.keepInBoundsOfParent


function def:menuChangeCleanup()
	self.menu:setSelectionStep(0, false)
	self:arrange()
	self:cacheUpdate(true)
	self:scrollClampViewport()
	self:selectionInView(true)
end


function def:uiCall_create(inst)
	if self == inst then
		if not self.wid_ref then
			error("no owner widget assigned to this menu.")

		elseif not self.menu then
			error("owner widget did not provide a menu sub-table.")
		end

		self.visible = true
		self.allow_hover = true
		self.clip_scissor = true

		self.sort_id = 6

		widShared.setupDoc(self)
		widShared.setupScroll(self)
		widShared.setupViewports(self, 2)

		self.press_busy = false

		lgcMenu.instanceSetup(self)

		self.MN_wrap_selection = false

		-- Padding values. -- XXX style/config, scale
		--[[
		self.pad_bijou_x1 = 2
		self.pad_bijou_x2 = 2
		self.pad_bijou_y1 = 2
		self.pad_bijou_y2 = 2
		--]]

		-- Drawing offsets and size for bijou quads.
		--[[
		self.bijou_draw_w = 24
		self.bijou_draw_h = 24
		--]]

		-- Padding above and below text and bijoux in items.
		-- The tallest of the two components determines the item's height.
		--[[
		self.pad_text_x1 = 4
		self.pad_text_x2 = 4
		self.pad_text_y1 = 4
		self.pad_text_y2 = 4
		--]]

		self:skinSetRefs()
		self:skinInstall()

		self:setScrollBars(false, true)

		-- Set up the widget's position, then call reshape() and then menuChangeCleanup().
	end
end


function def:uiCall_resize()
	local skin = self.skin
	local menu = self.menu
	local wid_ref = self.wid_ref
	local root = self:getTopWidgetInstance()

	if not wid_ref or wid_ref._dead then
		return
	end

	-- We assume that the root widget's dimensions match the display area.
	-- Item dimensions must be up-to-date before calling.
	local widest_item_width = 0
	for i, item in ipairs(menu.items) do
		widest_item_width = math.max(widest_item_width, item.w)
	end

	self.w = math.min(root.w, math.max(wid_ref.w, widest_item_width))
	self.h = math.min(root.h, (skin.item_height * math.min(skin.max_visible_items, #menu.items)))

	self:keepInBounds()
end


function def:uiCall_reshape()
	-- Viewport #1 is the main content viewport.
	-- Viewport #2 separates embedded controls (scroll bars) from the content.

	local skin = self.skin

	widShared.resetViewport(self, 1)

	-- Border and scroll bars.
	widShared.carveViewport(self, 1, skin.box.border)
	commonScroll.arrangeScrollBars(self)

	-- 'Okay-to-click' rectangle.
	widShared.copyViewport(self, 1, 2)

	-- Margin.
	widShared.carveViewport(self, 1, skin.box.margin)


	self:scrollClampViewport()
	commonScroll.updateScrollState(self)

	self:cacheUpdate()
end


--- Updates cached display state.
-- @param refresh_dimensions When true, update doc_w and doc_h based on the combined dimensions of all items.
-- @return Nothing.
function def:cacheUpdate(refresh_dimensions)
	local menu = self.menu

	if refresh_dimensions then
		self.doc_w, self.doc_h = lgcMenu.getCombinedItemDimensions(menu.items)
	end

	-- Set the draw ranges for items.
	lgcMenu.widgetAutoRangeV(self)
end


-- Used instead of 'uiCall_keypressed'. The dropdown body passes keyboard events through here.
function def:wid_forwardKeyPressed(key, scancode, isrepeat) -- XXX: WIP
	local root = self:getTopWidgetInstance()

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

	elseif scancode == "escape" then
		self:_closeSelf(false)
		return true

	-- Enter toggles the pop-up, closing it here. Update the chosen selection.
	elseif scancode == "return" or scancode == "kpenter" then
		self:_closeSelf(true)
		return true
	end
end


--function def:uiCall_pointerHoverOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)


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

				local item_i, item_t = self:getItemAtPoint(mx + self.scr_x, my + self.scr_y, 1, #self.menu.items)
				if item_i and item_t.selectable then
					self.menu:setSelectedIndex(item_i)

				else
					self.menu:setSelectedIndex(0)
				end
			--end
		end
	end
end


function def:uiCall_pointerHover(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		local mx, my = self:getRelativePosition(mouse_x, mouse_y)

		commonScroll.widgetProcessHover(self, mx, my)

		local xx = mx + self.scr_x - self.vp_x
		local yy = my + self.scr_y - self.vp_y

		if widShared.pointInViewport(self, 2, mx, my) then
			local menu = self.menu

			-- Update item hover
			local i, item = self:getItemAtPoint(xx, yy, math.max(1, self.MN_items_first), math.min(#menu.items, self.MN_items_last))

			if item and item.selectable then
				self.MN_item_hover = item

				--print("item", item, "index", menu.index, "xx|yy", xx, yy, "item.xywh", item.x, item.y, item.w, item.h)

				-- Implement mouse hover-to-select.
				if (mouse_dx ~= 0 or mouse_dy ~= 0) then
					local selected_item = self.menu.items[self.menu.index]
					if item ~= selected_item then
						self.menu:setSelectedIndex(i)
					end
				end
			end
		end
	end
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		commonScroll.widgetClearHover(self)
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self == inst then
		local ax, ay = self:getAbsolutePosition()
		local mouse_x = x - ax
		local mouse_y = y - ay

		local handled_scroll_bars

		-- Check for pressing on scroll bar components.
		if button == 1 then
			local fixed_step = 24 -- XXX style/config
			handled_scroll_bars = commonScroll.widgetScrollPress(self, x, y, fixed_step)
		end

		-- Successful mouse interaction with scroll bars should break any existing click-sequence.
		if handled_scroll_bars then
			self.context:clearClickSequence()
		else
			if widShared.pointInViewport(self, 2, mouse_x, mouse_y) then

				x = x - ax + self.scr_x - self.vp_x
				y = y - ay + self.scr_y - self.vp_y

				-- Check for click-able items.
				if not self.press_busy then
					local item_i, item_t = self:trySelectItemAtPoint(x, y, math.max(1, self.MN_items_first), math.min(#self.menu.items, self.MN_items_last))

					self.press_busy = "menu-drag"
					self:cacheUpdate(true)
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
		commonScroll.widgetClearPress(self)

		local old_press_busy = self.press_busy
		self.press_busy = false

		if old_press_busy == "menu-drag" then
			-- Handle mouse unpressing over the selected item.
			if button == 1 then
				local item_selected = self.menu.items[self.menu.index]

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
			self:cacheUpdate(false)
			return true
		end
	end
end


function def:uiCall_update(dt)
	-- This widget cannot operate if the owner which it extends is gone.
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

	elseif commonScroll.press_busy_codes[self.press_busy] then
		if self.context.mouse_pressed_ticks > 1 then
			local mx, my = self:getRelativePosition(self.context.mouse_x, self.context.mouse_y)
			local button_step = 350 -- XXX style/config
			commonScroll.widgetDragLogic(self, mx, my, button_step*dt)
		end
	end

	self:scrollUpdate(dt)

	-- Force a cache update if the external scroll position is different.
	if scr_x_old ~= self.scr_x or scr_y_old ~= self.scr_y then
		needs_update = true
	end

	-- Update scroll bar registers and thumb position.
	commonScroll.updateScrollBarShapes(self)
	commonScroll.updateScrollState(self)

	if needs_update then
		self:cacheUpdate(true)
	end
end


function def:uiCall_destroy(inst)
	if self == inst then
		self:_closeSelf(false)
	end
end


def.default_skinner = {
	schema = {
		item_height = "scaled-int",
	},

	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	--refresh = function(self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		local skin = self.skin
		local menu = self.menu

		local font = skin.font

		love.graphics.push("all")

		uiGraphics.intersectScissor(ox + self.x, oy + self.y, self.w, self.h)

		-- Back panel body.
		love.graphics.setColor(skin.color_body)
		uiGraphics.drawSlice(skin.slice, 0, 0, self.w, self.h)

		-- Embedded scroll bars, if present and active.
		local data_scroll = skin.data_scroll
		local scr_v = self.scr_v

		if scr_v and scr_v.active then
			self.impl_scroll_bar.draw(data_scroll, self.scr_v, 0, 0)
		end

		-- Scroll offsets.
		love.graphics.translate(-self.scr_x + self.vp_x, -self.scr_y + self.vp_y)

		-- Dropdown drawers do not render hover-glow.

		-- Selection glow.
		local selected_item = menu.items[menu.index]
		if selected_item then
			love.graphics.setColor(skin.color_selected)
			love.graphics.rectangle("fill", 0, selected_item.y, self.vp_w - self.vp_x, selected_item.h)
		end

		-- XXX: icons.

		-- Item text.
		love.graphics.setColor(skin.color_text)
		love.graphics.setFont(font)

		for i = math.max(1, self.MN_items_first), math.min(#menu.items, self.MN_items_last) do
			local item = menu.items[i]
			local xx = self.vp_x + textUtil.getAlignmentOffset(item.text, font, skin.text_align, self.vp_w)
			love.graphics.print(item.text, xx, item.y)
		end

		love.graphics.pop()
	end,


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy) -- (This widget can't take the thimble.)
}


return def
