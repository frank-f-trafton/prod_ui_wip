
-- XXX: Under construction. Copy of `wimp/dropdown_box.lua`

--[[
The main body of a ComboBox (a Dropdown Box with text input).

Closed:

+-----------+-+
| Foobar|   |v| --- Type and manipulate the text. To open the drawer, click the button to the side or press Alt+Down.
+-----------+-+     To cycle through items without opening the drawer, press the up/down keys or turn the mouse-wheel.


Opened:

+-----------+-+
| Foobar    |v| --- Click to close the drawer and return keyboard focus to the text.
+-----------+-+
| Bazbop    |^| --\
| Foobar    +-+   |
|:Jingle::::| |   |
| Bingo     | |   |--- Pop-up widget with list of selections.
| Pogo      +-+   |
| Stove     |v|   |
+-----------+-+ --/


The dropdown menu object is shared by the body and pop-up widget. The pop-up handles the menu's visual appearance
and mouse actions. The body manages the menu's contents. Keyboard actions are split between the body and
the pop-up, with the body holding onto the thimble and forwarding events to the pop-up when it exists.

Unlike similar list widgets, ComboBoxes do not support menu-item icons. ComboBoxes and Dropdowns use the same
drawer widget.

See wimp/dropdown_box.lua for relevant 'TODO's.

The last chosen index is tracked to help the user keep their place in the drawer when repeatedly opening
and closing it. This index should not be referenced by your program logic, however, because it might
have no association with the current input text. Track the field 'self.combo_text' instead.

Two kinds of pop-up menu are associated with this widget: the drawer, and also the standard context menu
when right-clicking on the editable text area. Only one of these may be active at a time, and you cannot
invoke another context menu a selection in the drawer.
--]]


local context = select(1, ...)


local commonMenu = require(context.conf.prod_ui_req .. "logic.common_menu")
local commonWimp = require(context.conf.prod_ui_req .. "logic.common_wimp")
local lgcInputS = context:getLua("shared/lgc_input_s")
local lineEdSingle = context:getLua("shared/line_ed/s/line_ed_s")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = require(context.conf.prod_ui_req .. "logic.wid_shared")


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


def.arrange = commonMenu.arrangeListVerticalTB


def.movePrev = commonMenu.widgetMovePrev
def.moveNext = commonMenu.widgetMoveNext
def.moveFirst = commonMenu.widgetMoveFirst
def.moveLast = commonMenu.widgetMoveLast


def.wid_buttonAction = uiShared.dummyFunc
def.wid_buttonAction2 = uiShared.dummyFunc
def.wid_buttonAction3 = uiShared.dummyFunc


--def.uiCall_thimbleAction
--def.uiCall_thimbleAction2


--- Callback for a change in the ComboBox state.
function def:wid_chosenSelection(index, tbl) -- XXX: change to def:wid_inputChanged(text)
	-- ...
end



