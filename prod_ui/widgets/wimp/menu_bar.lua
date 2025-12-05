--[[
wimp/menu_bar: A horizontal menu bar that is placed at the top of the application or within a window frame.

┌───────────────────────────────┐
│File  Edit  View  Help         │  <--  Menu bar widget
├─────────────────┬─────────────┘
│ New      ctrl+n │
│ Open     ctrl+o │                <--  Pop up menu spawned by menu bar
│┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄│
│ Quit     ctrl+q │
└─────────────────┘

The menu bar may act strangely if it becomes too narrow to display all categories.
--]]


local context = select(1, ...)


local pList2 = require(context.conf.prod_ui_req .. "lib.pile_list2")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiScale = require(context.conf.prod_ui_req .. "ui_scale")
local uiSchema = require(context.conf.prod_ui_req .. "ui_schema")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local wcMenu = context:getLua("shared/wc/wc_menu")
local wcWimp = context:getLua("shared/wc/wc_wimp")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "menu_bar1",

	default_settings = {
		icon_set_id = false -- lookup for 'resources.icons[icon_set_id]'
	}
}


wcMenu.attachMenuMethods(def)
widShared.scrollSetMethods(def)


def.getInBounds = wcMenu.getItemInBoundsRect
def.selectionInView = wcMenu.selectionInView
def.getItemAtPoint = wcMenu.widgetGetItemAtPoint -- (<self>, px, py, first, last)
def.trySelectItemAtPoint = wcMenu.widgetTrySelectItemAtPoint -- (<self>, x, y, first, last)
def.movePrev = wcMenu.widgetMovePrev
def.moveNext = wcMenu.widgetMoveNext
--def.moveFirst = wcMenu.widgetMoveFirst
--def.moveLast = wcMenu.widgetMoveLast


--[[
You can show labels for shortcut key-combos (like "Ctrl+Q" for Quit), but the actual implementation is handled by
whatever widget the menu bar is attached to.
The reason is that these shortcuts should work even if the menu bar is destroyed.
--]]


local function determineItemColor(item, client)
	if item.pop_up_proto then
		return client.skin.color_cat_enabled

	elseif client.MN_items[client.MN_index] == item then
		return client.skin.color_cat_selected

	else
		return client.skin.color_cat_disabled
	end
end


-- @param item The menu item containing the Pop-up menu definition.
-- @param client The widget that owns the menu item.
-- @param doctor_press When true, if user is pressing down a mouse button, transfer pressed state to the pop-up widget.
-- @param set_selection When true, set the default selection in the pop-up menu.
-- @return true if the pop-up was created, false if not.
local function _makePopUpMenu(item, client, take_thimble, doctor_press, set_selection) -- XXX name is too similar to wcWimp.makePopUpMenu()
	item.pop_up_proto:configure(item)

	-- Locate bottom of menu item in UI space.
	local ax, ay = client:getAbsolutePosition()
	local p_x = ax + item.x
	local p_y = ay + client.h
	--local p_y = ay + item.y + item.h

	local root = client:nodeGetRoot()

	if client["next"] then
		root:eventSend("rootCall_destroyPopUp", client)
	end


	local pop_up = wcWimp.makePopUpMenu(client, item.pop_up_proto, p_x, p_y)

	if doctor_press then
		root:eventSend("rootCall_doctorCurrentPressed", client, pop_up, "menu-drag")
	end

	client["next"] = pop_up
	client.state = "opened"
	client.last_open = item

	pop_up["prev"] = client

	if set_selection then
		pop_up.MN_default_deselect = false
	end
	pop_up:menuSetDefaultSelection()

	if take_thimble then
		pop_up:tryTakeThimble2()
	end
end


local function _destroyPopUpMenu(client, reason_code)
	local root = client:nodeGetRoot()

	root:eventSend("rootCall_destroyPopUp", client, reason_code)

	client.last_open = false
	client["next"] = false
end


