--[[
wimp/menu_pop: A pop-up menu implementation.

Supports sub-menus by spawning additional menu widgets. All widgets in the sequence
form a doubly-linked list, using the fields 'self.chain_next' and 'self.chain_prev'.
The first item in the chain may be the client (invoking) widget.


┌─────────────────────┐
│    Client Widget    │
│                     │
│               ┌──────────────────────┐
│               │    Foobar    Ctrl+f  │
└───────────────│[/] Docked    Shift+d │
                │┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄│
                │    Save      Ctrl+s  │┌───────────────────┐
                │    Export          > ││ As Foo...   Alt+f │
                │┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄││ As Bar...   Alt+b │
                │    Quit      Ctrl+F4 │└───────────────────┘
                └──────────────────────┘

      Chain #1   --->    Chain #2     --->     Chain #3


Three menu-items are supported:
* Command: executes a function
* Group: opens a sub-menu
* Separator

These are not real OS widgets, so they are limited to the boundaries of the window.
They may act strangely if the window is too small for the menu contents.


Horizontal item padding (not including widget margins):

 skin.pad_x1  skin.pad_x2
 |                      |
┌────────────────────────┐
│: [B]   Text    Ctrl+t :│
└────────────────────────┘
  │ │ │ │    │*1│      │
  │ │ │ │    │  │      │
  │ │ │ │    │  │      │
  │ │ │ │    │  │      │
  │ │ │ │    │  │      │
  │ │ │ │    │  │      │
  │ │ │ │    │  │      │
  │ │ │ │    │  │      │
  │ │ │ │    │  │      skin.pad_shortcut_x2 *2
  │ │ │ │    │  │
  │ │ │ │    │  │
  │ │ │ │    │  │
  │ │ │ │    │  skin.pad_shortcut_x1 *2
  │ │ │ │    │
  │ │ │ │    skin.pad_text_x2
  │ │ │ │
  │ │ │ │
  │ │ │ │
  │ │ │ skin.pad_text_x1
  │ │ │
  │ │ skin.pad_icon_x2 *3
  │ │
  │ skin.icon_draw_w *3
  │
  skin.pad_icon_x1 *3


*1: The shortcut text is right-aligned.
*2: Shortcut padding is only applied when at least one item has shortcut text.
*3: Icon padding is only applied when the setting 'show_icons' is enabled.
--]]


local context = select(1, ...)


local lgcMenu = context:getLua("shared/lgc_menu")
local lgcPopUps = context:getLua("shared/lgc_pop_ups")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiPopUpMenu = require(context.conf.prod_ui_req .. "ui_pop_up_menu")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "menu_pop1",

	default_settings = {
		show_icons = true, -- WIP
		icon_set_id = false, -- lookup for 'resources.icons[icon_set_id]'
	}
}


lgcMenu.attachMenuMethods(def)
widShared.scrollSetMethods(def)


local _arrange_tb = lgcMenu.arrangers["list-tb"]
function def:arrangeItems(first, last)
	_arrange_tb(self, self.vp, true, first, last)
end


def.setBlocking = lgcPopUps.setBlocking


local function destroySubMenus(self)
	if self.chain_next then
		widShared.chainDestroyPost(self)
		self.last_open_group = false
	end
end


local function assignSubMenu(item, client, set_selection)
	-- Only create a sub-menu if the last-open doesn't match the current index (including if last-open is false).
	local selected_item = client.MN_items[client.MN_index]
	if selected_item ~= client.last_open_group then

		-- If this menu currently has a sub-menu, close it.
		destroySubMenus(client)

		local parent = client.parent
		local group_prototype = item.group_prototype
		if group_prototype and parent then
			-- Add as a sibling and attach to the menu chain.
			local client_sub = parent:addChild("wimp/menu_pop")
			client.chain_next = client_sub
			client_sub.chain_prev = client
			client_sub.wid_ref = client.wid_ref

			-- Configure menu defs.
			group_prototype:configure(client_sub)

			-- Append items to fresh menu
			if group_prototype then
				client_sub:applyMenuPrototype(group_prototype)
			end

			-- Set dimensions and decide whether to place on the right or left (if not enough space).
			client_sub:updateDimensions()
			client_sub:menuChangeCleanup()

			local vp = client.vp
			client_sub.x = client.x + vp.x + vp.w -- XXX WIP
			client_sub.y = client.y + item.y

			client_sub:keepInBounds()

			client_sub.origin_item = item

			if set_selection then
				client_sub.MN_default_deselect = false
			end
			client_sub:menuSetDefaultSelection()

			-- Mark the item used to invoke this sub-menu.
			client.last_open_group = item

			-- Assign thimble to sub-menu
			client_sub:tryTakeThimble2()
		end
	end
