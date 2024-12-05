
--[[
The main body of a dropdown box.

Closed:

┌───────────┬─┐
│ Foobar    │v│ --- To open, click anywhere or press space/enter.
└───────────┴─┘     Press up/down or mouse-wheel to change the selection without opening.


Opened:

┌───────────┬─┐
│ Foobar    │v│
├───────────┼─┤
│ Bazbop    │^│ ══╗
│ Foobar    ├─┤   ║
│:Jingle::::│ │   ║
│ Bingo     │ │   ╠═══ Pop-up widget with list of selections.
│ Pogo      ├─┤   ║
│ Stove     │v│   ║
└───────────┴─┘ ══╝


The dropdown menu object is shared by the body and pop-up widget. The pop-up handles the menu's visual appearance
and mouse actions. The body manages the menu's contents. Keyboard actions are split between the body and
the pop-up, with the body holding onto the thimble and forwarding events to the pop-up when it exists.

TODO: pressing keys to jump to the next item beginning with the key cap label.
^ Probably need a text-input field for additional code points... same for ListBoxes.
Not sure about TreeBoxes.

TODO: menu-item icons.

TODO: right-click and thimble actions on the dropdown body. Note that context menus will not be supported from
the dropdown drawer, since the drawer uses the same "pop-up menu slot" in the WIMP root as context menus. They
should still work when clicking on the body, however.
--]]


local context = select(1, ...)


local commonWimp = require(context.conf.prod_ui_req .. "common.common_wimp")
local lgcMenu = context:getLua("shared/lgc_menu")
local textUtil = require(context.conf.prod_ui_req .. "lib.text_util")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = require(context.conf.prod_ui_req .. "common.wid_shared")


local def = {
	skin_id = "dropdown_box1",
}


def.arrange = lgcMenu.arrangeListVerticalTB


def.movePrev = lgcMenu.widgetMovePrev
def.moveNext = lgcMenu.widgetMoveNext
def.moveFirst = lgcMenu.widgetMoveFirst
def.moveLast = lgcMenu.widgetMoveLast


def.wid_buttonAction = uiShared.dummyFunc
def.wid_buttonAction2 = uiShared.dummyFunc
def.wid_buttonAction3 = uiShared.dummyFunc


--def.uiCall_thimbleAction
--def.uiCall_thimbleAction2


--- Callback for a change in the item choice.
function def:wid_chosenSelection(index, tbl)
	-- ...
end



function def:addItem(text, pos, bijou_id)
	local skin = self.skin
	local font = skin.font

	local items = self.menu.items

	uiShared.type1(1, text, "string")
	uiShared.intRangeEval(2, pos, 1, #items + 1)

	pos = pos or #items + 1

	-- XXX: bijou_id
	--]]

	local item = {}

	item.selectable = true

	item.x, item.y = 0, 0
	item.w = font:getWidth(text)
	item.h = math.floor((font:getHeight() * font:getLineHeight()) + skin.item_pad_v)

	item.text = text
	item.bijou_id = bijou_id
	item.tq_bijou = self.context.resources.tex_quads[bijou_id]

	table.insert(items, pos, item)

	-- If there is no chosen item, assign this one as chosen now.
	if self.menu.chosen_i == 0 then
		local i, tbl = self.menu:hasAnySelectableItems()
		if i then
			self:setSelectionByIndex(i, "chosen_i")
		end
	end

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

		-- -> lgcMenu.instanceSetup(self)
		self.page_jump_size = 4
		self.wheel_jump_size = 64
		self.wrap_selection = false

		self.menu = lgcMenu.new()

		-- XXX: dropdown button icon.

		-- State flags
		self.enabled = true

		-- When opened, this holds a reference to the pop-up widget.
		self.wid_drawer = false

		-- Index for the current selection displayed in the dropdown body.
		-- This is different from `menu.index`, which denotes the current selection in the pop-up menu.
		self.menu.chosen_i = 0

		self:skinSetRefs()
		self:skinInstall()

		self:reshape()
	end
end


function def:uiCall_reshape()
	-- Viewport #1 is the chosen item text area.
	-- Viewport #2 is the decorative button which indicates that this widget is clickable.

	local skin = self.skin

	widShared.resetViewport(self, 1)
	widShared.carveViewport(self, 1, "border")

	local button_spacing = (skin.button_spacing == "auto") and self.vp_h or skin.button_spacing

	widShared.partitionViewport(self, 1, 2, button_spacing, skin.button_placement, true)
end


function def:_openPopUpMenu()
	if not self.wid_drawer then
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

	elseif scancode == "home" then
		self:moveFirst(true, "chosen_i")
		check_chosen = true

	elseif scancode == "end" then
		self:moveLast(true, "chosen_i")
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


function def:uiCall_thimbleRelease(inst)
	print("def:uiCall_thimbleRelease", self, inst, self == inst)

	if self == inst then
		if self.wid_drawer then
			-- The pop-up menu should not exist if the dropdown body does not have the UI thimble.
			-- This precludes opening a right-click context menu on an item in the pop-up menu, since
			-- the context menu takes the thimble while it exists.
			-- If you require opening context menus on list items, consider using a plain ListBox
			-- widget instead.
			self:_closePopUpMenu(false)
			return true
		end
	end
end


function def:uiCall_destroy(inst)
	if self == inst then
		self:_closePopUpMenu(false)
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

			-- Space opens, but does not close the pop-up.
			if key == "space" then
				self:_openPopUpMenu()
				return true

			-- Enter toggles the pop-up, opening it here and closing it in the drawer.
			elseif key == "return" or key == "kpenter" then
				self:_openPopUpMenu()
				return true

			elseif self:wid_defaultKeyNav(key, scancode, isrepeat) then
				return true
			end
		end
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
		end

		if button == 1 then
			if not self.wid_drawer then
				self:_openPopUpMenu()

				return true
			end
		end
	end
end


function def:uiCall_pointerDrag(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
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

			-- XXX: Decorative button.
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

			love.graphics.pop()
		end,


		--renderLast = function(self, ox, oy) end,
		--renderThimble = function(self, ox, oy)
	},
}


return def
