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


The menu object is shared by the body and pop-up widget. The pop-up handles the menu's visual appearance and
mouse actions. The body manages the menu's contents.

Unlike similar list widgets, ComboBoxes do not support menu-item icons. ComboBoxes and Dropdowns use the same
drawer widget.

See wimp/dropdown_box.lua for relevant 'TODO's.

The last chosen index is tracked to help the user keep their place in the drawer when repeatedly opening
and closing it. This index should not be referenced by your program logic, however, because it might
have no association with the current input text. Use `self:getDisplayText()` or `self:getInternalText()`
instead.

Two kinds of pop-up menu are associated with this widget: the drawer, and also the standard context menu
when right-clicking on the editable text area. Only one of these may be active at a time, and you cannot
invoke another context menu on the selection in the drawer.
--]]


local context = select(1, ...)


local commonWimp = require(context.conf.prod_ui_req .. "common.common_wimp")
local lgcInputS = context:getLua("shared/lgc_input_s")
local lgcMenu = context:getLua("shared/lgc_menu")
local lineEdS = context:getLua("shared/line_ed/s/line_ed_s")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widDebug = require(context.conf.prod_ui_req .. "common.wid_debug")
local widShared = require(context.conf.prod_ui_req .. "common.wid_shared")


local def = {
	skin_id = "combo_box1",
}


widShared.scrollSetMethods(def)
-- No integrated scroll bars for single-line text inputs.


lgcInputS.setupDef(def)


def.scrollGetCaretInBounds = lgcInputS.method_scrollGetCaretInBounds
def.updateDocumentDimensions = lgcInputS.method_updateDocumentDimensions
def.updateAlignOffset = lgcInputS.method_updateAlignOffset
def.pop_up_def = lgcInputS.pop_up_def


def.arrange = lgcMenu.arrangeListVerticalTB


def.movePrev = lgcMenu.widgetMovePrev
def.moveNext = lgcMenu.widgetMoveNext
def.moveFirst = lgcMenu.widgetMoveFirst
def.moveLast = lgcMenu.widgetMoveLast
def.movePageUp = lgcMenu.widgetMovePageUp
def.movePageDown = lgcMenu.widgetMovePageDown


local function refreshLineEdText(self)
	local chosen_tbl = self.menu.items[self.menu.chosen_i]
	local line_ed = self.line_ed

	if chosen_tbl then
		self:replaceText(chosen_tbl.text)
		line_ed.hist:clearAll()
		self.input_category = false

		if self.allow_highlight then
			self:highlightAll()
		end
		lgcInputS.updateCaretShape(self)
	end
end


--- Callback for a change in the ComboBox state.
function def:wid_inputChanged(str)
	-- ...
end


-- Callback for when the user types enter.
function def:wid_action(str)

end


-- Callback for when the user navigates away from this widget
function def:wid_thimble1Release(str)

end