function def:addItem(text, pos)

	local skin = self.skin
	local font = skin.font

	local items = self.menu.items

	pos = pos or #items + 1

	-- Assertions.
	-- [[
	if type(text) ~= "string" then uiShared.errBadType(1, text, "string")
	elseif type(pos) ~= "number" then uiShared.errBadType(2, pos, "nil/number") end

	uiShared.assertIntRange(2, pos, 1, #items + 1)
	--]]

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

	-- Assertions
	-- [[
	if type(item_t) ~= "table" then uiShared.errBadType(1, item_t, "table") end
	--]]

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

	-- Assertions
	-- [[
	uiShared.assertNumber(1, item_i)
	--]]

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

	-- Assertions
	-- [[
	if type(item_t) ~= "table" then uiShared.errBadType(1, item_t, "table") end
	--]]

	local item_i = self.menu:getItemIndex(item_t)
	self:setSelectionByIndex(item_i, id)
end


function def:setSelectionByIndex(item_i, id)

	-- Assertions
	-- [[
	uiShared.assertNumber(1, item_i)
	--]]

	local chosen_i_old = self.menu.chosen_i

	self.menu:setSelectedIndex(item_i, id)

	-- XXX: update combo_text
	if id == "chosen_i" and chosen_i_old ~= self.menu.chosen_i then
		self:wid_chosenSelection(self.menu.chosen_i, self.menu.items[self.menu.chosen_i])
	end

	if self.wid_drawer then
		self.wid_drawer:menuChangeCleanup()
	end
end


function def:uiCall_create(inst)

	if self == inst then
		self.visible = true
		self.allow_hover = true
		self.can_have_thimble = true

		widShared.setupViewport(self, 1)
		widShared.setupViewport(self, 2)

		widShared.setupScroll(self)
		widShared.setupDoc(self)

		-- -> commonMenu.instanceSetup(self)
		self.page_jump_size = 4
		self.wheel_jump_size = 64
		self.wrap_selection = false

		self.menu = commonMenu.new()

		lgcInputS.setupInstance(self)

		self.combo_text = "" -- WIP

		-- State flags
		self.enabled = true

		-- When opened, this holds a reference to the pop-up widget.
		self.wid_drawer = false

		-- Index for the last chosen selection.
		-- This is different from `menu.index`, which denotes the current selection in the pop-up menu.
		-- The item contents may be outdated from what is stored in `self.combo_text`.
		self.menu.chosen_i = 0

		self:skinSetRefs()
		self:skinInstall()

		local skin = self.skin

		self.line_ed = lineEdSingle.new(skin.font)

		self:reshape()
	end
end


function def:uiCall_reshape()

	-- Viewport #1 is the chosen item text area.
	-- Viewport #2 is the "open menu" button.

	local skin = self.skin

	widShared.resetViewport(self, 1)
	widShared.carveViewport(self, 1, "border")

	local button_spacing = (skin.button_spacing == "auto") and self.vp_h or skin.button_spacing

	widShared.partitionViewport(self, 1, 2, button_spacing, skin.button_placement)
end


function def:uiCall_update(dt) -- Copied from input/text_box_single.lua, 27 Feb 2024.

	local line_ed = self.line_ed

	local scr_x_old = self.scr_x

	-- Handle update-time drag-scroll.
	if self.press_busy == "text-drag" then
		-- Need to continuously update the selection.
		local needs_update, mouse_drag_x = lgcInputS.mouseDragLogic(self)
		if needs_update then
			self.update_flag = true
		end
		if mouse_drag_x ~= 0 then
			self:scrollDeltaH(mouse_drag_x * dt * 4) -- XXX style/config
			self.update_flag = true
		end
	end

	line_ed:updateCaretBlink(dt)

	self:scrollUpdate(dt)

	-- Force a cache update if the external scroll position is different.
	if scr_x_old ~= self.scr_x then
		self.update_flag = true
	end

	if self.update_flag then
		lgcInputS.updateCaretShape(self)
		self.update_flag = false
	end
end


function def:_openPopUpMenu()

	if not self.wid_drawer then
		if self:hasThimble() then
			love.keyboard.setTextInput(false)
		end

		local skin = self.skin
		local root = self:getTopWidgetInstance()
		local menu = self.menu

		local ax, ay = self:getAbsolutePosition()

		local drawer = root:addChild("wimp/dropdown_pop", {
			skin_id = skin.skin_id_pop,
			wid_ref = self,
			menu = menu,
			x = ax,
			y = ay + self.h,
		})
		self.wid_drawer = drawer
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

	if self:hasThimble() then
		love.keyboard.setTextInput(true)
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
		self:movePrev(self.page_jump_size, true, "chosen_i")
		check_chosen = true

	elseif scancode == "pagedown" then
		self:moveNext(self.page_jump_size, true, "chosen_i")
		check_chosen = true
	end

	if check_chosen then
		if chosen_i_old ~= self.menu.chosen_i then
			self:wid_chosenSelection(self.menu.chosen_i, self.menu.items[self.menu.chosen_i])
		end
		return true
	end
end


function def:uiCall_thimbleTake(inst)

	if self == inst then
		love.keyboard.setTextInput(not self.wid_drawer)
	end
end


function def:uiCall_thimbleRelease(inst)

	print("def:uiCall_thimbleRelease", self, inst, self == inst)

	if self == inst then
		love.keyboard.setTextInput(false)

		if self.wid_drawer then
			-- The drawer should not exist if the dropdown body does not have the UI thimble.
			self:_closePopUpMenu(false)
			return true
		end
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
				-- XXX: tie 'enter' to a widget event (probably wid_action).
				return true

			elseif self:wid_defaultKeyNav(key, scancode, isrepeat) then
				return true

			-- Standard text box controls (caret navigation, etc.)
			else
				return lgcInputS.keyPressLogic(self, key, scancode, isrepeat)
			end
		end
	end
end


function def:uiCall_textInput(inst, text)

	if self == inst then
		lgcInputS.textInputLogic(self, text)
	end
end


--function def:uiCall_pointerHoverOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
--function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)

	if self == inst
	and self.enabled
	and button == self.context.mouse_pressed_button
	then
		if button <= 3 then
			self:tryTakeThimble()
			print("hasInput", love.keyboard.hasTextInput())
		end

		local mx, my = self:getRelativePosition(x, y)

		-- Clicking the text area:
		-- XXX I might need three viewports: one for the scissor box and initial click, one for the text area, and one for the button.
		-- Just compare against viewport 1 for now.
		if widShared.pointInViewport(self, 1, mx, my) then
			-- Propagation is halted when a context menu is created.
			if lgcInputS.mousePressLogic(self, button, mx, my) then
				return true
			end

		-- Clicking the drawer expander button:
		elseif widShared.pointInViewport(self, 2, mx, my) then
			if button == 1 and not self.wid_drawer then
				self:_openPopUpMenu()
				return true
			end
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
					self:wid_chosenSelection(self.menu.chosen_i, self.menu.items[self.menu.chosen_i])
				end
				return true
			end
		end
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
			local font = skin.font

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
			uiGraphics.drawSlice(res.slc_deco_button, self.vp2_x, self.vp2_y, self.vp2_w, self.vp2_h)
			uiGraphics.quadShrinkOrCenterXYWH(skin.tq_deco_glyph, self.vp2_x + res.deco_ox, self.vp2_y + res.deco_oy, self.vp2_w, self.vp2_h)

			-- Crop item text.
			uiGraphics.intersectScissor(
				ox + self.x + self.vp_x,
				oy + self.y + self.vp_y,
				self.vp_w,
				self.vp_h
			)

			-- Draw a highlight rectangle if this widget has the thimble and there is no drawer.
			if not self.wid_drawer and self.context.current_thimble == self then
				love.graphics.setColor(res.color_highlight)
				love.graphics.rectangle("fill", self.vp_x, self.vp_y, self.vp_w, self.vp_h)
			end

			local chosen = self.menu.items[self.menu.chosen_i]
			if chosen then
				love.graphics.setColor(res.color_text)

				-- XXX: Chosen item icon.

				-- Chosen item text.
				love.graphics.setFont(font)
				local xx = self.vp_x + textUtil.getAlignmentOffset(chosen.text, font, skin.text_align, self.vp_w)
				local yy = math.floor(0.5 + self.vp_y + (self.vp_h - font:getHeight()) / 2)
				love.graphics.print(chosen.text, xx, yy)
			end

			-- Debug
			love.graphics.print("self.wid_drawer: " .. tostring(self.wid_drawer), 288, 0)

			-- Debug: working on text input enable/disable in events.
			love.graphics.pop()

			love.graphics.push()
			if love.keyboard.hasTextInput() then
				love.graphics.setColor(1, 0, 0, 1)
			else
				love.graphics.setColor(0, 0, 1, 1)
			end
			love.graphics.circle("fill", 0, 0, 32)

			-- Just debug-print the LineEd internal text for now...
			love.graphics.print(self.line_ed.line, 0, 32)

			love.graphics.pop()
		end,


		--renderLast = function(self, ox, oy) end,
		--renderThimble = function(self, ox, oy)
	},
}


return def
