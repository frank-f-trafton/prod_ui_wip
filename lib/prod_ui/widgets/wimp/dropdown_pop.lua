-- XXX: Unfinished. Copy of `wimp/menu_pop.lua`.

--[[
wimp/dropdown_pop: The pop-up (or "drawer") component of a dropdown menu.

'self.wid_ref' points to the invoking dropdown base widget.

These are not real OS widgets, so they are limited to the boundaries of the window.
They may act strangely if the window is too small for the menu contents.
--]]


local context = select(1, ...)


local commonMenu = require(context.conf.prod_ui_req .. "logic.common_menu")
local commonScroll = require(context.conf.prod_ui_req .. "logic.common_scroll")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = require(context.conf.prod_ui_req .. "logic.wid_shared")


local def = {
	skin_id = "dropdown_pop1",
}


widShared.scrollSetMethods(def)
def.arrange = commonMenu.arrangeListVerticalTB


local function selectItemColor(item, client, skin)

	if item.actionable then
		return skin.color_actionable

	elseif client.menu.items[client.menu.index] == item then
		return skin.color_selected

	else
		return skin.color_inactive
	end
end


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

	self.w = math.min(w + self.margin_x1 + self.margin_x2, wid_top.w)
	self.h = math.min(h + self.margin_y1 + self.margin_y2, wid_top.h)

	self:reshape()

	-- Update item widths and then reshape their internals.
	for i, item in ipairs(self.menu.items) do
		item.w = self.vp_w
		item:reshape(self)
	end

	-- Refresh document size.
	self.doc_w, self.doc_h = commonMenu.getCombinedItemDimensions(menu.items)

	print(
		"self.w", self.w,
		"self.h", self.h,
		"self.vp_w", self.vp_w,
		"self.vp_h", self.vp_h,
		"self.doc_w", self.doc_w,
		"self.doc_h", self.doc_h
	)
end


function def:keepInView()

	local parent = self.parent

	if parent then
		self.x = math.max(0, math.min(self.x, parent.w - self.w))
		self.y = math.max(0, math.min(self.y, parent.h - self.h))
	end
end


-- * Scroll helpers *


def.getInBounds = commonMenu.getItemInBoundsRect
def.selectionInView = commonMenu.selectionInView


-- * Spatial selection *


def.getItemAtPoint = commonMenu.widgetGetItemAtPoint -- (<self>, px, py, first, last)
def.trySelectItemAtPoint = commonMenu.widgetTrySelectItemAtPoint -- (<self>, x, y, first, last)


-- * Selection movement *


def.movePrev = commonMenu.widgetMovePrev
def.moveNext = commonMenu.widgetMoveNext
def.moveFirst = commonMenu.widgetMoveFirst
def.moveLast = commonMenu.widgetMoveLast