function def:addItem(text, pos)
	local skin = self.skin
	local font = skin.font
	local items = self.menu.items

	uiShared.type1(1, text, "string")
	uiShared.intRangeEval(2, pos, 1, #items + 1)

	pos = pos or #items + 1

	local item = {}

	-- All ComboBox items should be selectable.
	item.selectable = true

	item.x, item.y = 0, 0
	item.w = font:getWidth(text)
	item.h = math.floor((font:getHeight() * font:getLineHeight()) + skin.item_pad_v)

	item.text = text

	table.insert(items, pos, item)

	-- (Unlike Dropdown, we do not assign a default chosen index here if the list was previously empty.)

	if self.wid_drawer then
		self.wid_drawer:menuChangeCleanup()
	end

	return item
end


function def:removeItem(item_t)
	uiShared.type1(1, item_t, "table")

	local item_i = self.menu:getItemIndex(item_t)

	local removed_item = self:removeItemByIndex(item_i)

	return removed_item
end



local function removeItemIndexCleanup(self, item_i, id)
	-- Removed item was the last in the list, and was selected:
	if self.menu[id] > #self.menu.items then
		local landing_i = self.menu:findSelectableLanding(#self.menu.items, -1)
		self:setSelectionByIndex(landing_i or 0, id)

	-- Removed item was not selected, and the selected item appears after the removed item in the list:
	elseif self.menu[id] > item_i then
		self.menu[id] = self.menu[id] - 1
	end

	-- Handle the current selection being removed.
	if self.menu[id] == item_i then
		local landing_i = self.menu:findSelectableLanding(#self.menu.items, -1) or self.menu:findSelectableLanding(#self.menu.items, 1)
		self.menu[id] = landing_i or 0
	end
end


function def:removeItemByIndex(item_i)
	uiShared.intGE(1, item_i, 0)

	local items = self.menu.items
	local removed_item = items[item_i]
	if not removed_item then
		error("no item to remove at index: " .. tostring(item_i))
	end

	local removed = table.remove(items, item_i)

	removeItemIndexCleanup(self, item_i, "index")
	removeItemIndexCleanup(self, item_i, "chosen_i")

	if self.wid_drawer then
		self.wid_drawer:menuChangeCleanup()
	end

	return removed_item
end


function def:setSelection(item_t, id)
	uiShared.type1(1, item_t, "table")

	local item_i = self.menu:getItemIndex(item_t)
	self:setSelectionByIndex(item_i, id)
end


function def:setSelectionByIndex(item_i, id)
	uiShared.intGE(1, item_i, 0)

	local chosen_i_old = self.menu.chosen_i

	self.menu:setSelectedIndex(item_i, id)

	if id == "chosen_i" and chosen_i_old ~= self.menu.chosen_i then
		refreshLineEdText(self)
		self:wid_inputChanged(self.line_ed.line)
	end

	if self.wid_drawer then
		self.wid_drawer:menuChangeCleanup()
	end
end


--- Gets the internal text string.
function def:getInternalText()
	return self.line_ed.line
end


--- Gets the display text string (which may be modified to show different UTF-8 code points).
function def:getDisplayText()
	return self.line_ed.disp_text
end


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true
	self.can_have_thimble = true

	widShared.setupViewports(self, 3)

	widShared.setupScroll(self)
	widShared.setupDoc(self)

	-- -> lgcMenu.instanceSetup(self)
	self.MN_page_jump_size = 4
	self.MN_wrap_selection = false

	self.menu = lgcMenu.new()

	lgcInputS.setupInstance(self)

	-- State flags
	self.enabled = true
	self.hovered = false

	-- When opened, this holds a reference to the pop-up widget.
	self.wid_drawer = false

	-- Index for the last chosen selection.
	-- This is different from `menu.index`, which denotes the current selection in the pop-up menu.
	-- The item contents may be outdated from what is stored in the LineEditor object.
	self.menu.chosen_i = 0

	self:skinSetRefs()
	self:skinInstall()

	local skin = self.skin

	self.line_ed = lineEdS.new(skin.font)

	self:reshape()
end


function def:uiCall_reshape()
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
end


function def:uiCall_update(dt)
	-- Handle update-time drag-scroll.
	if self.press_busy == "text-drag" then
		-- Need to continuously update the selection.
		local mouse_drag_x = lgcInputS.mouseDragLogic(self)
		if mouse_drag_x ~= 0 then
			self:scrollDeltaH(mouse_drag_x * dt * 4) -- XXX style/config
		end
	end

	lgcInputS.updateCaretBlink(self, dt)

	self:scrollUpdate(dt)
end


function def:_openPopUpMenu()
	if not self.wid_drawer then
		local skin = self.skin
		local root = self:getTopWidgetInstance()
		local menu = self.menu

		local ax, ay = self:getAbsolutePosition()

		local drawer = root:addChild("wimp/dropdown_pop")
		drawer.skin_id = skin.skin_id_pop
		drawer.menu = menu
		drawer:initialize()
		drawer.x = ax
		drawer.y = ay + self.h
		drawer.wid_ref = self

		self.wid_drawer = drawer

		self.chain_next = drawer
		drawer.chain_prev = self

		commonWimp.assignPopUp(self, drawer)

		self:setSelectionByIndex(menu.chosen_i)

		drawer:resize()
		drawer:reshape()
		drawer:menuChangeCleanup()
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
	local chosen_i_old = self.menu.chosen_i

	if scancode == "up" then
		self:movePrev(1, true, "chosen_i")
		check_chosen = true

	elseif scancode == "down" then
		self:moveNext(1, true, "chosen_i")
		check_chosen = true

	elseif scancode == "pageup" then
		--self:movePageUp(true, "chosen_i")
		self:movePrev(self.MN_page_jump_size, true, "chosen_i")
		check_chosen = true

	elseif scancode == "pagedown" then
		--self:movePageDown(true, "chosen_i")
		self:moveNext(self.MN_page_jump_size, true, "chosen_i")
		check_chosen = true
	end

	if check_chosen then
		if chosen_i_old ~= self.menu.chosen_i then
			refreshLineEdText(self)
			self:wid_inputChanged(self.line_ed.line)
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


function def:uiCall_thimble1Release(inst)
	print("def:uiCall_thimble1Release", self, inst, self == inst)

	if self == inst then
		if self.wid_drawer then
			-- The drawer should not exist if the dropdown body does not have thimble1.
			self:_closePopUpMenu(false)
			return true
		end

		self:wid_thimble1Release(self.line_ed.line)
	end
end


function def:uiCall_destroy(inst)
	if self == inst then
		-- Destroy pop-up menu (either kind) if it exists in reference to this widget.
		commonWimp.checkDestroyPopUp(self)
		--self:_closePopUpMenu(false)
		-- XXX: test the above change.
	end
end


function def:uiCall_keyPressed(inst, key, scancode, isrepeat)
	if self == inst then
		-- Forward keyboard events to the pop-up menu.
		if self.wid_drawer then
			return self.wid_drawer:wid_forwardKeyPressed(key, scancode, isrepeat)
		else
			local items = self.menu.items
			local old_index = self.menu.index
			local old_item = items[old_index]

			-- Alt+Down opens the pop-up.
			if key == "down" and context.key_mgr.mod["alt"] then
				self:_openPopUpMenu()
				return true

			elseif key == "return" or key == "kpenter" then
				self:wid_action(self.line_ed.line)
				return true

			elseif self:wid_defaultKeyNav(key, scancode, isrepeat) then
				return true

			-- Standard text box controls (caret navigation, etc.)
			else
				local old_line = self.line_ed.line
				local rv = lgcInputS.keyPressLogic(self, key, scancode, isrepeat)
				if old_line ~= self.line_ed.line then
					self:wid_inputChanged(self.line_ed.line)
				end
				return rv
			end
		end
	end
end


function def:uiCall_textInput(inst, text)
	if self == inst then
		local old_line = self.line_ed.line
		local rv = lgcInputS.textInputLogic(self, text)
		if old_line ~= self.line_ed.line then
			self:wid_inputChanged(self.line_ed.line)
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
			self:setCursorLow(self.skin.cursor_on)
		else
			self:setCursorLow()
		end
	end
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		if self.enabled then
			self.hovered = false
			self:setCursorLow()
		end
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self == inst
	and self.enabled
	and button == self.context.mouse_pressed_button
	then
		if button <= 3 then
			self:tryTakeThimble1()
			print("hasInput", love.keyboard.hasTextInput())
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
			if lgcInputS.mousePressLogic(self, button, mx, my) then
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
		-- Cycle menu options if the drawer is closed.
		if not self.wid_drawer then

			local check_chosen = false
			local chosen_i_old = self.menu.chosen_i

			if y > 0 then
				self:movePrev(y, true, "chosen_i")
				check_chosen = true

			elseif y < 0 then
				self:moveNext(math.abs(y), true, "chosen_i")
				check_chosen = true
			end

			if check_chosen then
				if chosen_i_old ~= self.menu.chosen_i then
					refreshLineEdText(self)
					self:wid_inputChanged(self.line_ed.line)
				end
				return true
			end
		end
	end
end


def.default_skinner = {
	schema = {
		main = {
			button_spacing = "scaled-int",
			item_pad_v = "scaled-int",
			res_idle = "&res",
			res_pressed = "&res",
			res_disabled = "&res"
		},
		res = {
			deco_ox = "scaled-int",
			deco_oy = "scaled-int"
		}
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
		--local font = skin.font
		local line_ed = self.line_ed

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

		-- XXX: "Open menu" button.
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

		-- Text editor component.
		local color_caret = self.replace_mode and res.color_caret_replace or res.color_caret_insert
		lgcInputS.draw(
			self,
			res.color_highlight,
			skin.font_ghost,
			res.color_text,
			line_ed.font,
			self.context.window_focus and not self.wid_drawer and color_caret -- Don't draw caret if drawer is pulled out. It's annoying.
		)

		love.graphics.pop()

		-- Debug
		love.graphics.push()

		love.graphics.print("self.wid_drawer: " .. tostring(self.wid_drawer), 288, 0)

		--[[
		-- Debug: working on text input enable/disable in events.
		if love.keyboard.hasTextInput() then
			love.graphics.setColor(1, 0, 0, 1)
		else
			love.graphics.setColor(0, 0, 1, 1)
		end
		love.graphics.circle("fill", 0, 0, 32)
		--]]

		love.graphics.pop()

		--[[
		widDebug.debugDrawViewport(self, 1)
		widDebug.debugDrawViewport(self, 2)
		widDebug.debugDrawViewport(self, 3)
		--]]
	end,


	--renderLast = function(self, ox, oy) end,
	--renderThimble = function(self, ox, oy)
}


return def