end


local function async_changeSubMenu(self, item_index, dt)
	-- We assume that this async function is only called as a result of the mouse hovering over a group,
	-- so the sub-menu defaults to no selection.

	if item_index == self.MN_index then
		local item = self.MN_items[item_index]

		if item and item.type == "group" then
			assignSubMenu(item, self, false)
		else
			destroySubMenus(self)
		end
	end
end


local function activateGroup(client, item, set_selection)
	assignSubMenu(item, client, set_selection)
	client.open_time = 0
end


local function activateCommand(client, item)
	local wid_ref = client.wid_ref

	if item.callback and wid_ref then -- XXX deal with cases where wid_ref is a dangling reference
		item.callback(wid_ref, item)
	end

	local root = client:getRootWidget()
	root:sendEvent("rootCall_destroyPopUp", client, "concluded")
end


local function keyMnemonicSearch(items, key)
	for i, item in ipairs(items) do
		if key == item.key_mnemonic then
			return i, item
		end
	end
end


local function _getRes(item, client, skin)
	local is_selected = client.MN_items[client.MN_index] == item
	if item.actionable then
		return is_selected and skin.res_actionable_selected or skin.res_actionable_unselected
	else
		return is_selected and skin.res_inactionable_selected or skin.res_inactionable_unselected
	end
end


-- 'item.text_int' == internal version of 'item.text', with the underline notation stripped.
-- For items with icons, 'item.tq_icon' is set in 'self:updateDimensions()'.


local function _makeCommand(self, info)
	uiAssert.type1(2, info, "table")

	uiAssert.fieldType1(info, "info", "text", "string")
	uiAssert.fieldTypeEval1(info, "info", "text_shortcut", "string")
	uiAssert.fieldTypeEval1(info, "info", "key_mnemonic", "string")
	uiAssert.fieldTypeEval1(info, "info", "key_shortcut", "string")
	uiAssert.fieldTypeEval1(info, "info", "icon_id", "string")
	uiAssert.fieldTypeEval1(info, "info", "callback", "function")
	uiAssert.fieldTypeEval1(info, "info", "config", "function")
	uiAssert.fieldTypeEval1(info, "info", "actionable", "boolean")
	-- don't check 'user_value'

	local item = {
		x = 0, y = 0, w = 0, h = 0,
		type = "command",
		text = info.text,
		text_int = "",
		text_shortcut = info.text_shortcut or false,
		icon_id = info.icon_id or false,

		selectable = true,
		callback = info.callback or false,
		actionable = not not info.callback,
		user_value = info.user_value or false
	}
	if item.callback and info.actionable ~= nil then
		item.actionable = not not info.actionable
	end

	return item
end


local function _makeGroup(self, info)
	uiAssert.type1(2, info, "table")

	uiAssert.fieldType1(info, "info", "text", "string")
	uiAssert.fieldTypeEval1(info, "info", "key_mnemonic", "string")
	uiAssert.fieldTypeEval1(info, "info", "icon_id", "string")
	uiAssert.fieldTypeEval1(info, "info", "group_prototype", "table")
	uiAssert.fieldTypeEval1(info, "info", "config", "function")

	local item = {
		x = 0, y = 0, w = 0, h = 0,
		type = "group",
		text = info.text,
		text_int = "",
		icon_id = info.icon_id or false,

		selectable = true,
		group_prototype = info.group_prototype,
		actionable = not not info.group_prototype
	}

	if item.group_prototype and info.actionable ~= nil then
		item.actionable = not not info.actionable
	end

	return item
end


local function _makeSeparator()
	return {
		x=0, y=0, w=0, h=0,
		type = "separator"
	}
end


function def:applyMenuPrototype(menu_prototype)
	uiAssert.type1(1, menu_prototype, "table")

	if #self.MN_items > 0 then
		error("this menu already contains items.")
	end

	for i, info in ipairs(menu_prototype) do
		for k, v in pairs(info) do
			print("i", i, k, v)
		end
		local mt = getmetatable(info)
		if mt then
			for kk, vv in pairs(mt) do
				print("mt", kk, vv)
			end
		end

		local typ = info.type
		local item
		if typ == "command" then
			item = _makeCommand(self, info)

		elseif typ == "group" then
			item = _makeGroup(self, info)

		elseif typ == "separator" then
			item = _makeSeparator()

		else
			error("invalid item type: " .. tostring(typ))
		end

		table.insert(self.MN_items, item)
	end
