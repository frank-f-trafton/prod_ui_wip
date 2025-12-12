--[[
The main body of a ComboBox (a Dropdown Box with text input).

Closed:

┌───────────┬─┐
│ Foobar|   │v│ --- Behaves like a text box. To open the drawer, click the button to the side, or press Alt+Down.
└───────────┴─┘     To cycle through items without opening the drawer, press the up/down keys or turn the mouse-wheel.


Opened:

┌───────────┬─┐
│ Foobar    │v│ --- Click to close the drawer and return keyboard focus to the text.
├───────────┼─┤
│ Bazbop    │^│ ══╗
│ Foobar    ├─┤   ║
│:Jingle::::│ │   ║
│ Bingo     │ │   ╠═══ Pop-up widget with list of selections.
│ Pogo      ├─┤   ║
│ Stove     │v│   ║
└───────────┴─┘ ══╝

The main widget and the drawer have separate menus, the latter being populated upon creation.
Changing the ComboBox's menu while the drawer is open does not affect the drawer's menu, and
vice versa.

Unlike similar list widgets, ComboBoxes do not support menu-item icons. ComboBoxes and Dropdowns use the same
drawer widget.

See wimp/dropdown_box.lua for relevant 'TODO's.

The last chosen index is tracked to help the user keep their place in the drawer when repeatedly opening
and closing it. This index should not be referenced by your program logic, however, because it might
have no association with the current input text. Use `self:getText()` instead.

Two kinds of pop-up menu are associated with this widget: the drawer, and also the standard context menu
when right-clicking on the editable text area. Only one of these may be active at a time, and you cannot
invoke another context menu on the selection in the drawer.
--]]


local context = select(1, ...)


local editFuncS = context:getLua("shared/line_ed/s/edit_func_s")
local editWid = context:getLua("shared/line_ed/edit_wid")
local editWidS = context:getLua("shared/line_ed/s/edit_wid_s")
local lineEdS = context:getLua("shared/line_ed/s/line_ed_s")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiScale = require(context.conf.prod_ui_req .. "ui_scale")
local uiSchema = require(context.conf.prod_ui_req .. "ui_schema")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local wcInputS = context:getLua("shared/wc/wc_input_s")
local wcMenu = context:getLua("shared/wc/wc_menu")
local wcPopUp = context:getLua("shared/wc/wc_pop_up")
local wcWimp = context:getLua("shared/wc/wc_wimp")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "combo_box1",
	--TODO: text_align_h = "left", -- "left", "center", "right"
}


wcMenu.attachMenuMethods(def)
widShared.scrollSetMethods(def)
-- No integrated scroll bars for single-line text inputs.


wcInputS.setupDef(def)


def.updateAlignOffset = wcInputS.method_updateAlignOffset
def.pop_up_proto = wcInputS.pop_up_proto


local _arrange_tb = wcMenu.arrangers["list-tb"]
function def:arrangeItems(first, last)
	_arrange_tb(self, self.vp, true, first, last)
end


def.movePrev = wcMenu.widgetMovePrev
def.moveNext = wcMenu.widgetMoveNext
def.moveFirst = wcMenu.widgetMoveFirst
def.moveLast = wcMenu.widgetMoveLast
def.movePageUp = wcMenu.widgetMovePageUp
def.movePageDown = wcMenu.widgetMovePageDown


local function refreshLineEdText(self)
	local chosen_tbl = self.MN_items[self.MN_index]
	local LE = self.LE

	if chosen_tbl then
		self:replaceText(chosen_tbl.text)
		editFuncS.wipeHistoryEntries(self)

		if self.LE_allow_highlight then
			self:highlightAll()
		end
	end
end


--- Callback for a change in the ComboBox state.
function def:wid_inputChanged(str)
	-- ...
end


--- Callback for when the drawer selection changes.
function def:wid_drawerSelection(drawer, index, tbl)
	-- ...
end


-- Callback for when the user types enter. Return true to halt the code that checks for typing
-- literal newlines via enter.
function def:wid_action(str)

end


-- Callback for when the user navigates away from this widget
function def:wid_thimble1Release(str)

end


local _mt_item = {selectable=true, x=0, y=0, w=0, h=0}
_mt_item.__index = _mt_item