local function _shapeItem(self, item)
	local skin = self.skin
	local font = skin.font_item

	item.h = self.vp.h

	local xx = 0
	item.text_x = xx
	if item.icon_id then
		xx = xx + skin.icon_pad_x
		item.icon_x = xx
		xx = xx + skin.icon_w
		item.text_x = xx
	end
	xx = xx + skin.text_pad_x
	item.text_x = xx

	item.text_y = math.floor(0.5 + (item.h - font:getHeight())/2)

	item.icon_y = math.floor(0.5 + (item.h - skin.icon_h)/2)

	-- Underline state
	local temp_str, x, w = textUtil.processUnderline(item.text, font)
	if not temp_str then
		item.ul_on = false
		item.text_int = item.text
	else
		item.ul_on = true
		item.text_int = temp_str
		item.ul_x = item.text_x + x
		item.ul_y = item.text_y + textUtil.getUnderlineOffset(font, skin.underline_width)
		item.ul_w = w
	end

	item.w = (item.icon_id and skin.icon_w or 0) + font:getWidth(item.text_int) + skin.text_pad_x*2
end


local _mt_category = {
	type="category",
}
_mt_category.__index = _mt_category


function def:addCategory(text, key_mnemonic, icon_id, pop_up_proto, selectable, pos)
	-- args 1-5 are checked in item:setParameters()
	uiAssert.integerEval(6, pos, "number")

	local items = self.MN_items
	pos = pos or #items + 1
	if pos < 1 or pos > #items + 1 then
		error("position is out of range")
	end

	local item = setmetatable({
		text = "",
		key_mnemonic = false,
		icon_id = false,
		pop_up_proto = false,
		selectable = true,

		x=0, y=0, w=0, h=0,
		text_int = "",
		tq_icon = false,
		icon_x = 0,
		icon_y = 0,
		text_x = 0,
		text_y = 0,
		text_w = 0,
	}, _mt_category)
	self:updateCategory(item, text, key_mnemonic, icon_id, pop_up_proto, selectable)

	table.insert(items, pos, item)

	self:arrangeItems()

	return item
end


function def:updateCategory(item, text, key_mnemonic, icon_id, pop_up_proto, selectable)
	uiAssert.type(1, item, "table")
	uiAssert.typeEval(2, text, "string")
	uiAssert.typeEval(3, key_mnemonic, "string")
	uiAssert.typeEval(4, icon_id, "string")
	uiAssert.typeEval(5, pop_up_proto, "table")
	-- don't assert 'selectable'

	if text ~= nil then
		item.text = text
	end
	if key_mnemonic ~= nil then
		item.key_mnemonic = key_mnemonic or false
	end
	--print("icon_id", icon_id)
	if icon_id ~= nil then
		item.icon_id = icon_id or false
		item.tq_icon = wcMenu.getIconQuad(self.icon_set_id, item.icon_id) or false
		--print("self.icon_set_id", self.icon_set_id)
		--print("new tq_icon", item.tq_icon)
	end
	if pop_up_proto ~= nil then
		item.pop_up_proto = pop_up_proto or false
	end
	if selectable ~= nil then
		item.selectable = not not selectable
	end

	_shapeItem(self, item)

	-- Invoke widget:arrangeItems() after you are done updating categories.
end


function def:removeCategory(item_t)
	uiAssert.type(1, item_t, "table")

	local item_i = self:menuGetItemIndex(item_t)

	local removed_item = self:removeItemByIndex(item_i)
	return removed_item
end


function def:removeCategoryByIndex(item_i)
	uiAssert.numberNotNaN(1, item_i)

	local items = self.MN_items
	local removed_item = items[item_i]
	if not removed_item then
		error("no item to remove at index: " .. tostring(item_i))
	end

	table.remove(items, item_i)

	wcMenu.removeItemIndexCleanup(self, item_i, "MN_index")

	self:arrangeItems()

	-- If there is a pop up menu associated with this category, destroy it.
	if self["next"] then
		_destroyPopUpMenu(self, "concluded")
	end

	return removed_item
end


local function setStateIdle(self)
	self["next"] = false
	self.last_open = false
	self:menuSetSelectedIndex(0)
	self.state = "idle"
end