end


--- Sets the correct widget dimensions for the menu, updating its internal contents along the way.
function def:updateDimensions()
	local skin = self.skin
	local items = self.MN_items
	local font = skin.font_item

	self.icon_x = 0
	self.text_label_x = 0
	self.text_shortcut_x = 0
	self.group_arrow_x = 0

	local w_text, w_shortcut = 0, 0
	local has_groups_or_shortcuts = false

	local icon_h = self.show_icons and skin.pad_icon_y1 + skin.icon_draw_h + skin.pad_icon_y2 or 0
	local text_h = skin.pad_text_y1 + font:getHeight() + skin.pad_text_y2
	local item_height = math.max(text_h, icon_h)

	for i, item in ipairs(items) do
		item.x = 0
		item.h = (item.type == "separator") and skin.separator_item_height or item_height

		if item.type == "group" then
			has_groups_or_shortcuts = true
		end

		if item.type ~= "separator" then
			item.tq_icon = lgcMenu.getIconQuad(self.icon_set_id, item.icon_id)

			-- Underline state
			local temp_str, x, w = textUtil.processUnderline(item.text, font)
			if not temp_str then
				item.ul_on = false
				item.text_int = item.text
			else
				item.ul_on = true
				item.text_int = temp_str
				item.ul_x = x
				item.ul_y = textUtil.getUnderlineOffset(font, skin.underline_width)
				item.ul_w = w
			end
		end

		-- Measure the widest label text and the widest shortcut text
		if item.text_int then
			w_text = math.max(w_text, font:getWidth(item.text_int))
		end
		if item.text_shortcut then
			w_shortcut = math.max(w_shortcut, font:getWidth(item.text_shortcut))
			has_groups_or_shortcuts = true
		end
	end

	-- Place items vertically.
	self:arrangeItems()

	-- The work-in-progress widget dimensions.
	local wh = items and items[#items] and (items[#items].y + items[#items].h) or 1
	local ww = skin.pad_x1

	if self.show_icons then
		ww = ww + skin.pad_icon_x1
		self.icon_x = ww
		ww = ww + skin.icon_draw_w + skin.pad_icon_x2
	end

	if w_text > 0 then
		ww = ww + skin.pad_text_x1
		self.text_label_x = ww
		ww = ww + w_text + skin.pad_text_x2
	end

	if has_groups_or_shortcuts then
		ww = ww + skin.pad_shortcut_x1
		self.text_shortcut_x = ww
		ww = ww + math.max(w_shortcut, skin.arrow_draw_w)
		self.group_arrow_x = ww - skin.arrow_draw_w
		ww = ww + skin.pad_shortcut_x2
	end

	ww = ww + skin.pad_x2

	-- We assume that the root widget's dimensions match the display area.
	local root = self:getRootWidget()
	local margin = skin.box.margin

	-- Manually add the margin edges...
	self.w = math.min(ww + margin.x1 + margin.x2, root.w)
	self.h = math.min(wh + margin.y1 + margin.y2, root.h)

	self:reshape()

	-- Update item widths and then reshape their internals
	local vp_w = self.vp.w
	for i, item in ipairs(self.MN_items) do
		item.w = vp_w
	end

	-- Refresh document size
	self.doc_w, self.doc_h = lgcMenu.getCombinedItemDimensions(self.MN_items)
end


def.keepInBounds = widShared.keepInBoundsOfParent


def.getInBounds = lgcMenu.getItemInBoundsRect
def.selectionInView = lgcMenu.selectionInView


def.getItemAtPoint = lgcMenu.widgetGetItemAtPoint -- (<self>, px, py, first, last)
def.trySelectItemAtPoint = lgcMenu.widgetTrySelectItemAtPoint -- (<self>, x, y, first, last)


def.movePrev = lgcMenu.widgetMovePrev
def.moveNext = lgcMenu.widgetMoveNext
def.moveFirst = lgcMenu.widgetMoveFirst
def.moveLast = lgcMenu.widgetMoveLast


function def:menuChangeCleanup()
	self:menuSetSelectionStep(0, false)
	self:arrangeItems()
	self:cacheUpdate(true)
	self:scrollClampViewport()
	self:selectionInView()
end


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 2

	self.sort_id = 7

	lgcPopUps.setupInstance(self)

	widShared.setupDoc(self)
	widShared.setupScroll(self, -1, -1)
	widShared.setupViewports(self, 2)

	self.press_busy = false

	lgcMenu.setup(self)
	self.MN_default_deselect = true

	self.icon_x = 0
	self.text_label_x = 0
	self.text_shortcut_x = 0
	self.group_arrow_x = 0

	-- References populated when this widget is part of a chain of menus.
	self.chain_next = false
	self.chain_prev = false

	-- Caller sets this to the widget table that this menu "belongs to" or extends.
	self.wid_ref = false

	-- Used to determine if a sub-menu needs to be invoked.
	self.last_open_group = false

	-- Timer to delay the opening and closing of sub-menus.
	self.open_time = 0.0

	-- When this is a sub-menu, include a reference to the item in parent that was used to spawn it.
	--self.origin_item =

	self:skinSetRefs()
	self:skinInstall()
	self:applyAllSettings()

	self:reshape()
	self:menuChangeCleanup()
end


function def:uiCall_reshapePre()
	-- vp - viewport area
	-- vp2 - reserved for separating scroll bars (etc.) from content

	local vp, vp2 = self.vp, self.vp2

	vp:set(0, 0, self.w, self.h)

	-- Apply edge padding.
	vp:reduceSideDelta(self.skin.box.margin)

	-- 'Okay-to-click' rectangle.
	-- (Reserved in case any kind of scroll bar or other UI control is added around
	-- the edges.)
	vp:copy(vp2)

	self:cacheUpdate()

	return true
end


--- Updates cached display state.
-- @param refresh_dimensions When true, update doc_w and doc_h based on the combined dimensions of all items.
-- @return Nothing.
function def:cacheUpdate(refresh_dimensions)
	if refresh_dimensions then
		self.doc_w, self.doc_h = lgcMenu.getCombinedItemDimensions(self.MN_items)
	end

	-- Set the draw ranges for items.
	lgcMenu.widgetAutoRangeV(self)
end


--- The default navigational key input.
function def:wid_defaultKeyNav(key, scancode, isrepeat)
	local mod = self.context.key_mgr.mod

	if key == "up" or (key == "tab" and mod["shift"]) then
		self:movePrev(1, true, isrepeat)
		return true

	elseif key == "down" or (key == "tab" and not mod["shift"]) then
		self:moveNext(1, true, isrepeat)
		return true
	end
end


function def:uiCall_keyPressed(inst, key, scancode, isrepeat)
	if self == inst then
		local root = self:getRootWidget()

		if key == "escape" then
			destroySubMenus(self)
			--print("self.chain_prev", self.chain_prev)

			-- Need some special handling depending on whether this is the base pop-up, or
			-- if the previous chain entry is the widget that invoked the pop-up (or is
			-- yet another temporary pop-up menu).

			-- This is the base pop-up.
			if not self.chain_prev or (self.wid_ref and self.wid_ref == self.chain_prev) then
				local wid_ref = self.wid_ref

				root:sendEvent("rootCall_destroyPopUp", self, "concluded")
				-- NOTE: self is now dead.

				return true
			-- This pop-up is further down the menu chain.
			-- We do not want to destroy the entire chain, just this one (and any others to the
			-- right, which we took care of above).
			else
				local temp_chain_prev = self.chain_prev

				self:destroy()

				temp_chain_prev.chain_next = false
				temp_chain_prev.last_open_group = false
				temp_chain_prev:tryTakeThimble2()

				return true
			end

		elseif key == "left" then
			-- Similar to Esc, but we only want to act here if chain_prev is another pop-up.
			if self.chain_prev and self.chain_prev ~= self.wid_ref then
				destroySubMenus(self)
				local temp_chain_prev = self.chain_prev

				self:destroy()

				temp_chain_prev.chain_next = false
				temp_chain_prev.last_open_group = false
				temp_chain_prev:tryTakeThimble2()

				return true
			end
		end
		-- 'left' needs to fall down here if not handled.

		local sel_item = self.MN_items[self.MN_index]

		if sel_item and sel_item.selectable and sel_item.actionable then
			if sel_item.type == "group" then
				if sel_item.group_prototype and (key == "return" or key == "kpenter" or key == "space" or key == "right") then
					activateGroup(self, sel_item, true)
					return true
				end

			elseif sel_item.type == "command" then
				if key == "return" or key == "kpenter" or key == "space" then
					activateCommand(self, sel_item)
					return true
				end
			end
		end

		-- Run the default navigation checks.
		if self.wid_defaultKeyNav and self:wid_defaultKeyNav(key, scancode, isrepeat) then
			return true
		end

		-- prev/next movement for the menu bar, if it exists and nothing has already handled input.
		if self.wid_ref and self.wid_ref.widCall_keyPressedFallback then
			local result = self.wid_ref:widCall_keyPressedFallback(self, key, scancode, isrepeat)
			if result then
				return true
			end
		end

		local mod = self.context.key_mgr.mod
		if not mod["ctrl"] then
			-- Finally, check for key mnemonics.
			local item_i, item = keyMnemonicSearch(self.MN_items, key)
			if item and item.selectable then
				self:menuSetSelectedIndex(item_i)
				if item.actionable then
					if item.type == "group" then
						if item.group_prototype then
							activateGroup(self, item, true)
							return true
						end

					elseif item.type == "command" then
						activateCommand(self, item)
						return true
					end
				end
			end
		end
	end

	-- XXX: Test blocking keyhooks while the menu is active and has thimble focus.
	-- Solves issues like pressing Alt+? multiple times causing a jump from a window-frame
	-- menu to the root menu.
	-- It might break other things, though.
	return true -- XXX
end


function def:widCall_mnemonicFromOpenMenuBar(key) -- XXX: Unused?
	local item_i, item = keyMnemonicSearch(self.MN_items, key)
	if item and item.selectable then
		self:menuSetSelectedIndex(item_i)
		if item.actionable then
			if item.type == "group" then
				if item.group_prototype then
					activateGroup(self, item, true)
					return true
				end

			elseif item.type == "command" then
				activateCommand(self, item)
				return true
			end
		end
	end
end


function def:uiCall_pointerHoverOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		self:tryTakeThimble2()
	end
end


local function pressedAndThimbleHandoff(self, wid)
	if self.context.current_pressed == self and wid.allow_hover then
		self.context:transferPressedState(wid)

		wid.press_busy = self.press_busy
		self.press_busy = false
	end

	wid:tryTakeThimble2()

	if self.wid_chainRollOff then
		self:wid_chainRollOff()
	end
	if wid.wid_chainRollOn then
		wid:wid_chainRollOn()
	end
end


function def:uiCall_pointerDrag(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		local rolled = false

		-- Handle press roll-over for menus in Open Mode.
		if self.press_busy == "menu-drag" then
			local wid = widShared.checkChainPointerOverlap(self, mouse_x, mouse_y)

			if wid and wid ~= self then
				pressedAndThimbleHandoff(self, wid)

				rolled = true
				wid:wid_dragAfterRoll(mouse_x, mouse_y, mouse_dx, mouse_dy)
			end
		end

		-- Continue with the rest of the logic if no roll-over occurred.
		if not rolled then
			self:wid_dragAfterRoll(mouse_x, mouse_y, mouse_dx, mouse_dy)
		end
	end
end


local function restingOnOpenGroup(self)
	--[[
	print("restingOnOpenGroup",
		self.chain_next,
		self.chain_next and self.chain_next.origin_item,
		self.MN_items[self.MN_index])
	--]]
	return self.chain_next and self.chain_next.origin_item == self.MN_items[self.MN_index]
end


local function findOriginItemIndex(c_prev, origin_item)
	for i, c_item in ipairs(c_prev.MN_items) do
		--print(i, c_item, #c_prev.MN_items)
		if c_item == origin_item then
			return i
		end
	end
end


local function forceSuperMenuGroupSelection(self)
	local w_prev = self.chain_prev

	-- (Filter out menu-bars -> they don't have 'menu' populated)
	if w_prev and w_prev.menu and self.origin_item then

		-- We have the origin item table, but not its index in the menu list. Dig that up now.
		local index = findOriginItemIndex(w_prev, self.origin_item)

		if index then
			w_prev:menuSetSelectedIndex(index)
		end
	end
end


function def:wid_dragAfterRoll(mouse_x, mouse_y, mouse_dx, mouse_dy)
	-- Implement Drag-to-select.
	-- Need to test the full range of items because the mouse can drag outside the bounds of the viewport.

	-- Mouse position relative to viewport #1
	local vp = self.vp
	local mx, my = self:getRelativePosition(mouse_x, mouse_y)
	mx = mx - vp.x
	my = my - vp.y

	local item_i, item_t = self:getItemAtPoint(mx + self.scr_x, my + self.scr_y, 1, #self.MN_items)
	if item_i and item_t.selectable then
		self:menuSetSelectedIndex(item_i)
		--self:selectionInView()

		-- Immediately open groups when dragging over them.
		if item_t.type == "group" then
			if item_t.group_prototype then
				activateGroup(self, item_t, false)
			end
		end

	-- Only remove the selection if it is not a group that is currently opened.
	elseif not restingOnOpenGroup(self) then
		self:menuSetSelectedIndex(0)
	end

	-- If this is a sub-menu, force the left-menu's open group to remain selected.
	forceSuperMenuGroupSelection(self)
end


function def:uiCall_pointerHover(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		local vp = self.vp
		local mx, my = self:getRelativePosition(mouse_x, mouse_y)
		local xx = mx + self.scr_x - vp.x
		local yy = my + self.scr_y - vp.y

		local hover_ok = false

		if self.vp2:pointOverlap(mx, my) then
			-- Update item hover
			local i, item = self:getItemAtPoint(xx, yy, math.max(1, self.MN_items_first), math.min(#self.MN_items, self.MN_items_last))

			if item and item.selectable then
				self.MN_item_hover = item

				-- Implement mouse hover-to-select.
				if (mouse_dx ~= 0 or mouse_dy ~= 0) then
					local selected_item = self.MN_items[self.MN_index]
					if item ~= selected_item then
						self:menuSetSelectedIndex(i)
					end
				end

				hover_ok = true
			end
		end

		if self.MN_item_hover and not hover_ok then
			self.MN_item_hover = false

			-- Only remove the selection if it is not a group that is currently opened.
			if not restingOnOpenGroup(self) then
				self:menuSetSelectedIndex(0)
			end
		end

		-- If this is a sub-menu, force the left-menu's open group to remain selected.
		if self.chain_prev then
			forceSuperMenuGroupSelection(self)
		end
	end
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		self.MN_item_hover = false

		-- Only remove the selection if it is not a group that is currently opened.
		if not restingOnOpenGroup(self) then
			self:menuSetSelectedIndex(0)
		end
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

		if button <= 3 then
			self:tryTakeThimble2()
		end

		if self.vp2:pointOverlap(mx, my) then
			local vp = self.vp
			x = x - ax + self.scr_x - vp.x
			y = y - ay + self.scr_y - vp.y

			-- Check for click-able items.
			if not self.press_busy then
				local item_i, item_t = self:trySelectItemAtPoint(x, y, math.max(1, self.MN_items_first), math.min(#self.MN_items, self.MN_items_last))

				self.press_busy = "menu-drag"

				if item_t then
					-- Don't activate commands on press-down.
					if item_t.type == "group" then
						if item_t.group_prototype then
							activateGroup(self, item_t, false)
						end
					end
					-- Don't activate separators.
				end

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
				local item_selected = self.MN_items[self.MN_index]
				if item_selected and item_selected.selectable and item_selected.actionable then
					local vp = self.vp
					local ax, ay = self:getAbsolutePosition()
					local mouse_x = x - ax
					local mouse_y = y - ay

					-- Apply scroll and viewport offsets
					local xx = mouse_x + self.scr_x - vp.x
					local yy = mouse_y + self.scr_y - vp.y

					-- XXX safety precaution: ensure mouse position is within widget viewport #2?
					if xx >= item_selected.x and xx < item_selected.x + item_selected.w
					and yy >= item_selected.y and yy < item_selected.y + item_selected.h
					then
						if item_selected.type == "command" then
							activateCommand(self, item_selected)

						elseif item_selected.type == "group" then
							activateGroup(self, item_selected, false)
						end
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

		if widShared.checkScrollWheelScroll(self, x, y) then
			self:cacheUpdate(false)
			return true
		end
	end
end


function def:uiCall_update(dt)
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

	--print("wid_update", "open_time", self.open_time)

	local selected = self.MN_items[self.MN_index]

	--[[
	local cur_thimble2 = self.context.thimble2
	local in_chain = false
	local wid = self.chain_next
	while wid do
		if cur_thimble2 == wid then
			in_chain = true
			break
		end
		wid = wid.chain_next
	end

	--print("chain_next", self.chain_next, "in_chain", in_chain)
	--print("self.MN_index", self.MN_index, "selected", selected, "type", selected and selected.type, "last_open_group", self.last_open_group)
	--]]

	-- Is the mouse currently hovering over the selected item?
	local item_i, item_t
	if self.context.mouse_focus then
		local vp = self.vp
		local mx, my = self:getRelativePosition(self.context.mouse_x, self.context.mouse_y)
		item_i, item_t = self:getItemAtPoint(mx + self.scr_x - vp.x, my + self.scr_y - vp.y, 1, #self.MN_items)
	end

	--print("item_t", item_t, "selected", selected, "sel==itm", selected == item_t, "sel.type", selected and selected.type or "n/a", "last_open", self.last_open_group, "open_time", self.open_time)

	if item_t and selected and selected == item_t
	and (selected.type == "group" and not self.last_open_group
	or self.last_open_group and selected ~= self.last_open_group)
	then
		self.open_time = self.open_time + dt
	else
		self.open_time = 0
	end

	if self.open_time >= 0.20 then -- XXX config/style
		self.context:appendAsyncAction(self, async_changeSubMenu, self.MN_index)
		self.open_time = 0
	end

	if needs_update then
		self:cacheUpdate(true)
	end
end


function def:uiCall_destroy(inst)
	if self == inst then
		-- If this widget is part of a chain and currently holds the context pressed and/or thimble state,
		-- try to transfer it back to the previous menu in the chain.
		if self.press_busy == "menu-drag" then
			local c_prev = self.chain_prev
			if c_prev then
				pressedAndThimbleHandoff(self, c_prev)
			end
		end

		widShared.chainUnlink(self)

		widShared.removeViewports(self, 2)
	end
end


local check, change = uiTheme.check, uiTheme.change


local function _checkRes(skin, k)
	uiTheme.pushLabel(k)

	local res = check.getRes(skin, k)

	check.colorTuple(res, "col_icon")
	check.colorTuple(res, "col_label")
	check.colorTuple(res, "col_shortcut")
	check.colorTuple(res, "col_arrow")

	uiTheme.popLabel()
end


def.default_skinner = {
	validate = function(skin)
		check.box(skin, "box")
		check.type(skin, "icon_set_id", "nil", "string")
		check.loveType(skin, "font_item", "Font")
		check.slice(skin, "slc_body")
		check.quad(skin, "tq_px")
		check.quad(skin, "tq_arrow")

		-- Height of horizontal separator items.
		check.integer(skin, "separator_item_height", 0)

		-- Height of the line graphic within separators.
		check.integer(skin, "separator_graphic_height", 0)

		-- Used when underlining shortcut key letters in menu items.
		check.integer(skin, "underline_width", 0)

		-- (Pop up menus do not render hover-glow.)

		-- (While pop-up menus can scroll if needed, they do not have explicit scroll bars.)

		-- Padding values.
		check.integer(skin, "pad_x1", 0)
		check.integer(skin, "pad_x2", 0)

		check.integer(skin, "pad_icon_x1", 0)
		check.integer(skin, "pad_icon_x2", 0)
		check.integer(skin, "pad_icon_y1", 0)
		check.integer(skin, "pad_icon_y2", 0)

		-- Drawing offsets and size for icon quads.
		check.integer(skin, "icon_draw_w", 0)
		check.integer(skin, "icon_draw_h", 0)

		-- Padding above and below text and icons in items.
		-- The tallest of the two components determines the item's height.
		check.integer(skin, "pad_text_x1", 0)
		check.integer(skin, "pad_text_x2", 0)
		check.integer(skin, "pad_text_y1", 0)
		check.integer(skin, "pad_text_y2", 0)

		check.integer(skin, "arrow_draw_w", 0)
		check.integer(skin, "arrow_draw_h", 0)

		-- NOTE: Group arrows share padding with shortcuts.
		check.integer(skin, "pad_shortcut_x1", 0)
		check.integer(skin, "pad_shortcut_x2", 0)

		check.colorTuple(skin, "color_separator")
		check.colorTuple(skin, "color_select_glow")

		_checkRes(skin, "res_actionable_selected")
		_checkRes(skin, "res_actionable_unselected")
		_checkRes(skin, "res_inactionable_selected")
		_checkRes(skin, "res_inactionable_unselected")
	end,


	transform = function(skin, scale)
		change.integerScaled(skin, "separator_item_height", scale)
		change.integerScaled(skin, "separator_graphic_height", scale)
		change.integerScaled(skin, "underline_width", scale)

		change.integerScaled(skin, "pad_x1", scale)
		change.integerScaled(skin, "pad_x2", scale)
		change.integerScaled(skin, "pad_icon_x1", scale)
		change.integerScaled(skin, "pad_icon_x2", scale)
		change.integerScaled(skin, "pad_icon_y1", scale)
		change.integerScaled(skin, "pad_icon_y2", scale)

		change.integerScaled(skin, "icon_draw_w", scale)
		change.integerScaled(skin, "icon_draw_h", scale)

		change.integerScaled(skin, "pad_text_x1", scale)
		change.integerScaled(skin, "pad_text_x2", scale)
		change.integerScaled(skin, "pad_text_y1", scale)
		change.integerScaled(skin, "pad_text_y2", scale)

		change.integerScaled(skin, "arrow_draw_w", scale)
		change.integerScaled(skin, "arrow_draw_h", scale)
	end,


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)

		self:updateDimensions()
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
	end,


	--refresh = function(self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		local skin = self.skin
		local font = skin.font_item
		local tq_px = skin.tq_px
		local tq_arrow = skin.tq_arrow

		local items = self.MN_items
		local items_first, items_last = math.max(self.MN_items_first, 1), math.min(self.MN_items_last, #items)

		love.graphics.push("all")

		uiGraphics.intersectScissor(ox + self.x, oy + self.y, self.w, self.h)

		-- Back panel body
		local slc_body = skin.slc_body
		uiGraphics.drawSlice(slc_body, 0, 0, self.w, self.h)

		-- Scroll offsets
		love.graphics.translate(-self.scr_x, -self.scr_y)

		-- Pop up menus do not render hover-glow.

		-- Selection glow
		local sel_item = items[self.MN_index]
		if sel_item then
			love.graphics.setColor(skin.color_select_glow)
			uiGraphics.quad1x1(tq_px, sel_item.x, sel_item.y, sel_item.w, sel_item.h)
		end

		-- Separators
		love.graphics.setColor(skin.color_separator)
		for i = items_first, items_last do
			local item = items[i]
			if item.type == "separator" then
				uiGraphics.quad1x1(tq_px, item.x, math.floor(item.y + item.h/2), item.w, skin.separator_graphic_height)
			end
		end

		local text_x = self.text_label_x
		local text_y = skin.pad_text_y1

		-- Underlines
		for i = items_first, items_last do
			local item = items[i]
			if item.ul_on then
				local res = _getRes(item, self, skin)
				love.graphics.setColor(res.col_label)
				uiGraphics.quad1x1(
					tq_px,
					text_x + item.ul_x,
					item.y + skin.pad_text_y1 + item.ul_y,
					item.ul_w,
					skin.underline_width
				)
			end
		end

		local icon_x = self.icon_x

		-- Icons and arrow bijoux
		for i = items_first, items_last do
			local item = items[i]
			local tq_icon = item.tq_icon
			if tq_icon then
				local res = _getRes(item, self, skin)
				love.graphics.setColor(res.col_icon)
				uiGraphics.quadXYWH(
					tq_icon,
					icon_x,
					item.y + skin.pad_icon_y1,
					skin.icon_draw_w,
					skin.icon_draw_h
				)
			end

			local arrow_x = self.group_arrow_x
			if item.type == "group" then
				local res = _getRes(item, self, skin)
				love.graphics.setColor(res.col_arrow)
				uiGraphics.quadXYWH(
					tq_arrow,
					arrow_x,
					item.y + skin.pad_text_y1,
					tq_arrow.w,
					tq_arrow.h
				)
			end
		end

		love.graphics.setFont(font)

		-- Main text and shortcuts
		for i = items_first, items_last do
			local item = items[i]

			local res = _getRes(item, self, skin)

			if item.text_int then
				love.graphics.setColor(res.col_label)
				love.graphics.print(item.text_int, self.text_label_x, item.y + skin.pad_text_y1)
			end

			if item.text_shortcut then
				love.graphics.setColor(res.col_shortcut)
				love.graphics.print(item.text_shortcut, self.text_shortcut_x, item.y + skin.pad_text_y1)
			end
		end

		love.graphics.pop()

		-- Debug: draw viewports
		--[[
		love.graphics.push("all")
		love.graphics.setScissor()
		widShared.debug.debugDrawViewport(self, 1)
		widShared.debug.debugDrawViewport(self, 2)
		love.graphics.pop()
		--]]
	end,


	--renderLast = function(self, ox, oy) end,


	renderThimble = function(self, ox, oy)
		-- nothing
	end,
}


return def
