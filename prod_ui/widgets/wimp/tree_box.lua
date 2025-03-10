
--[[
A WIMP TreeBox.

 ┌──────────────────────────┬─┐
 │   [B] Leaf               │^│ <──
 │ > [B] Node               ├─┤ <──
 │ v [B] Node               │ │ <── Items
 │       [B] Leaf           │ │ <──
 │    v  [B] Node           │ │ <──
 │          [B] Leaf        ├─┤ <──
 │   [B] Leaf               │v│ <──
 ├─┬──────────────────────┬─┼─┤
 │<│                      │>│ │
 └─┴──────────────────────┴─┴─┘
                             ^
                             │
                   Optional scroll bars

 [B]: Optional icons (bijoux)
 >/v: Optional expander sensors
--]]


local context = select(1, ...)


local commonScroll = require(context.conf.prod_ui_req .. "common.common_scroll")
local commonTree = require(context.conf.prod_ui_req .. "common.common_tree")
local lgcMenu = context:getLua("shared/lgc_menu")
local structTree = require(context.conf.prod_ui_req .. "common.struct_tree")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "tree_box1",

	default_settings = {
		TR_item_align_h = "left", -- start edge for the tree root. "left", "right"
		TR_expanders_active = false,
		TR_show_icons = false,
	},
}


lgcMenu.attachMenuMethods(def)
widShared.scrollSetMethods(def)
def.setScrollBars = commonScroll.setScrollBars
def.impl_scroll_bar = context:getLua("shared/impl_scroll_bar1")


def.arrangeItems = commonTree.arrangeItems


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
-- @param item The current selected item, or nil if no item is selected.
-- @param item_i Index of the current selected item, or zero if no item is selected.
function def:wid_action(item, item_i)

end


--- Called when the user right-clicks on the widget or presses "application" or shift+F10.
-- @param item The current selected item, or nil if no item is selected.
-- @param item_i Index of the current selected item, or zero if no item is selected.
function def:wid_action2(item, item_i)

end


--- Called when the user middle-clicks on the widget.
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


def.wid_defaultKeyNav = commonTree.wid_defaultKeyNav


def.setIconsEnabled = commonTree.setIconsEnabled
def.setExpandersActive = commonTree.setExpandersActive
def.setItemAlignment = commonTree.setItemAlignment
def.addNode = commonTree.addNode
def.orderItems = commonTree.orderItems
def.removeNode = commonTree.removeNode


function def:setSelection(item_t)
	uiShared.type1(1, item_t, "table")

	local item_i = self:menuGetItemIndex(item_t)
	self:setSelectionByIndex(item_i)
end


function def:setSelectionByIndex(item_i)
	uiShared.intGE(1, item_i, 0)

	local old_index = self.index
	self:menuSetSelectedIndex(item_i)
	if old_index ~= self.index then
		self:wid_select(self.items[self.index], self.index)
	end
end


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true
	self.can_have_thimble = true

	widShared.setupDoc(self)
	widShared.setupScroll(self, -1, -1)
	widShared.setupViewports(self, 2)

	self.press_busy = false

	lgcMenu.setup(self, nil, true, true) -- with mark and drag+drop state
	self.MN_wrap_selection = false

	commonTree.instanceSetup(self)
	self.tree = structTree.new()

	-- State flags.
	self.enabled = true

	self:skinSetRefs()
	self:skinInstall()
	self:applyAllSettings()
end


function def:uiCall_reshapeInner2()
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

	self:cacheUpdate(true)
end


