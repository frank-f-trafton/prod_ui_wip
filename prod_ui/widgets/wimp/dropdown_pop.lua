
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
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "dropdown_pop1",

	default_settings = {
		icon_side = "left", -- "left", "right"
		show_icons = false,
		text_align_h = "left", -- "left", "center", "right"
		icon_set_id = false, -- lookup for 'resources.icons[icon_set_id]'
	}
}


lgcMenu.attachMenuMethods(def)
widShared.scrollSetMethods(def)
def.setScrollBars = commonScroll.setScrollBars
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


function def:_shapeItem(item)
	local skin = self.skin
	local font = skin.font

	item.w = font:getWidth(item.text)
	item.h = math.floor((font:getHeight() * font:getLineHeight()) + skin.item_pad_v)

	lgcMenu.updateItemIcon(self, item)
end


function def:_closeSelf(update_chosen)
	if not self._dead then
		local wid_ref = self.wid_ref
		if wid_ref and not wid_ref._dead then
			wid_ref.wid_drawer = false

			if update_chosen then
				wid_ref:setSelectionByIndex(self.index, "chosen_i")
			end
		end

		local root = self:getRootWidget()
		if root.pop_up_menu == self then
			root:sendEvent("rootCall_destroyPopUp", self, "concluded")
		end
	end
end


def.keepInBounds = widShared.keepInBoundsOfParent


function def:menuChangeCleanup()
	for i, item in ipairs(self.items) do
		self:_shapeItem(item)
	end

	self:menuSetSelectionStep(0, false)
	self:arrangeItems()
	self:cacheUpdate(true)
	self:scrollClampViewport()
	self:selectionInView(true)
end


def.setIconSetID = lgcMenu.setIconSetID
def.getIconSetID = lgcMenu.getIconSetID


function def:uiCall_initialize()
	if not self.wid_ref then
		error("no owner widget assigned to this menu.")

	elseif not self.items then
		error("owner widget did not provide a table of menu items.")
	end

	self.visible = true
	self.allow_hover = true
	self.clip_scissor = true

	self.sort_id = 7

	widShared.setupDoc(self)
	widShared.setupScroll(self, -1, -1)
	widShared.setupViewports(self, 4)

	self.press_busy = false

	lgcMenu.setup(self, self.items) -- 'items' was set by invoker

	self.MN_wrap_selection = false

	self:skinSetRefs()
	self:skinInstall()

	self:setScrollBars(false, true)

	-- Set up the widget's position, then call reshape() and menuChangeCleanup().
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
	-- Item dimensions must be up to date before calling.
	local widest_item_width = 0
	for i, item in ipairs(self.items) do
		widest_item_width = math.max(widest_item_width, item.w)
	end

	self.w = math.min(root.w, math.max(wid_ref.w, widest_item_width))
	self.h = math.min(root.h, (skin.item_height * math.min(skin.max_visible_items, #self.items)))

	self:keepInBounds()

	widShared.resetViewport(self, 1)

	-- Border and scroll bars.
	widShared.carveViewport(self, 1, skin.box.border)
	commonScroll.arrangeScrollBars(self)

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
	commonScroll.updateScrollState(self)

	self:cacheUpdate()

	return true
end


--- Updates cached display state.
-- @param refresh_dimensions When true, update doc_w and doc_h based on the combined dimensions of all items.
-- @return Nothing.
function def:cacheUpdate(refresh_dimensions)
	if refresh_dimensions then
		self.doc_w, self.doc_h = lgcMenu.getCombinedItemDimensions(self.items)
	end

	-- Set the draw ranges for items.
	lgcMenu.widgetAutoRangeV(self)
end


-- Used instead of 'uiCall_keypressed'. The dropdown body passes keyboard events through here.
function def:wid_forwardKeyPressed(key, scancode, isrepeat) -- XXX: WIP
	local root = self:getRootWidget()

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

				local item_i, item_t = self:getItemAtPoint(mx + self.scr_x, my + self.scr_y, 1, #self.items)
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

		commonScroll.widgetProcessHover(self, mx, my)

		local xx = mx + self.scr_x - self.vp_x
		local yy = my + self.scr_y - self.vp_y

		if widShared.pointInViewport(self, 2, mx, my) then
			-- Update item hover
			local i, item = self:getItemAtPoint(xx, yy, math.max(1, self.MN_items_first), math.min(#self.items, self.MN_items_last))

			if item and item.selectable then
				self.MN_item_hover = item

				--print("item", item, "index", self.index, "xx|yy", xx, yy, "item.xywh", item.x, item.y, item.w, item.h)

				-- Implement mouse hover-to-select.
				if (mouse_dx ~= 0 or mouse_dy ~= 0) then
					local selected_item = self.items[self.index]
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
					local item_i, item_t = self:trySelectItemAtPoint(x, y, math.max(1, self.MN_items_first), math.min(#self.items, self.MN_items_last))

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
				local item_selected = self.items[self.index]

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

		love.graphics.push("all")

		local old_r, old_g, old_b, old_a = love.graphics.getColor()

		uiGraphics.intersectScissor(ox + self.x, oy + self.y, self.w, self.h)

		-- Back panel body.
		love.graphics.setColor(skin.color_body)
		uiGraphics.drawSlice(skin.slice, 0, 0, self.w, self.h)

		commonScroll.drawScrollBarsV(self, self.skin.data_scroll)

		-- Scroll offsets.
		--love.graphics.translate(-self.scr_x + self.vp_x, -self.scr_y + self.vp_y)
		love.graphics.translate(-self.scr_x, -self.scr_y)
		uiGraphics.intersectScissor(ox + self.x + self.vp_x, oy + self.y + self.vp_y, self.vp_w, self.vp_h)

		-- Dropdown drawers do not render hover-glow.

		-- Selection glow.
		local selected_item = self.items[self.index]
		if selected_item then
			love.graphics.setColor(skin.color_selected)
			love.graphics.rectangle("fill", 0, selected_item.y, self.vp3_w, selected_item.h)
		end

		local i_min, i_max = math.max(1, self.MN_items_first), math.min(#self.items, self.MN_items_last)
		local items = self.items

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
	--renderThimble = function(self, ox, oy) -- (This widget can't take the thimble.)
}


return def
