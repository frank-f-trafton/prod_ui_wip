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
local lgcInputS = context:getLua("shared/lgc_input_s")
local lgcMenu = context:getLua("shared/lgc_menu")
local lgcPopUps = context:getLua("shared/lgc_pop_ups")
local lineEdS = context:getLua("shared/line_ed/s/line_ed_s")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = context:getLua("core/wid_shared")


local def = {
	skin_id = "combo_box1",
	--TODO: text_align_h = "left", -- "left", "center", "right"
}


lgcMenu.attachMenuMethods(def)
widShared.scrollSetMethods(def)
-- No integrated scroll bars for single-line text inputs.


lgcInputS.setupDef(def)


def.updateAlignOffset = lgcInputS.method_updateAlignOffset
def.pop_up_def = lgcInputS.pop_up_def


local _arrange_tb = lgcMenu.arrangers["list-tb"]
function def:arrangeItems(first, last)
	_arrange_tb(self, 1, true, first, last)
end


def.movePrev = lgcMenu.widgetMovePrev
def.moveNext = lgcMenu.widgetMoveNext
def.moveFirst = lgcMenu.widgetMoveFirst
def.moveLast = lgcMenu.widgetMoveLast
def.movePageUp = lgcMenu.widgetMovePageUp
def.movePageDown = lgcMenu.widgetMovePageDown


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

	uiAssert.type1(1, text, "string")
	uiAssert.intRangeEval(2, pos, 1, #items + 1)

	pos = pos or #items + 1

	local item = setmetatable({}, _mt_item)

	item.text = text
	-- ComboBox items do not support icons.

	table.insert(items, pos, item)

	-- Unlike Dropdown, we do not assign a default chosen index here if the list was previously empty.

	return item
end


function def:removeItem(item_t)
	uiAssert.type1(1, item_t, "table")

	local item_i = self:menuGetItemIndex(item_t)
	local removed_item = self:removeItemByIndex(item_i)
	return removed_item
end


function def:removeItemByIndex(item_i)
	uiAssert.intGE(1, item_i, 0)

	local items = self.MN_items
	local removed_item = items[item_i]
	if not removed_item then
		error("no item to remove at index: " .. tostring(item_i))
	end

	local removed = table.remove(items, item_i)

	lgcMenu.removeItemIndexCleanup(self, item_i, "MN_index")

	return removed_item
end


function def:setSelection(item_t)
	uiAssert.type1(1, item_t, "table")

	local item_i = self:menuGetItemIndex(item_t)
	self:setSelectionByIndex(item_i)
end


function def:setSelectionByIndex(item_i)
	uiAssert.intGE(1, item_i, 0)

	local index_old = self.MN_index

	self:menuSetSelectedIndex(item_i)

	if index_old ~= self.MN_index then
		refreshLineEdText(self)
		self:wid_inputChanged(self.LE.line)
	end
end


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 1

	widShared.setupViewports(self, 3)

	widShared.setupScroll(self, -1, -1)
	widShared.setupDoc(self)

	self.press_busy = false

	lgcMenu.setup(self)
	self.MN_page_jump_size = 4
	self.MN_wrap_selection = false

	-- State flags
	self.enabled = true
	self.hovered = false

	-- When opened, this holds a reference to the pop-up widget.
	self.wid_drawer = false

	lgcInputS.setupInstance(self, "single")

	self:skinSetRefs()
	self:skinInstall()
	self:applyAllSettings()
end


function def:uiCall_reshapePre()
	-- Viewport #1 is for text placement and offsetting.
	-- Viewport #2 is the text scissor-box boundary.
	-- Viewport #3 is the "open menu" button.

	local skin = self.skin

	widShared.resetViewport(self, 1)
	widShared.carveViewport(self, 1, skin.box.border)

	local button_spacing = (skin.button_spacing == "auto") and self.vp_h or skin.button_spacing
	widShared.partitionViewport(self, 1, 3, button_spacing, skin.button_placement, true)

	widShared.copyViewport(self, 1, 2)
	widShared.carveViewport(self, 1, skin.box.margin)

	self:scrollClampViewport()

	editWidS.generalUpdate(self, true, true, false, true)

	return true
end


function def:uiCall_update(dt)
	editWid.updateCaretBlink(self, dt)

	local scr_x_old, scr_y_old = self.scr_x, self.scr_y
	local do_update

	-- Handle update-time drag-scroll.
	if self.press_busy == "text-drag" then
		if lgcInputS.mouseDragLogic(self) then
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
		local root = self:getRootWidget()

		local ax, ay = self:getAbsolutePosition()

		local drawer = root:addChild("wimp/dropdown_pop", nil, skin.skin_id_pop, self)
		drawer.x = ax
		drawer.y = ay + self.h
		self.wid_drawer = drawer
		self.chain_next = drawer
		drawer.chain_prev = self
		drawer:writeSetting("show_icons", false)

		for i, item in ipairs(self.MN_items) do
			local new_item = drawer:addItem(item.text, nil, item.icon_id, true)
			new_item.source_item = item
		end

		local lgcWimp = self.context:getLua("shared/lgc_wimp")
		lgcWimp.assignPopUp(self, drawer)

		drawer:setSelectionByIndex(self.MN_index)

		drawer:reshape()
		drawer:centerSelectedItem(true)

		lgcPopUps.checkBlocking(drawer)

		drawer:tryTakeThimble2()
	end
end


function def:_closePopUpMenu(update_chosen)
	local wid_drawer = self.wid_drawer
	if wid_drawer and not wid_drawer._dead then
		self.wid_drawer:_closeSelf(update_chosen)
		self.chain_next = false
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


--- Called in uiCall_keyPressed(). Implements basic keyboard navigation.
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


function def:uiCall_thimbleTopTake(inst)
	if self == inst then
		love.keyboard.setTextInput(true)
	end
end


function def:uiCall_thimbleTopRelease(inst)
	if self == inst then
		love.keyboard.setTextInput(false)
	end
end


function def:uiCall_thimble1Take(inst)
	if self == inst then
		lgcInputS.thimble1Take(self)
	end
end


function def:uiCall_thimble1Release(inst)
	if self == inst then
		lgcInputS.thimble1Release(self)

		if self.wid_drawer then
			-- The drawer should not exist if the dropdown body does not have thimble1.
			self:_closePopUpMenu(false)
		end

		self:wid_thimble1Release(self.LE.line)
	end
end


function def:uiCall_destroy(inst)
	if self == inst then
		-- Destroy pop-up menu (either kind) if it exists in reference to this widget.
		local lgcWimp = self.context:getLua("shared/lgc_wimp")
		lgcWimp.checkDestroyPopUp(self)
		--self:_closePopUpMenu(false)
		-- XXX: test the above change.
	end
end


function def:uiCall_keyPressed(inst, key, scancode, isrepeat, hot_key, hot_scan)
	if self == inst then
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
				local rv = lgcInputS.keyPressLogic(self, key, scancode, isrepeat, hot_key, hot_scan)
				if old_line ~= self.LE.line then
					self:wid_inputChanged(self.LE.line)
				end
				return rv
			end
		end
	end
end


function def:uiCall_textInput(inst, text)
	if self == inst then
		local old_line = self.LE.line
		local rv = lgcInputS.textInputLogic(self, text)
		if old_line ~= self.LE.line then
			self:wid_inputChanged(self.LE.line)
		end
		return rv
	end
end


function def:uiCall_pointerHoverOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst
	and self.enabled
	then
		self.hovered = true
	end
end


function def:uiCall_pointerHover(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst
	and self.enabled
	then
		local mx, my = self:getRelativePosition(mouse_x, mouse_y)

		if widShared.pointInViewport(self, 1, mx, my) then
			self.cursor_hover = self.skin.cursor_on
		else
			self.cursor_hover = nil
		end
	end
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		if self.enabled then
			self.hovered = false
			self.cursor_hover = nil
		end
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self == inst
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
		if widShared.pointInViewport(self, 1, mx, my) then
			-- Propagation is halted when a context menu is created.
			if lgcInputS.mousePressLogic(self, button, mx, my, had_thimble1_before) then
				return true
			end

		-- Clicking the drawer expander button: open drawer, but only
		-- if we didn't just close it.
		elseif button == 1
		and not closed_drawer
		and widShared.pointInViewport(self, 3, mx, my)
		then
			self:_openPopUpMenu()
			return true
		end
	end
end


function def:uiCall_pointerDrag(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
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


function def:uiCall_pointerUnpress(inst, x, y, button, istouch, presses)
	if self == inst then
		if button == 1 and button == self.context.mouse_pressed_button then
			self.press_busy = false
		end
	end
end


function def:uiCall_pointerWheel(inst, x, y)
	if self == inst then
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


local check, change = uiTheme.check, uiTheme.change


local function _checkRes(skin, k)
	uiTheme.pushLabel(k)

	local res = check.getRes(skin, k)
	check.slice(res, "slice")
	check.slice(res, "slc_deco_button")
	check.quad(res, "tq_deco_glyph")
	check.colorTuple(res, "color_body")
	check.colorTuple(res, "color_text")
	check.colorTuple(res, "color_highlight")
	check.colorTuple(res, "color_highlight_active")
	check.colorTuple(res, "color_caret_insert")
	check.colorTuple(res, "color_caret_replace")
	check.number(res, "deco_ox")
	check.number(res, "deco_oy")

	uiTheme.popLabel()
end


local function _changeRes(skin, k, scale)
	uiTheme.pushLabel(k)

	local res = check.getRes(skin, k)
	change.numberScaled(res, "deco_ox", scale)
	change.numberScaled(res, "deco_oy", scale)

	uiTheme.popLabel()
end


def.default_skinner = {
	validate = function(skin)
		-- The SkinDef ID for pop-ups made by this widget.
		check.type(skin, "skin_id_pop", "string")

		check.box(skin, "box")

		check.loveType(skin, "font", "Font")
		check.loveType(skin, "font_ghost", "Font")

		check.type(skin, "cursor_on", "nil", "string")

		-- Horizontal size of the expander button.
		-- "auto": use Viewport #2's height.
		check.numberOrExact(skin, "button_spacing", nil, nil, "auto")

		-- Placement of the expander button.
		check.exact(skin, "button_placement", "left", "right")

		check.integer(skin, "item_pad_v", 0)

		_checkRes(skin, "res_idle")
		_checkRes(skin, "res_pressed")
		_checkRes(skin, "res_disabled")
	end,


	transform = function(skin, scale)
		change.integerScaled(skin, "item_pad_v", scale)
		change.numberScaled(skin, "button_spacing", scale)

		_changeRes(skin, "res_idle", scale)
		_changeRes(skin, "res_pressed", scale)
		_changeRes(skin, "res_disabled", scale)
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
		uiGraphics.drawSlice(res.slc_deco_button, self.vp3_x, self.vp3_y, self.vp3_w, self.vp3_h)
		uiGraphics.quadShrinkOrCenterXYWH(res.tq_deco_glyph, self.vp3_x + res.deco_ox, self.vp3_y + res.deco_oy, self.vp3_w, self.vp3_h)

		-- Crop item text.
		uiGraphics.intersectScissor(
			ox + self.x + self.vp2_x,
			oy + self.y + self.vp2_y,
			self.vp2_w,
			self.vp2_h
		)

		-- Translate into core region, with scrolling offsets applied.
		love.graphics.translate(self.LE_align_ox - self.scr_x, -self.LE_align_oy - self.scr_y)

		-- Text editor component.
		local color_caret = self.LE_replace_mode and res.color_caret_replace or res.color_caret_insert
		local is_active = self == self.context.thimble1
		local col_highlight = is_active and res.color_highlight_active or res.color_highlight
		lgcInputS.draw(
			self,
			col_highlight,
			skin.font_ghost,
			res.color_text,
			LE.font,
			self.context.window_focus and not self.wid_drawer and color_caret -- Don't draw caret if drawer is pulled out. It's annoying.
		)

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