function def:menuChangeCleanup()

	self.menu:setSelectionStep(0, false)
	self:arrange()
	self:cacheUpdate(true)
	self:scrollClampViewport()
	self:selectionInView()
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
		-- This widget does not take the thimble.
		-- The owner widget holds onto the thimble and forwards keyboard events through a callback.

		self.clip_scissor = true

		self.sort_id = 6

		widShared.setupDoc(self)
		widShared.setupScroll(self)
		widShared.setupViewport(self, 1)
		widShared.setupViewport(self, 2)

		self.press_busy = false

		-- Ref to currently-hovered item, or false if not hovering over any items.
		self.item_hover = false

		self.wheel_jump_size = 64 -- pixels

		-- Range of items that are visible and should be checked for press/hover state.
		self.items_first = 0 -- max(first, 1)
		self.items_last = 2^53 -- min(last, #items)

		-- Edge margin -- XXX style/config, scale
		self.margin_x1 = 4
		self.margin_x2 = 4
		self.margin_y1 = 4
		self.margin_y2 = 4

		-- Padding values. -- XXX style/config, scale
		self.pad_bijou_x1 = 2
		self.pad_bijou_x2 = 2
		self.pad_bijou_y1 = 2
		self.pad_bijou_y2 = 2

		-- Drawing offsets and size for bijou quads.
		self.bijou_draw_w = 24
		self.bijou_draw_h = 24

		-- Padding above and below text and bijoux in items.
		-- The tallest of the two components determines the item's height.
		self.pad_text_x1 = 4
		self.pad_text_x2 = 4
		self.pad_text_y1 = 4
		self.pad_text_y2 = 4

		-- Extends the selected item dimensions when scrolling to keep it within the bounds of the viewport.
		self.selection_extend_x = 0
		self.selection_extend_y = 0

		self:skinSetRefs()
		self:skinInstall()

		self:reshape()
		self:menuChangeCleanup()
	end
end


function def:uiCall_reshape()

	self.vp_x = 0
	self.vp_y = 0
	self.vp_w = self.w
	self.vp_h = self.h

	-- Apply edge padding
	self.vp_x = self.vp_x + self.margin_x1
	self.vp_y = self.vp_y + self.margin_y1
	self.vp_h = self.vp_h - (self.margin_y1 + self.margin_y2)
	self.vp_w = self.vp_w - (self.margin_x1 + self.margin_x2)

	self.vp2_x = self.vp_x
	self.vp2_y = self.vp_y
	self.vp2_w = self.vp_w
	self.vp2_h = self.vp_h

	self:cacheUpdate()
end


--- Updates cached display state.
-- @param refresh_dimensions When true, update doc_w and doc_h based on the combined dimensions of all items.
-- @return Nothing.
function def:cacheUpdate(refresh_dimensions)

	local menu = self.menu

	if refresh_dimensions then
		self.doc_w, self.doc_h = commonMenu.getCombinedItemDimensions(menu.items)
	end

	-- Set the draw ranges for items.
	commonMenu.widgetAutoRangeV(self)
end


--- The default navigational key input.
function def:wid_defaultKeyNav(key, scancode, isrepeat)

	local mod = self.context.key_mgr.mod

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
		self:movePrev(self.page_jump_size, true)
		return true

	elseif scancode == "pagedown" then
		self:moveNext(self.page_jump_size, true)
		return true
	end
end


-- Used instead of 'uiCall_keypressed'. The dropdown body passes keyboard events through here.
function def:wid_forwardKeyPressed(key, scancode, isrepeat) -- XXX: WIP

	local root = self:getTopWidgetInstance()

	-- Suppress stepping the thimble while a menu is open.
	if scancode == "tab" then
		return true

	elseif scancode == "escape" then
		root:runStatement("rootCall_destroyPopUp", self, "concluded")
		return true

	-- Enter toggles the pop-up, closing it here. Update the chosen selection.
	elseif scancode == "return" or scancode == "kpenter" then
		root:runStatement("rootCall_destroyPopUp", self, "concluded")
		return true
	end
end


function def:uiCall_pointerHoverOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)

	if self == inst then
		self:tryTakeThimble()
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
			mx = mx - self.vp_x
			my = my - self.vp_y

			local item_i, item_t = self:getItemAtPoint(mx + self.scr_x, my + self.scr_y, 1, #self.menu.items)
			if item_i and item_t.selectable then
				self.menu:setSelectedIndex(item_i)

			else
				self.menu:setSelectedIndex(0)
			end
		end
	end
end


local function findOriginItemIndex(c_prev, origin_item)

	for i, c_item in ipairs(c_prev.menu.items) do
		--print(i, c_item, #c_prev.menu.items)
		if c_item == origin_item then
			return i
		end
	end

	-- return nil
end


function def:uiCall_pointerHoverMove(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)

	if self == inst then
		local mx, my = self:getRelativePosition(mouse_x, mouse_y)
		local xx = mx + self.scr_x - self.vp_x
		local yy = my + self.scr_y - self.vp_y

		local hover_ok = false

		if not self.press_busy and widShared.pointInViewport(self, 2, mx, my) then

			local menu = self.menu

			-- Update item hover
			local i, item = self:getItemAtPoint(xx, yy, math.max(1, self.items_first), math.min(#menu.items, self.items_last))

			if item and item.selectable then
				-- Un-hover any existing hovered item
				if self.item_hover ~= item then

					self.item_hover = item
				end

				-- Implement mouse hover-to-select.
				if (mouse_dx ~= 0 or mouse_dy ~= 0) then
					local selected_item = self.menu.items[self.menu.index]
					if item ~= selected_item then
						self.menu:setSelectedIndex(i)
					end
				end

				hover_ok = true
			end
		end

		if self.item_hover and not hover_ok then
			self.item_hover = false
		end
	end
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)

	if self == inst then
		self.item_hover = false
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)

	if self == inst then
		if button <= 3 then
			self:tryTakeThimble()
		end

		local ax, ay = self:getAbsolutePosition()
		local mouse_x = x - ax
		local mouse_y = y - ay

		if widShared.pointInViewport(self, 2, mouse_x, mouse_y) then

			x = x - ax + self.scr_x - self.vp_x
			y = y - ay + self.scr_y - self.vp_y

			-- Check for click-able items.
			if not self.press_busy then
				local item_i, item_t = self:trySelectItemAtPoint(x, y, math.max(1, self.items_first), math.min(#self.menu.items, self.items_last))

				self.press_busy = "menu-drag"

				self:cacheUpdate(true)
			end
		end
	end
end


--function def:uiCall_pointerPressRepeat(inst, x, y, button, istouch, reps)


function def:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)

	if self == inst then
		if button == self.context.mouse_pressed_button then
			self.press_busy = false

			-- Handle mouse unpressing over the selected item.
			if button == 1 then
				local item_selected = self.menu.items[self.menu.index]
				if item_selected and item_selected.selectable and item_selected.actionable then

					local ax, ay = self:getAbsolutePosition()
					local mouse_x = x - ax
					local mouse_y = y - ay

					-- Apply scroll and viewport offsets
					local xx = mouse_x + self.scr_x - self.vp_x
					local yy = mouse_y + self.scr_y - self.vp_y

					-- XXX safety precaution: ensure mouse position is within widget viewport #2?
					if xx >= item_selected.x and xx < item_selected.x + item_selected.w
					and yy >= item_selected.y and yy < item_selected.y + item_selected.h
					then
						-- XXX: run callback in owner widget with item_selected
						-- XXX: destroy this pop-up
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

		if (y > 0 and self.scr_y > 0) or (y < 0 and self.scr_y < self.doc_h - self.vp_h) then
			local old_scr_x, old_scr_y = self.scr_x, self.scr_y

			-- Scroll about 1/4 of the visible items.
			--local n = self.h / self.item_h * 4
			self:scrollDeltaV(math.floor(self.wheel_jump_size * -y + 0.5))

			if old_scr_x ~= self.scr_x or old_scr_y ~= self.scr_y then
				self:cacheUpdate(true)
			end

			-- Stop bubbling
			return true
		end
	end
end


function def:uiCall_update(dt)

	print("Hello?")

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
	end

	self:scrollUpdate(dt)

	-- Force a cache update if the external scroll position is different.
	if scr_x_old ~= self.scr_x or scr_y_old ~= self.scr_y then
		needs_update = true
	end

	if needs_update then
		self:cacheUpdate(true)
	end
end


function def:uiCall_destroy(inst)

	if self == inst then
		--
	end
end


def.skinners = {
	default = {
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

			love.graphics.push("all")

			love.graphics.setColor(1, 0, 1, 1)
			love.graphics.rectangle("line", 0, 0, self.w - 1, self.h - 1)
			love.graphics.print("WIP dropdown pop-up menu")

			love.graphics.pop()
		end,


		--renderLast = function(self, ox, oy) end,


		renderThimble = function(self, ox, oy)
			-- nothing
		end,
	},
}


return def
