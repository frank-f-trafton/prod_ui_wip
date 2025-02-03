--[[
wimp/menu_bar: A horizontal menu bar that sits at the top of the application or within a window frame.

┌───────────────────────────────┐
│File  Edit  View  Help         │  <--  Menu Bar Widget
├─────────────────┬─────────────┘
│ New      ctrl+n │
│ Open     ctrl+o │                <--  Pop-up menu spawned by Menu Bar
│┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄│
│ Quit     ctrl+q │
└─────────────────┘

The menu bar may act strangely if it is too narrow to display all categories.

--]]

local context = select(1, ...)

local commonWimp = require(context.conf.prod_ui_req .. "common.common_wimp")
local lgcMenu = context:getLua("shared/lgc_menu")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = require(context.conf.prod_ui_req .. "common.wid_shared")


local def = {
	skin_id = "menu_bar1",
}


widShared.scrollSetMethods(def)


--[[
You can show labels for shortcut key-combos (like "Ctrl+Q" for Quit), but the actual implementation is handled by
whatever widget the menu bar is attached to.
The reason is that these shortcuts should work even if the menu bar is destroyed.
--]]


local function determineItemColor(item, client)
	if item.pop_up_def then
		return client.skin.color_cat_enabled

	elseif client.menu.items[client.menu.index] == item then
		return client.skin.color_cat_selected

	else
		return client.skin.color_cat_disabled
	end
end


def._mt_category = {
	type = "category",
	reshape = function(item, client)
		local font = client.skin.font_item

		--item.h = client.h
		item.h = client.vp_h
		item.text_x = client.text_pad_x
		item.text_y = math.floor(0.5 + item.h/2 - font:getHeight()/2)

		-- Underline state
		local temp_str, x, w = textUtil.processUnderline(item.text, font)
		if not temp_str then
			item.ul_on = false
			item.text_int = item.text
		else
			item.ul_on = true
			item.text_int = temp_str
			item.ul_x = item.text_x + x
			item.ul_w = w
			--item.ul_y = item.text_y + font:getHeight() + math.floor(0.5 + client.underline_width / 2)
			item.ul_y = item.text_y + font:getBaseline() + math.floor(0.5 + client.underline_width / 2)
		end

		item.w = font:getWidth(item.text_int) + client.text_pad_x*2
	end,
	render = function(item, client, ox, oy)
		love.graphics.setColor(determineItemColor(item, client))

		-- Underlines are handled in a separate pass in the client.

		-- Font is set by the client widget ahead of time.
		love.graphics.print(item.text_int, item.x + item.text_x, item.y + item.text_y)
	end,
}
def._mt_category.__index = def._mt_category