function def:arrangeItems()
	local items = self.MN_items
	local xx = 0

	for i = 1, #items do
		local item = items[i]

		item.x = xx
		item.y = 0

		xx = item.x + item.w
	end
end


function def:wid_popUpCleanup(reason_code)
	--print("wid_popUpCleanup", "reason_code", reason_code, "thimble1", self.context.thimble1, "thimble2", self.context.thimble2, "self", self)
	--print(debug.traceback())

	if reason_code == "concluded" then
		setStateIdle(self)
	end

	self["next"] = false
	self.last_open = false
end


function def:setHidden(enabled)
	self.hidden = not not enabled

	-- Reshape the parent after calling.
end


function def:getHidden()
	return self.hidden
end


--- Call after adding or removing items. Side effect: resets menu bar state.
function def:menuChangeCleanup()
	setStateIdle(self)

	self:arrangeItems()
	self:scrollClampViewport()
	self:selectionInView()

	self:cacheUpdate(true)
end


function def:evt_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 0
	self.allow_focus_capture = true
	self.clip_scissor = true

	widShared.setupDoc(self)
	widShared.setupScroll(self, -1, -1)
	widShared.setupViewports(self, 2)

	self.press_busy = false

	-- Should be set by the skinner. (Typically, this is font height + top and bottom border values.)
	self.base_height = 0

	-- Used to determine if a new pop-up menu needs to be invoked.
	self.last_open = false

	wcMenu.setup(self) -- XXX clean up assignments below.

	-- Ref to currently-hovered item, or false if not hovering over any items.
	self.MN_item_hover = false

	-- Extends the selected item dimensions when scrolling to keep it within the bounds of the viewport.
	self.MN_selection_extend_x = 0
	self.MN_selection_extend_y = 0

	-- Range of items that are visible and should be checked for press/hover state.
	self.MN_items_first = 0 -- max(first, 1)
	self.MN_items_last = 2^53 -- min(last, #items)

	-- References populated when this widget is part of a chain of menus.
	self["next"] = false

	-- When true, the height reported to the layout node is zero. The menu may still respond
	-- through key shortcuts, though.
	self.hidden = false

	-- "idle": Not active.
	-- "opened": A pop-up menu is active.
	self.state = "idle"

	-- Used when underlining shortcut key letters in menu items.
	self.show_underlines = true

	self:skinSetRefs()
	self:skinInstall()
	self:applyAllSettings()
end


function def:evt_getSegmentLength(x_axis, cross_length)
	if not x_axis then
		if self.hidden then
			return 0, false
		else
			return self.base_height, false
		end
	end
end


function def:evt_reshapePre()
	local vp, vp2 = self.vp, self.vp2

	vp:set(0, 0, self.w, self.h)
	vp:reduceT(self.skin.box.border)

	-- 'Okay-to-click' rectangle.
	vp:copy(vp2)

	for i, item in ipairs(self.MN_items) do
		_shapeItem(self, item)
	end

	self:arrangeItems()
	self:scrollClampViewport()
	self:selectionInView()

	self:cacheUpdate(true)
end


--- Updates cached display state.
function def:cacheUpdate(refresh_dimensions)
	if refresh_dimensions then
		self.doc_w, self.doc_h = wcMenu.getCombinedItemDimensions(self.MN_items)
	end
end


local function keyMnemonicSearch(items, key)
	for i, item in ipairs(items) do
		if key == item.key_mnemonic then
			-- Return the first instance, even if not selectable, to avoid weird conflicts
			return i, item
		end
	end
end


local function _findMenuInParent(parent)
	-- XXX: This sucks; it's collatoral damage from rewriting how keyhooks work.
	-- I probably want containers with menus to have a standard set of methods to interact with them.
	for i, child in ipairs(parent.nodes) do
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
			local root = self:nodeGetRoot()
			if root.pop_up_menu then
				_destroyPopUpMenu(menu_bar, "concluded")
				setStateIdle(menu_bar)

				key_mgr:stunRecent()

				return true
			end
		-- Check category key mnemonics (when idle, and only if alt is held)
		else
			local alt_state = key_mgr:getModAlt()
			if (menu_bar.state == "idle" and alt_state) then
				--print("hook_pressed", key, alt_state, "menu_bar.state", menu_bar.state)

				local item_i, item = keyMnemonicSearch(menu_bar.MN_items, key)
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
	for i, item in ipairs(self.MN_items) do
		if item == item_t then
			item_i = i
			break
		end
	end

	if not item_i then
		error("item to run doesn't belong to this menu.")
	end

	if item_t.selectable then
		if item_t.pop_up_proto then
			_makePopUpMenu(item_t, self, true, false, true)
			self.state = "opened"
			self:menuSetSelectedIndex(item_i)
		end
	end

	self:cacheUpdate()
end


--- Activate the menu bar, opening the first selectable category (if one exists).
function def:widCall_keyboardActivate()
	-- If there is already a pop-up menu (whether chained to the menu bar or just in general), destroy it
	local root = self:nodeGetRoot()
	if root.pop_up_menu then
		_destroyPopUpMenu(self, "concluded")
		setStateIdle(self)
	else
		-- If the menu bar is currently active, blank out the current selection and restore thimble state if possible.
		if self.state == "opened" then
			setStateIdle(self)
		else
			-- Find first selectable item
			local item_i, item_t
			for i, item in ipairs(self.MN_items) do
				if item.selectable then
					item_i = i
					item_t = item
					break
				end
			end

			if item_t and item_t.selectable and item_t.pop_up_proto then
				_makePopUpMenu(item_t, self, true, false, true)
				self.state = "opened"
				self:menuSetSelectedIndex(item_i)
			end
		end
	end

	self:cacheUpdate(true)
end


--- Code to handle stepping left and right through the menu bar, which is called from a couple of places.
local function handleLeftRightKeys(self, key, scancode, isrepeat)
	local selection_old = self.MN_index
	local mod = self.context.key_mgr.mod

	if key == "left" or (key == "tab" and mod["shift"]) then
		self:movePrev(1, true, isrepeat)

	elseif key == "right" or (key == "tab" and not mod["shift"]) then
		self:moveNext(1, true, isrepeat)
	end

	-- Unfortunately, with this design, the current selection is blanked out by
	-- wid_popUpCleanup(), so we need to temporarily track it here.
	local selection_new = self.MN_index

	if selection_old ~= selection_new then
		local item = self.MN_items[self.MN_index]
		if item.selectable and item.pop_up_proto then
			_makePopUpMenu(item, self, true, false, true)

			self:menuSetSelectedIndex(selection_new)
			return true
		else
			_destroyPopUpMenu(self, "concluded")
			setStateIdle(self)

			return true
		end
	end
end


-- Menu bars cannot hold onto the thimble, so they don't get keyboard input events directly.
--function def:evt_keyPressed(inst, key, scancode, isrepeat)


--- Sent from a pop-up menu that hasn't handled left/right input.
function def:widCall_keyPressedFallback(invoker, key, scancode, isrepeat)
	if handleLeftRightKeys(self, key, scancode, isrepeat) then
		return true
	end
end


function def:evt_pointerDrag(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
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
		local vp = self.vp

		-- Mouse position relative to viewport #1
		local mx = mouse_x - vp.x
		local my = mouse_y - vp.y

		-- And with scroll offsets
		local s_mx = mx + self.scr_x
		local s_my = my + self.scr_y

		local ax, ay = self:getAbsolutePosition()

		local item_i, item_t = self:getItemAtPoint(s_mx - ax, s_my - ay, 1, #self.MN_items)
		if item_i and item_t.selectable then
			self:menuSetSelectedIndex(item_i)
			--self:selectionInView()

			if self.context.mouse_pressed_button == 1 then
				--print("item_t.pop_up_proto", item_t.pop_up_proto, "self.state", self.state)
				if item_t.pop_up_proto and self.state ~= "idle" then
					if self.last_open ~= item_t then
						if self["next"] then
							_destroyPopUpMenu(self)
						end
						if item_t.pop_up_proto then
							_makePopUpMenu(item_t, self, false, false, false)
						end
					end
				end
			end
		end
	end
end


function def:evt_pointerHover(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		local vp, vp2 = self.vp, self.vp2
		local ax, ay = self:getAbsolutePosition()
		mouse_x = mouse_x - ax
		mouse_y = mouse_y - ay

		local xx = mouse_x + self.scr_x - vp.x
		local yy = mouse_y + self.scr_y - vp.y

		-- Inside of viewport #2
		if mouse_x >= vp2.x
		and mouse_x < vp2.x + vp2.w
		and mouse_y >= vp2.y
		and mouse_y < vp2.y + vp2.h
		and (mouse_dx ~= 0 or mouse_dy ~= 0)
		then
			local hover_ok = false

			-- Update item hover
			local i, item = self:getItemAtPoint(xx, yy, 1, #self.MN_items)

			if item and item.selectable then
				local old_hover = self.MN_item_hover
				self.MN_item_hover = item
				--print("self.MN_item_hover 1", self.MN_item_hover)

				if self.state == "opened" then
					-- Hover-to-select
					local selected_item = self.MN_items[self.MN_index]
					if item ~= selected_item then
						self:menuSetSelectedIndex(i)
					end

					if self.last_open ~= item then
						if self["next"] then
							_destroyPopUpMenu(self)
						end
						if item.pop_up_proto then
							_makePopUpMenu(item, self, true, false, false)
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


function def:evt_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		self.MN_item_hover = false
	end
end


function def:evt_pointerPress(inst, x, y, button, istouch, presses)
	--print("menu bar pointerPress", self, inst, x, y, button)
	if self == inst then
		if button == 1 and button == self.context.mouse_pressed_button then
			local vp, vp2 = self.vp, self.vp2
			local ax, ay = self:getAbsolutePosition()
			local ms_x = x - ax
			local ms_y = y - ay

			-- Check if pointer was inside of viewport #2
			if ms_x >= vp2.x and ms_x < vp2.x + vp2.w
			and ms_y >= vp2.y and ms_y < vp2.y + vp2.h
			then
				-- Menu's already opened: close it
				if self.state == "opened" then
					_destroyPopUpMenu(self)
					setStateIdle(self)
					self.MN_item_hover = false

					self:cacheUpdate(true)
				else
					x = x - ax + self.scr_x - vp.x
					y = y - ay + self.scr_y - vp.y

					--print("self.press_busy", self.press_busy)

					-- Check for click-able items.
					if not self.press_busy then
						local item_i, item_t = self:trySelectItemAtPoint(x, y, 1, #self.MN_items)

						self.press_busy = "menu-drag"

						if item_t then
							-- If this menu already has a pop-up menu opened, close it and restore thimble state.
							if self["next"] then
								_destroyPopUpMenu(self)

							elseif item_t.pop_up_proto then
								_makePopUpMenu(item_t, self, true, false, false)
								self:cacheUpdate(true)
								-- Halt propagation
								return true
							end
						-- Clicked on bare or non-interactive part of widget: close any open category.
						else
							_destroyPopUpMenu(self)
							setStateIdle(self)
						end

						self:cacheUpdate(true)
					end
				end
			end
		end
	end
end


function def:evt_pointerUnpress(inst, x, y, button, istouch, presses)
	if self == inst then
		if button == self.context.mouse_pressed_button then
			self.press_busy = false

			-- Mouse is over the selected item
			local item_selected = self.MN_items[self.MN_index]
			if item_selected and item_selected.selectable  and item_selected.pop_up_proto then

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


local function async_destroy(self, _reserved, dt)
	-- Tests async destruction and pop-up menu cleanup.
	self:destroy()
end


function def:evt_update(dt)
	--print(self.w, self.h, self.doc_w, self.doc_h, self.scr_x, self.scr_y)
	--print("vp1", self.vp.x, self.vp.y, self.vp.w, self.vp.h)

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

	-- Set underline render state
	local uline_draw = context.settings.wimp.menu_bar.draw_underlines
	local mod = self.context.key_mgr.mod

	if uline_draw == "always" then
		self.show_underlines = true

	elseif uline_draw == "when-active" then
		self.show_underlines = (self["next"] or mod["alt"]) and true or false

	else -- "never"
		self.show_underlines = false
	end
end


function def:evt_destroy(inst)
	if self == inst then
		-- If a pop-up menu exists that references this widget, destroy it.
		if self["next"] then
			_destroyPopUpMenu(self, "concluded")
		end
		pList2.nodeUnlink(self)

		widShared.removeViewports(self, 2)
	end
end


-- Menu bars cannot hold the thimble (though pop-up menus created by them can).
--function def:renderThimble(os_x, os_y)


local themeAssert = context:getLua("core/res/theme_assert")


def.default_skinner = {
	validate = uiSchema.newKeysX {
		skinner_id = {uiAssert.type, "string"},

		-- settings
		icon_set_id = {uiAssert.type, "string"},
		-- /settings

		-- NOTE: Very large box borders will interfere with clicking on menu items.
		box = themeAssert.box,
		tq_px = themeAssert.quad,
		sl_body = themeAssert.slice,
		font_item = themeAssert.font,
		color_cat_enabled = uiAssert.loveColorTuple,
		color_cat_selected = uiAssert.loveColorTuple,
		color_cat_disabled = uiAssert.loveColorTuple,
		color_select_glow = uiAssert.loveColorTuple,
		color_hover_glow = uiAssert.loveColorTuple,
		color_item_icon = uiAssert.loveColorTuple,

		base_height = {uiAssert.numberGEOrOneOf, 0, "auto"},
		underline_width = {uiAssert.integerGE, 1},
		height_mult = {uiAssert.numberGE, 1.0},

		icon_pad_x = {uiAssert.integerGE, 0},
		icon_w = {uiAssert.integerGE, 0},
		icon_h = {uiAssert.integerGE, 0},
		text_pad_x = {uiAssert.integerGE, 0}
	},


	transform = function(scale, skin)
		uiScale.fieldInteger(scale, skin, "underline_width")
		if type(skin.base_height) == "number" then
			uiScale.fieldInteger(scale, skin, "base_height")
		end

		uiScale.fieldInteger(scale, skin, "icon_pad_x")
		uiScale.fieldInteger(scale, skin, "icon_w")
		uiScale.fieldInteger(scale, skin, "text_pad_x")
	end,


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)

		if skin.base_height == "auto" then
			self.base_height = math.floor(skin.font_item:getHeight() * skin.height_mult) + skin.box.border.y1 + skin.box.border.y2
		else
			self.base_height = skin.base_height
		end
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	--refresh = function(self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		if self.hidden then
			return
		end

		local skin = self.skin

		local items = self.MN_items
		local selected_index = self.MN_index

		local font = skin.font_item

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

		-- Item icons
		love.graphics.setColor(skin.color_item_icon)
		for i = 1, #items do
			local item = items[i]
			local tq_icon = item.tq_icon
			--print("item #", i, "tq_icon", tq_icon)
			if tq_icon then
				uiGraphics.quadShrinkOrCenterXYWH(tq_icon, item.x + item.icon_x, item.y + item.icon_y, skin.icon_w, skin.icon_h)
			end
		end

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
						skin.underline_width
					)
				end
			end
		end

		--print("self.MN_items_first", self.MN_items_first, "self.MN_items_last", self.MN_items_last)

		-- Item text
		love.graphics.setFont(font)
		for i = 1, #items do
			local item = items[i]
			love.graphics.setColor(determineItemColor(item, self))
			love.graphics.print(item.text_int, item.x + item.text_x, item.y + item.text_y)
		end

		love.graphics.pop()

		-- XXX Debug
		--[[
		love.graphics.origin()
		love.graphics.setColor(1,1,1,1)
		love.graphics.setFont(self.context.resources.fonts.p)
		local ww = love.graphics.getWidth() - 288

		local root = self:nodeGetRoot()

		love.graphics.print("state: " .. self.state
		.. "\npressed: " .. tostring(self == self.context.current_pressed)
		.. "\nMN_item_hover: " .. tostring(self.MN_item_hover)
		.. "\nself.MN_index: " .. tostring(self.MN_index)
		,
		ww, oy + 32)
		 --]]
	end,


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy)
}


return def