function def:addItem(text, pos)
	local skin = self.skin
	local font = skin.font
	local items = self.MN_items

	uiAssert.type(1, text, "string")
	uiAssert.integerRangeEval(2, pos, 1, #items + 1)

	pos = pos or #items + 1

	local item = setmetatable({}, _mt_item)

	item.text = text
	-- ComboBox items do not support icons.

	table.insert(items, pos, item)

	-- Unlike Dropdown, we do not assign a default chosen index here if the list was previously empty.

	return item
end


function def:removeItem(item_t)
	uiAssert.type(1, item_t, "table")

	local item_i = self:menuGetItemIndex(item_t)
	local removed_item = self:removeItemByIndex(item_i)
	return removed_item
end


function def:removeItemByIndex(item_i)
	uiAssert.integerGE(1, item_i, 0)

	local items = self.MN_items
	local removed_item = items[item_i]
	if not removed_item then
		error("no item to remove at index: " .. tostring(item_i))
	end

	local removed = table.remove(items, item_i)

	wcMenu.removeItemIndexCleanup(self, item_i, "MN_index")

	return removed_item
end


function def:setSelection(item_t)
	uiAssert.type(1, item_t, "table")

	local item_i = self:menuGetItemIndex(item_t)
	self:setSelectionByIndex(item_i)
end


function def:setSelectionByIndex(item_i)
	uiAssert.integerGE(1, item_i, 0)

	local index_old = self.MN_index

	self:menuSetSelectedIndex(item_i)

	if index_old ~= self.MN_index then
		refreshLineEdText(self)
		self:wid_inputChanged(self.LE.line)
	end
end


function def:evt_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 1

	widShared.setupViewports(self, 3)

	widShared.setupScroll(self, -1, -1)
	widShared.setupDoc(self)

	self.press_busy = false

	wcMenu.setup(self)
	self.MN_page_jump_size = 4
	self.MN_wrap_selection = false

	-- State flags
	self.enabled = true
	self.hovered = false

	-- When opened, this holds a reference to the pop-up widget.
	self.wid_drawer = false

	wcInputS.setupInstance(self, "single")

	self:skinSetRefs()
	self:skinInstall()
	self:applyAllSettings()
end


function def:evt_reshapePre()
	-- Viewport #1 is for text placement and offsetting.
	-- Viewport #2 is the text scissor-box boundary.
	-- Viewport #3 is the "open menu" button.

	local skin = self.skin
	local vp, vp2, vp3 = self.vp, self.vp2, self.vp3

	vp:set(0, 0, self.w, self.h)
	vp:reduceT(skin.box.border)

	local button_spacing = (skin.button_spacing == "auto") and self.vp.h or skin.button_spacing

	vp:splitOrOverlay(vp3, skin.button_placement, button_spacing)
	vp:copy(vp2)
	vp:reduceT(skin.box.margin)

	self:scrollClampViewport()

	editWidS.generalUpdate(self, true, true, false, true)

	return true
end


function def:evt_update(dt)
	editWid.updateCaretBlink(self, dt)

	local scr_x_old, scr_y_old = self.scr_x, self.scr_y
	local do_update

	-- Handle update-time drag-scroll.
	if self.press_busy == "text-drag" then
		if wcInputS.mouseDragLogic(self) then
			do_update = true
		end
		if widShared.dragToScroll(self, dt) then
			do_update = true
		end
	end

	self:scrollUpdate(dt)

	-- Force a cache update if the external scroll position is different.
	if scr_x_old ~= self.scr_x or scr_y_old ~= self.scr_y then
		do_update = true
	end

	if do_update then
		editWidS.generalUpdate(self, true, false, false, true)
	end
end


function def:_openPopUpMenu()
	if not self.wid_drawer then
		local skin = self.skin
		local root = self:nodeGetRoot()

		local ax, ay = self:getAbsolutePosition()

		local drawer = root:addChild("wimp/dropdown_pop", skin.skin_id_pop, nil, self)
		drawer.x = ax
		drawer.y = ay + self.h
		self.wid_drawer = drawer
		self["next"] = drawer
		drawer["prev"] = self
		drawer:writeSetting("show_icons", false)

		for i, item in ipairs(self.MN_items) do
			local new_item = drawer:addItem(item.text, nil, item.icon_id, true)
			new_item.source_item = item
		end

		wcWimp.assignPopUp(self, drawer)

		drawer:setSelectionByIndex(self.MN_index)

		drawer:reshape()
		drawer:centerSelectedItem(true)

		wcPopUp.checkBlocking(drawer)

		drawer:tryTakeThimble2()
	end
end


function def:_closePopUpMenu(update_chosen)
	local wid_drawer = self.wid_drawer
	if wid_drawer and not wid_drawer._dead then
		self.wid_drawer:_closeSelf(update_chosen)
		self["next"] = false
	end
end


function def:_togglePopUpMenu(update_chosen)
	if self.wid_drawer then
		self:_closePopUpMenu(update_chosen)
	else
		self:_openPopUpMenu()
	end
end


function def:wid_popUpCleanup(reason_code)
	-- Prevent instantly creating the drawer again when clicking on the dropdown body (with the intention of closing it).
	if self.context.current_pressed == self then
		self.context.current_pressed = false
	end

	self.wid_drawer = false
end


--- Called in evt_keyPressed(). Implements basic keyboard navigation.
-- @param key The key code.
-- @param scancode The scancode.
-- @param isrepeat Whether this is a key-repeat event.
-- @return true to halt keynav and further bubbling of the keyPressed event.
function def:wid_defaultKeyNav(key, scancode, isrepeat)
	local check_chosen = false
	local index_old = self.MN_index

	if scancode == "up" then
		self:movePrev(1, true, isrepeat)
		check_chosen = true

	elseif scancode == "down" then
		self:moveNext(1, true, isrepeat)
		check_chosen = true

	elseif scancode == "pageup" then
		self:movePrev(self.MN_page_jump_size, true, false)
		check_chosen = true

	elseif scancode == "pagedown" then
		self:moveNext(self.MN_page_jump_size, true, false)
		check_chosen = true
	end

	if check_chosen then
		if index_old ~= self.MN_index then
			refreshLineEdText(self)
			self:wid_inputChanged(self.LE.line)
		end
		return true
	end
end


function def:evt_thimbleTopTake(targ)
	if self == targ then
		love.keyboard.setTextInput(true)
	end
end


function def:evt_thimbleTopRelease(targ)
	if self == targ then
		love.keyboard.setTextInput(false)
	end
end


function def:evt_thimble1Take(targ)
	if self == targ then
		wcInputS.thimble1Take(self)
	end
end


function def:evt_thimble1Release(targ)
	if self == targ then
		wcInputS.thimble1Release(self)

		if self.wid_drawer then
			-- The drawer should not exist if the dropdown body does not have thimble1.
			self:_closePopUpMenu(false)
		end

		self:wid_thimble1Release(self.LE.line)
	end
end


function def:evt_destroy(targ)
	if self == targ then
		-- Destroy pop-up menu (either kind) if it exists in reference to this widget.
		wcWimp.checkDestroyPopUp(self)
		--self:_closePopUpMenu(false)
		-- XXX: test the above change.

		widShared.removeViewports(self, 3)
	end
end


function def:evt_keyPressed(targ, key, scancode, isrepeat, hot_key, hot_scan)
	if self == targ then
		-- Forward keyboard events to the pop-up menu.
		if not self.wid_drawer then
			local items = self.MN_items
			local old_index = self.MN_index
			local old_item = items[old_index]

			-- Alt+Down opens the pop-up.
			if key == "down" and context.key_mgr.mod["alt"] then
				self:_openPopUpMenu()
				return true

			elseif (key == "return" or key == "kpenter") and self:wid_action(self.LE.line) then
				return true

			elseif self:wid_defaultKeyNav(key, scancode, isrepeat) then
				return true

			-- Standard text box controls (caret navigation, etc.)
			else
				local old_line = self.LE.line
				local rv = wcInputS.keyPressLogic(self, key, scancode, isrepeat, hot_key, hot_scan)
				if old_line ~= self.LE.line then
					self:wid_inputChanged(self.LE.line)
				end
				return rv
			end
		end
	end
end


function def:evt_textInput(targ, text)
	if self == targ then
		local old_line = self.LE.line
		local rv = wcInputS.textInputLogic(self, text)
		if old_line ~= self.LE.line then
			self:wid_inputChanged(self.LE.line)
		end
		return rv
	end
end


function def:evt_pointerHoverOn(targ, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == targ
	and self.enabled
	then
		self.hovered = true
	end
end


function def:evt_pointerHover(targ, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == targ
	and self.enabled
	then
		local mx, my = self:getRelativePosition(mouse_x, mouse_y)

		if self.vp:pointOverlap(mx, my) then
			self.cursor_hover = self.skin.cursor_on
		else
			self.cursor_hover = nil
		end
	end
end


function def:evt_pointerHoverOff(targ, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == targ then
		if self.enabled then
			self.hovered = false
			self.cursor_hover = nil
		end
	end
end


function def:evt_pointerPress(targ, x, y, button, istouch, presses)
	if self == targ
	and self.enabled
	and button == self.context.mouse_pressed_button
	then
		local had_thimble1_before = self == self.context.thimble1
		if button <= 3 then
			self:tryTakeThimble1()
		end

		local closed_drawer
		-- Drawer is already opened: close it.
		if self.wid_drawer then
			self:_closePopUpMenu(false)
			closed_drawer = true
		end

		local mx, my = self:getRelativePosition(x, y)

		-- Clicking the text area:
		if self.vp:pointOverlap(mx, my) then
			-- Propagation is halted when a context menu is created.
			if wcInputS.mousePressLogic(self, button, mx, my, had_thimble1_before) then
				return true
			end

		-- Clicking the drawer expander button: open drawer, but only
		-- if we didn't just close it.
		elseif button == 1
		and not closed_drawer
		and self.vp3:pointOverlap(mx, my)
		then
			self:_openPopUpMenu()
			return true
		end
	end
end


function def:evt_pointerDrag(targ, mouse_x, mouse_y, mouse_dx, mouse_dy)
	-- XXX: text manipulation stuff.

	-- If the cursor overlaps the pop-up drawer while not overlapping the body,
	-- transfer context pressed state.
	local wid_drawer = self.wid_drawer
	if wid_drawer then
		local ax1, ay1 = self:getAbsolutePosition()
		local ax2, ay2 = wid_drawer:getAbsolutePosition()

		if not (mouse_x >= ax1 and mouse_x < ax1 + self.w and mouse_y >= ay1 and mouse_y < ay1 + self.h)
		and (mouse_x >= ax2 and mouse_x < ax2 + wid_drawer.w and mouse_y >= ay2 and mouse_y < ay2 + wid_drawer.h)
		then
			self.context:transferPressedState(wid_drawer)

			wid_drawer.press_busy = "menu-drag"
			wid_drawer:cacheUpdate(true)
		end
	end
end


function def:evt_pointerUnpress(targ, x, y, button, istouch, presses)
	if self == targ then
		if button == 1 and button == self.context.mouse_pressed_button then
			self.press_busy = false
		end
	end
end


function def:evt_pointerWheel(targ, x, y)
	if self == targ then
		-- Cycle menu options if the drawer is closed and this widget has top thimble focus.
		if not self.wid_drawer and self:hasTopThimble() then
			local check_chosen = false
			local index_old = self.MN_index

			if y > 0 then
				self:movePrev(y, true)
				check_chosen = true

			elseif y < 0 then
				self:moveNext(math.abs(y), true)
				check_chosen = true
			end

			if check_chosen then
				if index_old ~= self.MN_index then
					refreshLineEdText(self)
					self:wid_inputChanged(self.LE.line)
				end
				return true
			end
		end
	end
end


local themeAssert = context:getLua("core/res/theme_assert")


local md_res = uiSchema.newKeysX {
	slice = themeAssert.slice,
	slc_deco_button = themeAssert.slice,

	tq_deco_glyph = themeAssert.quad,

	color_body = uiAssert.loveColorTuple,
	color_text = uiAssert.loveColorTuple,
	color_ghost_text = uiAssert.loveColorTuple,
	color_highlight = uiAssert.loveColorTuple,
	color_highlight_active = uiAssert.loveColorTuple,
	color_caret_insert = uiAssert.loveColorTuple,
	color_caret_insert_not_focused = uiAssert.loveColorTuple,
	color_caret_replace = uiAssert.loveColorTuple,
	color_caret_replace_not_focused = uiAssert.loveColorTuple,

	deco_ox = {uiAssert.type, "number"},
	deco_oy = {uiAssert.type, "number"}
}


def.default_skinner = {
	validate = uiSchema.newKeysX {
		skinner_id = {uiAssert.type, "string"},

		-- The SkinDef ID for pop-ups made by this widget.
		skin_id_pop = {uiAssert.type, "string"},

		box = themeAssert.box,

		font = themeAssert.font,
		font_ghost = themeAssert.font,
		ghost_mode = {uiAssert.namedMap, editWid._nm_ghost_mode},

		cursor_on = {uiAssert.types, "nil", "string"},

		text_align = {uiAssert.oneOf, "left", "center", "right"},
		text_align_v = {uiAssert.numberRange, 0.0, 1.0},

		-- Horizontal size of the expander button.
		-- "auto": use Viewport #2's height.
		button_spacing = {uiAssert.numberGEOrOneOf, 0, "auto"},

		-- Placement of the expander button.
		button_placement = {uiAssert.oneOf, "left", "right"},

		item_pad_v = {uiAssert.integerGE, 0},

		res_idle = md_res,
		res_pressed = md_res,
		res_disabled = md_res
	},


	transform = function(scale, skin)
		uiScale.fieldInteger(scale, skin, "item_pad_v")
		uiScale.fieldNumber(scale, skin, "button_spacing")

		local function _changeRes(scale, res)
			uiScale.fieldNumber(scale, res, "deco_ox")
			uiScale.fieldNumber(scale, res, "deco_oy")
		end

		_changeRes(scale, skin.res_idle)
		_changeRes(scale, skin.res_pressed)
		_changeRes(scale, skin.res_disabled)
	end,


	install = function(self, skinner, skin)
		uiTheme.skinnerCopyMethods(self, skinner)
		self.LE:setFont(self.skin.font)
		if self.LE_text_batch then
			self.LE_text_batch:setFont(self.skin.font)
		end
		self.LE:updateDisplayText()
	end,


	remove = function(self, skinner, skin)
		uiTheme.skinnerClearData(self)
		self.LE:setFont()
	end,


	--refresh = function(self, skinner, skin)
	--update = function(self, skinner, skin, dt)


	render = function(self, ox, oy)
		local skin = self.skin
		local vp2, vp3 = self.vp2, self.vp3
		local LE = self.LE

		local res
		if self.enabled then
			res = (self.wid_drawer) and skin.res_pressed or skin.res_idle
		else
			res = skin.res_disabled
		end

		love.graphics.push("all")

		-- Back panel body.
		love.graphics.setColor(res.color_body)
		uiGraphics.drawSlice(res.slice, 0, 0, self.w, self.h)

		-- "Open menu" button.
		love.graphics.setColor(1, 1, 1, 1)
		uiGraphics.drawSlice(res.slc_deco_button, vp3.x, vp3.y, vp3.w, vp3.h)
		uiGraphics.quadShrinkOrCenterXYWH(res.tq_deco_glyph, vp3.x + res.deco_ox, vp3.y + res.deco_oy, vp3.w, vp3.h)

		-- Crop item text.
		uiGraphics.intersectScissor(
			ox + self.x + vp2.x,
			oy + self.y + vp2.y,
			vp2.w,
			vp2.h
		)

		-- Translate into core region, with scrolling offsets applied.
		love.graphics.translate(self.LE_align_ox - self.scr_x, -self.LE_align_oy - self.scr_y)

		-- Text editor component.
		local is_ghost_text = wcInputS.shouldShowGhostText(self)
		local font, col_text
		if is_ghost_text then
			font = skin.font_ghost
			col_text = res.color_ghost_text
		else
			font = self.LE.font
			col_text = res.color_text
		end
		local col_highlight = (self:hasAnyThimble() and context.window_focus) and res.color_highlight_active or res.color_highlight
		local col_caret
		if self.context.window_focus then
			col_caret = self.LE_replace_mode and res.color_caret_replace or res.color_caret_insert
		else
			col_caret = self.LE_replace_mode and res.color_caret_replace_not_focused or res.color_caret_insert_not_focused
		end
		wcInputS.draw(self, is_ghost_text, font, col_highlight, col_text, col_caret)

		love.graphics.pop()

		-- Debug
		--[[
		love.graphics.push()

		love.graphics.setScissor()
		local font = love.graphics.getFont()
		love.graphics.print("self.wid_drawer: " .. tostring(self.wid_drawer), 0, -math.ceil(font:getHeight() * 1.2))

		love.graphics.pop()
		--]]
	end,


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy)
}


return def