function def:appendItem(item_type, info)
	local item = {
		x = 0,
		y = 0,
		w = 1,
		h = 1,
	}

	if item_type == "category" then
		item.text = info.text or ""
		item.text_int = ""
		item.text_x = 0
		item.text_y = 0
		item.text_w = 1

		item.pop_up_def = info.pop_up_def

		item.selectable = true

		setmetatable(item, self._mt_category)
	else
		error("unknown item type: " .. tostring(item_type))
	end

	if info then
		for k, v in pairs(info) do
			item[k] = v
		end
	end

	self.menu.items[#self.menu.items + 1] = item

	return item
end


local function setStateIdle(self)
	self.chain_next = false
	self.last_open = false
	self.menu:setSelectedIndex(0)
	self.state = "idle"
end


-- @param item The menu item containing the Pop-up menu definition.
-- @param client The widget that owns the menu item.
-- @param doctor_press When true, if user is pressing down a mouse button, transfer pressed state to the pop-up widget.
-- @param set_selection When true, set the default selection in the pop-up menu.
-- @return true if the pop-up was created, false if not.
local function makePopUpMenu(item, client, take_thimble, doctor_press, set_selection) -- XXX name is too similar to commonWimp.makePopUpMenu()
	lgcMenu.widgetConfigureMenuItems(item, item.pop_up_def)

	-- Locate bottom of menu item in UI space.
	local ax, ay = client:getAbsolutePosition()
	local p_x = ax + item.x
	local p_y = ay + client.h
	--local p_y = ay + item.y + item.h

	local root = client:getTopWidgetInstance()

	if client.chain_next then
		root:sendEvent("rootCall_destroyPopUp", client)
	end

	local pop_up = commonWimp.makePopUpMenu(client, item.pop_up_def, p_x, p_y)

	if doctor_press then
		root:sendEvent("rootCall_doctorCurrentPressed", client, pop_up, "menu-drag")
	end

	client.chain_next = pop_up
	client.state = "opened"
	client.last_open = item

	pop_up.chain_prev = client

	if set_selection then
		pop_up.menu.default_deselect = false
	end
	pop_up.menu:setDefaultSelection()

	if take_thimble then
		pop_up:tryTakeThimble2()
	end
end


local function destroyPopUpMenu(client, reason_code)
	local root = client:getTopWidgetInstance()

	root:sendEvent("rootCall_destroyPopUp", client, reason_code)

	client.last_open = false
	client.chain_next = false
end


function def:arrange()
	local items = self.menu.items
	local xx = 0

	for i = 1, #items do
		local item = items[i]

		item.x = xx
		item.y = 0

		xx = item.x + item.w
	end
end


function def:wid_popUpCleanup(reason_code)
	print("wid_popUpCleanup", "reason_code", reason_code, "thimble1", self.context.thimble1, "thimble2", self.context.thimble2, "self", self)
	--print(debug.traceback())

	if reason_code == "concluded" then
		setStateIdle(self)
	end

	self.chain_next = false
	self.last_open = false
end


-- * Scroll helpers *


def.getInBounds = lgcMenu.getItemInBoundsRect
def.selectionInView = lgcMenu.selectionInView


-- * / Scroll helpers *


-- * Spatial selection *


def.getItemAtPoint = lgcMenu.widgetGetItemAtPoint -- (<self>, px, py, first, last)
def.trySelectItemAtPoint = lgcMenu.widgetTrySelectItemAtPoint -- (<self>, x, y, first, last)


-- * / Spatial selection *


-- * Selection movement *


def.movePrev = lgcMenu.widgetMovePrev
def.moveNext = lgcMenu.widgetMoveNext
--def.moveFirst = lgcMenu.widgetMoveFirst
--def.moveLast = lgcMenu.widgetMoveLast


-- * / Selection movement *


-- * Item management *


--- Call after adding or removing items. Side effect: resets menu bar state.
function def:menuChangeCleanup()
	setStateIdle(self)

	self:arrange()
	self:scrollClampViewport()
	self:selectionInView()

	self:cacheUpdate(true)
end


-- * / Item management *


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true
	self.can_have_thimble = false
	self.allow_focus_capture = true
	self.clip_scissor = true

	widShared.setupDoc(self)
	widShared.setupScroll(self)
	widShared.setupViewports(self, 2)

	self.press_busy = false

	-- Should be set by the skinner. (Typically, this is font height + top and bottom border values.)
	self.base_height = 0

	-- Used to determine if a new pop-up menu needs to be invoked.
	self.last_open = false

	-- Ref to currently-hovered item, or false if not hovering over any items.
	self.MN_item_hover = false

	-- Extends the selected item dimensions when scrolling to keep it within the bounds of the viewport.
	self.MN_selection_extend_x = 0
	self.MN_selection_extend_y = 0

	-- Range of items that are visible and should be checked for press/hover state.
	self.MN_items_first = 0 -- max(first, 1)
	self.MN_items_last = 2^53 -- min(last, #items)

	self.text_pad_x = 12

	-- References populated when this widget is part of a chain of menus.
	self.chain_next = false

	-- "idle": Not active.
	-- "opened": A pop-up menu is active.
	self.state = "idle"

	-- Used when underlining shortcut key letters in menu items.
	self.show_underlines = true
	self.underline_width = 1

	self.menu = self.menu or lgcMenu.new()

	self:skinSetRefs()
	self:skinInstall()

	self:resize()
	self:reshape()

	self:menuChangeCleanup()
end


function def:uiCall_resize()
	self.h = self.base_height
end


function def:uiCall_reshape()
	widShared.resetViewport(self, 1)
	widShared.carveViewport(self, 1, self.skin.box.border)

	-- 'Okay-to-click' rectangle.
	widShared.copyViewport(self, 1, 2)

	-- Reshape all items
	for i, item in ipairs(self.menu.items) do
		item:reshape(self)
	end

	self:cacheUpdate(true)
end


--- Updates cached display state.
function def:cacheUpdate(refresh_dimensions)
	if refresh_dimensions then
		self.doc_w, self.doc_h = lgcMenu.getCombinedItemDimensions(self.menu.items)
	end
end


local function keyMnemonicSearch(items, key)
	for i, item in ipairs(items) do
		if key == item.key_mnemonic then
			-- Return the first instance, even if not selectable, to avoid weird conflicts
			return i, item
		end
	end

	return nil
end


local function _findMenuInParent(parent)
	-- XXX: This sucks; it's collatoral damage from rewriting how keyhooks work.
	-- I probably want containers with menus to have a standard set of methods to interact with them.
	for i, child in ipairs(parent.children) do
		if child.id == "wimp/menu_bar" then
			return child
		end
	end
end



--- KeyPress hooks for the widget that owns the menu.
function def:widHook_pressed(key, scancode, isrepeat)
	-- 'self' is the menu's parent.

	-- Find this menu.
	local menu_bar = _findMenuInParent(self)
	if not menu_bar then
		return
	end

	local key_mgr = self.context.key_mgr

	if not self.context.mouse_pressed_button then
	--if not self.context.mouse_pressed_button and not isrepeat then

		-- Menu deactivation
		if key == "f10" then
			local root = self:getTopWidgetInstance()
			if root.pop_up_menu then
				destroyPopUpMenu(menu_bar, "concluded")
				setStateIdle(menu_bar)

				key_mgr:stunRecent()

				return true
			end
		-- Check category key mnemonics (when idle, and only if alt is held)
		else
			local alt_state = key_mgr:getModAlt()
			if (menu_bar.state == "idle" and alt_state) then
				print("hook_pressed", key, alt_state, "menu_bar.state", menu_bar.state)

				local item_i, item = keyMnemonicSearch(menu_bar.menu.items, key)
				if item then
					--print("got it", key, item.text)
					menu_bar:widCall_keyboardRunItem(item)
					return true
				end
			end
		end
	end
end


--- A callback function to use for keyRelease hooks.
function def:widHook_released(key, scancode, isrepeat)
	-- 'self' is the parent container.
	-- Find this menu.
	local menu_bar = _findMenuInParent(self)
	if not menu_bar then
		return
	end

	local key_mgr = self.context.key_mgr

	if not self.context.mouse_pressed_button then
		-- (Reason for excluding shift: Shift+F10 is used in some applications to open a right-click context menu.)
		if key == "f10" and key_mgr:getRecentKeyConstant() == key and not key_mgr:getModShift() then
			menu_bar:widCall_keyboardActivate()
			return true
		end
	end
end


function def:widCall_keyboardRunItem(item_t)
	-- Confirm item belongs to this menu
	local item_i
	for i, item in ipairs(self.menu.items) do
		if item == item_t then
			item_i = i
			break
		end
	end

	if not item_i then
		error("item to run doesn't belong to this menu.")
	end

	if item_t.selectable then
		if item_t.pop_up_def then
			makePopUpMenu(item_t, self, true, false, true)
			self.state = "opened"
			self.menu:setSelectedIndex(item_i)
		end
	end

	self:cacheUpdate()
end


--- Activate the menu bar, opening the first selectable category (if one exists).
function def:widCall_keyboardActivate()
	-- If there is already a pop-up menu (whether chained to the menu bar or just in general), destroy it
	local root = self:getTopWidgetInstance()
	if root.pop_up_menu then
		destroyPopUpMenu(self, "concluded")
		setStateIdle(self)
	else
		-- If the menu bar is currently active, blank out the current selection and restore thimble state if possible.
		if self.state == "opened" then
			setStateIdle(self)
		else
			-- Find first selectable item
			local item_i, item_t
			for i, item in ipairs(self.menu.items) do
				if item.selectable then
					item_i = i
					item_t = item
					break
				end
			end

			if item_t and item_t.selectable and item_t.pop_up_def then
				makePopUpMenu(item_t, self, true, false, true)
				self.state = "opened"
				self.menu:setSelectedIndex(item_i)
			end
		end
	end

	self:cacheUpdate(true)
end


--- Code to handle stepping left and right through the menu bar, which is called from a couple of places.
local function handleLeftRightKeys(self, key, scancode, isrepeat)
	local selection_old = self.menu.index
	local mod = self.context.key_mgr.mod

	if key == "left" or (key == "tab" and mod["shift"]) then
		self:movePrev()

	elseif key == "right" or (key == "tab" and not mod["shift"]) then
		self:moveNext()
	end

	-- Unfortunately, with this design, the current selection is blanked out by
	-- wid_popUpCleanup(), so we need to temporarily track it here.
	local selection_new = self.menu.index

	if selection_old ~= selection_new then
		local item = self.menu.items[self.menu.index]
		if item.selectable and item.pop_up_def then
			makePopUpMenu(item, self, true, false, true)

			self.menu:setSelectedIndex(selection_new)
			return true
		else
			destroyPopUpMenu(self, "concluded")
			setStateIdle(self)

			return true
		end
	end
end


-- Menu bars cannot hold onto the thimble, so they don't get keyboard input events directly.
--function def:uiCall_keyPressed(inst, key, scancode, isrepeat)


--- Sent from a pop-up menu that hasn't handled left/right input.
function def:widCall_keyPressedFallback(invoker, key, scancode, isrepeat)
	if handleLeftRightKeys(self, key, scancode, isrepeat) then
		return true
	end
end


function def:uiCall_pointerDrag(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		local rolled = false

		--print("self.state", self.state, "self.press_busy", self.press_busy)
		-- Handle press roll-over for menus in "opened" state.
		if self.state == "opened" and self.press_busy == "menu-drag" then
			local wid = widShared.checkChainPointerOverlap(self, mouse_x, mouse_y)

			if wid and wid ~= self then
				self.context:transferPressedState(wid)

				wid.press_busy = self.press_busy
				self.press_busy = false
				wid:tryTakeThimble2()

				if self.wid_chainRollOff then
					self:wid_chainRollOff()
				end
				if wid.wid_chainRollOn then
					wid:wid_chainRollOn()
				end

				rolled = true
				wid:wid_dragAfterRoll(mouse_x, mouse_y, mouse_dx, mouse_dy)
			end
		end

		if not rolled then
			self:wid_dragAfterRoll(mouse_x, mouse_y, mouse_dx, mouse_dy)
		end
	end
end


function def:wid_dragAfterRoll(mouse_x, mouse_y, mouse_dx, mouse_dy)
	-- Implement Drag-to-select.
	-- Need to test the full range of items because the mouse can drag outside the bounds of the viewport.

	if self.state == "opened" then
		-- Mouse position relative to viewport #1
		local mx = mouse_x - self.vp_x
		local my = mouse_y - self.vp_y

		-- And with scroll offsets
		local s_mx = mx + self.scr_x
		local s_my = my + self.scr_y

		local ax, ay = self:getAbsolutePosition()

		local item_i, item_t = self:getItemAtPoint(s_mx - ax, s_my - ay, 1, #self.menu.items)
		if item_i and item_t.selectable then
			self.menu:setSelectedIndex(item_i)
			--self:selectionInView()

			if self.context.mouse_pressed_button == 1 then
				--print("item_t.pop_up_def", item_t.pop_up_def, "self.state", self.state)
				if item_t.pop_up_def and self.state ~= "idle" then
					if self.last_open ~= item_t then
						if self.chain_next then
							destroyPopUpMenu(self)
						end
						if item_t.pop_up_def then
							makePopUpMenu(item_t, self, false, false, false)
						end
					end
				end
			end
		end
	end
end


--function def:uiCall_pointerHoverOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)


function def:uiCall_pointerHover(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		--[[
		-- XXX: Commented out 2023-Apr-07. I don't think this is necessary anymore. When active,
		-- the current pop-up selection is lost when the mouse sweeps across the menu
		-- bar body. This is undesirable behavior when navigating the menu with the keyboard
		-- (something bumps against the mouse and your selection disappears).
		if (mouse_dx ~= 0 or mouse_dy ~= 0) and self.chain_next then
			self.chain_next.menu:setSelectedIndex(0)
		end
		--]]

		local ax, ay = self:getAbsolutePosition()
		mouse_x = mouse_x - ax
		mouse_y = mouse_y - ay

		local xx = mouse_x + self.scr_x - self.vp_x
		local yy = mouse_y + self.scr_y - self.vp_y

		-- Inside of viewport #2
		if mouse_x >= self.vp2_x
		and mouse_x < self.vp2_x + self.vp2_w
		and mouse_y >= self.vp2_y
		and mouse_y < self.vp2_y + self.vp2_h
		and (mouse_dx ~= 0 or mouse_dy ~= 0)
		then
			local hover_ok = false

			-- Update item hover
			local i, item = self:getItemAtPoint(xx, yy, 1, #self.menu.items)

			if item and item.selectable then
				local old_hover = self.MN_item_hover
				self.MN_item_hover = item
				--print("self.MN_item_hover 1", self.MN_item_hover)

				if self.state == "opened" then
					-- Hover-to-select
					local selected_item = self.menu.items[self.menu.index]
					if item ~= selected_item then
						self.menu:setSelectedIndex(i)
					end

					if self.last_open ~= item then
						if self.chain_next then
							destroyPopUpMenu(self)
						end
						if item.pop_up_def then
							makePopUpMenu(item, self, true, false, false)
						end
					end
				end

				hover_ok = true
			end
			if not hover_ok then
				self.MN_item_hover = false
			end
		end
	end

	--print("self.MN_item_hover 2", self.MN_item_hover)
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		self.MN_item_hover = false
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	--print("menu bar pointerPress", self, inst, x, y, button)
	if self == inst then
		if button == 1 and button == self.context.mouse_pressed_button then
			local ax, ay = self:getAbsolutePosition()
			local ms_x = x - ax
			local ms_y = y - ay

			-- Check if pointer was inside of viewport #2
			if ms_x >= self.vp2_x and ms_x < self.vp2_x + self.vp2_w
			and ms_y >= self.vp2_y and ms_y < self.vp2_y + self.vp2_h
			then
				-- Menu's already opened: close it
				if self.state == "opened" then
					destroyPopUpMenu(self)
					setStateIdle(self)
					self.MN_item_hover = false

					self:cacheUpdate(true)
				else
					x = x - ax + self.scr_x - self.vp_x
					y = y - ay + self.scr_y - self.vp_y

					--print("self.press_busy", self.press_busy)

					-- Check for click-able items.
					if not self.press_busy then
						local item_i, item_t = self:trySelectItemAtPoint(x, y, 1, #self.menu.items)

						self.press_busy = "menu-drag"

						if item_t then
							-- If this menu already has a pop-up menu opened, close it and restore thimble state.
							if self.chain_next then
								destroyPopUpMenu(self)

							elseif item_t.pop_up_def then
								makePopUpMenu(item_t, self, true, false, false)
								self:cacheUpdate(true)
								-- Halt propagation
								return true
							end
						-- Clicked on bare or non-interactive part of widget: close any open category.
						else
							destroyPopUpMenu(self)
							setStateIdle(self)
						end

						self:cacheUpdate(true)
					end
				end
			end
		end
	end
end


--function def:uiCall_pointerPressRepeat(inst, x, y, button, istouch, reps)


function def:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)
	if self == inst then
		if button == self.context.mouse_pressed_button then
			self.press_busy = false

			-- Mouse is over the selected item
			local item_selected = self.menu.items[self.menu.index]
			if item_selected and item_selected.selectable  and item_selected.pop_up_def then

				local ax, ay = self:getAbsolutePosition()
				local mouse_x = x - ax
				local mouse_y = y - ay

				-- XXX safety precaution: ensure mouse position is within widget viewport #2?
				if mouse_x >= item_selected.x and mouse_x < item_selected.x + item_selected.w
				and mouse_y >= item_selected.y and mouse_y < item_selected.y + item_selected.h
				then
					-- reserved (?)
				end
			end
		end
	end
end


-- function def:uiCall_pointerWheel(inst, x, y)


local function async_remove(self, _reserved, dt)
	-- Tests async removal and pop-up menu cleanup.
	self:remove()
end


function def:uiCall_update(dt)
	--print(self.w, self.h, self.doc_w, self.doc_h, self.scr_x, self.scr_y)
	--print("vp1", self.vp_x, self.vp_y, self.vp_w, self.vp_h)

	dt = math.min(dt, 1.0)

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

	-- Update cache if necessary.
	if needs_update then
		self:cacheUpdate(true)
	end

	-- Selectively draw underlines?
	--[[
	local mod = self.context.key_mgr.mod
	if self.chain_next or mod["alt"] then
		self.show_underlines = true
	else
		self.show_underlines = false
	end
	--]]

	-- Test async removal
	--[[
	if self.DBG_time then
		self.DBG_time = self.DBG_time + dt
		if self.DBG_time > 1.0 then
			self.context:appendAsyncAction(self, async_remove)
		end
	end
	--]]
end


function def:uiCall_destroy(inst)
	if self == inst then
		-- If a pop-up menu exists that references this widget, destroy it.
		if self.chain_next then
			destroyPopUpMenu(self, "concluded")
		end
		widShared.chainUnlink(self)
	end
end


-- Menu bars cannot hold the thimble (though pop-up menus created by them can).
--function def:renderThimble(os_x, os_y)


def.default_skinner = {
	schema = {
		underline_width = "scaled-int",
		base_height = "scaled-int"
	},


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)

		self.underline_width = skin.underline_width
		self.base_height = skin.base_height
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	--refresh = function(self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		local skin = self.skin

		local items = self.menu.items
		local selected_index = self.menu.index

		local font = skin.font_item
		local font_h = font:getHeight()

		love.graphics.push("all")

		-- Don't draw menu contents outside of the widget bounding box.
		uiGraphics.intersectScissor(ox + self.x, oy + self.y, self.w, self.h)

		-- Body background.
		uiGraphics.drawSlice(skin.sl_body, 0, 0, self.w, self.h)

		-- Scroll offsets
		love.graphics.translate(-self.scr_x, -self.scr_y)

		-- Draw selection or hover glow (just one or the other).
		local sel_item = items[selected_index]
		local item_hover = self.MN_item_hover

		if sel_item then
			love.graphics.setColor(skin.color_select_glow)
			uiGraphics.quad1x1(skin.tq_px, sel_item.x, sel_item.y, sel_item.w, sel_item.h)

		elseif item_hover then
			love.graphics.setColor(skin.color_hover_glow)
			uiGraphics.quad1x1(skin.tq_px, item_hover.x, item_hover.y, item_hover.w, item_hover.h)
		end

		love.graphics.setFont(font)

		if self.show_underlines then
			for i = 1, #items do
				local item = items[i]
				if item.ul_on then
					love.graphics.setColor(determineItemColor(item, self))

					uiGraphics.quad1x1(
						skin.tq_px,
						item.x + item.ul_x,
						item.y + item.ul_y,
						item.ul_w,
						self.underline_width
					)
				end
			end
		end

		--print("self.MN_items_first", self.MN_items_first, "self.MN_items_last", self.MN_items_last)

		for i = 1, #items do
			items[i]:render(self, ox, oy)
		end

		love.graphics.pop()

		-- XXX Debug
		--[[
		love.graphics.origin()
		love.graphics.setColor(1,1,1,1)
		love.graphics.setFont(self.context.resources.fonts.p)
		local ww = love.graphics.getWidth() - 288

		local root = self:getTopWidgetInstance()

		love.graphics.print("state: " .. self.state
		.. "\npressed: " .. tostring(self == self.context.current_pressed)
		.. "\nMN_item_hover: " .. tostring(self.MN_item_hover)
		.. "\nself.menu.index: " .. tostring(self.menu.index))
		,
		ww, oy + 32)
		 --]]
	end,


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy)
}


return def