--- Updates cached display state.
-- @param refresh_dimensions When true, update doc_w and doc_h based on the combined dimensions of all items.
-- @return Nothing.
function def:cacheUpdate(refresh_dimensions)
	local skin = self.skin

	if refresh_dimensions then
		self.doc_w, self.doc_h = 0, 0

		commonTree.updateAllItemDimensions(self, self.skin, self.tree)

		-- Document height is based on the last item in the menu.
		local last_item = self.items[#self.items]
		if last_item then
			self.doc_h = last_item.y + last_item.h
		end

		-- Document width is the rightmost visible item, or the viewport width, whichever is larger.
		for i, item in ipairs(self.items) do
			self.doc_w = math.max(self.doc_w, item.x + item.w)
		end
		self.doc_w = math.max(self.doc_w, self.vp_w)

		-- Get component widths.
		self.TR_expander_w = self.TR_expanders_active and skin.first_col_spacing or 0
		self.TR_icon_w = self.TR_show_icons and skin.icon_spacing or 0

		-- Get component left positions. (These numbers assume left alignment, and are
		-- adjusted at render time for right alignment.)
		local xx = 0
		self.TR_expander_x = xx
		xx = self.TR_expander_x + skin.first_col_spacing

		self.TR_icon_x = xx
		xx = xx + self.TR_icon_w

		self.TR_text_x = xx
	end

	-- Set the draw ranges for items.
	lgcMenu.widgetAutoRangeV(self)
end


function def:uiCall_keyPressed(inst, key, scancode, isrepeat)
	if self == inst then
		local items = self.items
		local old_index = self.index
		local old_item = items[old_index]

		-- wid_action() is handled in the 'thimbleAction()' callback.

		if self.MN_mark_mode == "toggle" and key == "space" then
			if old_index > 0 and self:menuCanSelect(old_index) then
				self:menuToggleMarkedItem(self.items[old_index])
				return true
			end

		elseif self:wid_keyPressed(key, scancode, isrepeat)
		or self:wid_defaultKeyNav(key, scancode, isrepeat)
		then
			if old_item ~= items[self.index] then
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
				self:wid_select(items[self.index], self.index)
			end
			return true
		end
	end
end


function def:uiCall_pointerHover(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		local mx, my = self:getRelativePosition(mouse_x, mouse_y)

		commonScroll.widgetProcessHover(self, mx, my)

		local hover_ok = false

		if widShared.pointInViewport(self, 2, mx, my) then
			mx = mx + self.scr_x
			my = my + self.scr_y

			-- Update item hover
			local i, item = self:getItemAtPoint(mx, my, math.max(1, self.MN_items_first), math.min(#self.items, self.MN_items_last))

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


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		commonScroll.widgetClearHover(self)
		self.MN_item_hover = false
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self == inst
	and self.enabled
	and button == self.context.mouse_pressed_button
	then
		if button <= 3 then
			self:tryTakeThimble1()
		end

		if not lgcMenu.pointerPressScrollBars(self, x, y, button) then
			local mx, my = self:getRelativePosition(x, y)

			if widShared.pointInViewport(self, 2, mx, my) then
				mx = mx + self.scr_x
				my = my + self.scr_y

				local item_i, item_t = lgcMenu.checkItemIntersect(self, mx, my, button)

				if item_t and item_t.selectable then
					local old_index = self.index
					local old_item = self.items[old_index]

					-- Button 1 selects an item only if the mouse didn't land on an expander sensor.
					-- Buttons 2 and 3 always select an item.
					-- Only button 1 updates the item mark state.

					-- First, check for clicking on an expander sensor.
					local clicked_expander = false
					if button == 1 then
						local skin = self.skin
						local ex_x, ex_w = self.TR_expander_x, self.TR_expander_w
						local it_x, it_w = item_t.x, item_t.w

						if self.TR_expanders_active
						and #item_t.nodes > 0
						and (self.TR_item_align_h == "left" and mx >= it_x + ex_x and mx < it_x + ex_x + ex_w)
						or (self.TR_item_align_h == "right" and mx >= it_x + it_w - ex_x - ex_w and mx < it_x + it_w - ex_x)
						then
							commonTree.setExpanded(self, item_t, not item_t.expanded)

							clicked_expander = true
						end
					end

					if button <= 3 then
						if not clicked_expander then
							lgcMenu.widgetSelectItemByIndex(self, item_i)
							self.MN_mouse_clicked_item = item_t
							if button == 1 then
								lgcMenu.pointerPressButton1(self, item_t, old_index)
							end
						end

						if old_item ~= item_t then
							self:wid_select(item_t, item_i)
						end
					end

					-- TODO: fix selections and marked items when items are no longer visible.

					-- Button 1 clicks that did not land on the expander buttons initiate click-drag.
					if button == 1 and not clicked_expander then
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
		commonScroll.widgetClearPress(self)
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


function def:uiCall_thimbleAction(inst, key, scancode, isrepeat)
	if self == inst
	and self.enabled
	then
		local index = self.index
		local item = self.items[index]

		self:wid_action(item, index)

		return true -- Stop bubbling.
	end
end


function def:uiCall_thimbleAction2(inst, key, scancode, isrepeat)
	if self == inst
	and self.enabled
	then
		local index = self.index
		local item = self.items[index]

		self:wid_action2(item, index)

		return true -- Stop bubbling.
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
		self:cacheUpdate(false)
	end
end


def.default_skinner = {
	schema = {
		item_pad_v = "scaled-int",
		first_col_spacing = "scaled-int",
		indent = "scaled-int",
		pipe_width = "scaled-int",
		icon_spacing = "scaled-int",
		pad_icon_x = "scaled-int",
		pad_text_x = "scaled-int",
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
		local data_icon = skin.data_icon

		local tq_px = skin.tq_px
		local sl_body = skin.sl_body

		local items = self.items

		local font = skin.font
		local font_h = font:getHeight()

		local first = math.max(self.MN_items_first, 1)
		local last = math.min(self.MN_items_last, #items)

		-- XXX: pick resources for enabled or disabled state, etc.
		--local res = (self.active) and skin.res_active or skin.res_inactive

		-- TreeBox body
		love.graphics.setColor(1, 1, 1, 1)
		uiGraphics.drawSlice(sl_body, 0, 0, self.w, self.h)

		commonScroll.drawScrollBarsHV(self, self.skin.data_scroll)

		love.graphics.push("all")

		-- Scissor, scroll offsets for content.
		uiGraphics.intersectScissor(ox + self.x + self.vp2_x, oy + self.y + self.vp2_y, self.vp2_w, self.vp2_h)
		love.graphics.translate(-self.scr_x, -self.scr_y)

		-- Vertical pipes.
		if skin.draw_pipes then
			love.graphics.setColor(skin.color_pipe)
			local line_x_offset, dir_h
			if self.TR_item_align_h == "left" then
				line_x_offset = math.floor((skin.first_col_spacing - skin.pipe_width) / 2)
				dir_h = 1
			else -- "right"
				line_x_offset = math.floor(self.doc_w - (skin.first_col_spacing  - skin.pipe_width) / 2)
				dir_h = -1
			end

			for i = first, last do
				local item = items[i]
				for j = 0 , item.depth - 1 do
					uiGraphics.quadXYWH(tq_px,
						line_x_offset + skin.indent * j * dir_h,
						item.y,
						skin.pipe_width,
						item.h
					)
				end
				-- draw the final pipe if there is no expander sensor in the way
				-- [[
				if not self.TR_expanders_active or #item.nodes == 0 then
					uiGraphics.quadXYWH(tq_px,
						line_x_offset + skin.indent * item.depth * dir_h,
						item.y,
						skin.pipe_width,
						item.h
					)
				end
				--]]
			end
		end

		-- Hover glow.
		local item_hover = self.MN_item_hover
		if item_hover then
			love.graphics.setColor(skin.color_hover_glow)
			if self.TR_item_align_h == "left" then
				uiGraphics.quadXYWH(
					tq_px,
					item_hover.x + skin.first_col_spacing,
					item_hover.y,
					math.max(self.vp_w, self.doc_w) - item_hover.x,
					item_hover.h
				)
			else -- "right"
				uiGraphics.quadXYWH(
					tq_px,
					self.vp_x,
					item_hover.y,
					-self.vp_x + item_hover.x + item_hover.w - skin.first_col_spacing,
					item_hover.h
				)
			end
			--[[
			love.graphics.push("all")
			love.graphics.setColor(1,0,0,1)
			love.graphics.rectangle("line", item_hover.x, item_hover.y, item_hover.w, item_hover.h)
			love.graphics.pop()
			--]]
		end

		-- Selection glow.
		local sel_item = items[self.index]
		if sel_item then
			local is_active = self == self.context.thimble1
			local col = is_active and skin.color_active_glow or skin.color_select_glow
			love.graphics.setColor(col)

			if self.TR_item_align_h == "left" then
				uiGraphics.quadXYWH(
					tq_px,
					sel_item.x + skin.first_col_spacing,
					sel_item.y,
					math.max(self.vp_w, self.doc_w) - sel_item.x, sel_item.h
				)
			else -- "right"
				uiGraphics.quadXYWH(
					tq_px,
					self.vp_x,
					sel_item.y,
					-self.vp_x + sel_item.x + sel_item.w - skin.first_col_spacing,
					sel_item.h
				)
			end
		end


		-- Menu items.
		love.graphics.setColor(skin.color_item_text)
		love.graphics.setFont(font)

		-- 1: Item markings
		local rr, gg, bb, aa = love.graphics.getColor()
		love.graphics.setColor(skin.color_item_marked)

		for i = first, last do
			local item = items[i]
			if item.marked then
				uiGraphics.quadXYWH(tq_px, item.x, item.y, math.max(self.vp_w, self.doc_w) - item.x, item.h)
			end
		end

		love.graphics.setColor(rr, gg, bb, aa)

		-- 2: Expander sensors, if enabled.
		if self.TR_expanders_active then
			local tq_on = skin.tq_expander_down
			local tq_off = (self.TR_item_align_h == "left") and skin.tq_expander_right or skin.tq_expander_left

			for i = first, last do
				local item = items[i]

				if #item.nodes > 0 then
					local tq_expander = item.expanded and tq_on or tq_off
					if tq_expander then
						local item_x
						if self.TR_item_align_h == "left" then
							item_x = item.x + self.TR_expander_x
						else -- "right"
							item_x = item.x + item.w - self.TR_expander_x - self.TR_expander_w
						end

						uiGraphics.quadShrinkOrCenterXYWH(tq_expander, item_x, item.y, self.TR_expander_w, item.h)
					end
				end
			end
		end


		-- 3: Bijou icons, if enabled
		if self.TR_show_icons then
			for i = first, last do
				local item = items[i]
				local tq_bijou = item.tq_bijou
				if tq_bijou then
					local item_x
					if self.TR_item_align_h == "left" then
						item_x = item.x + self.TR_icon_x
					else -- "right"
						item_x = item.x + item.w - self.TR_icon_x - self.TR_icon_w
					end

					uiGraphics.quadShrinkOrCenterXYWH(tq_bijou, item_x, item.y, self.TR_icon_w, item.h)
				end
			end
		end

		-- 4: Text labels
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
				local item_x
				if self.TR_item_align_h == "left" then
					item_x = item.x + self.TR_text_x
				else -- "right"
					item_x = item.x + item.w - self.TR_text_x - font:getWidth(item.text)
					-- XXX: Maybe cache text width in each item table?
				end
				love.graphics.print(
					item.text,
					item_x,
					item.y + math.floor((item.h - font_h) * 0.5)
				)
			end
		end

		love.graphics.pop()
	end,

	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy) end,
}


return def
