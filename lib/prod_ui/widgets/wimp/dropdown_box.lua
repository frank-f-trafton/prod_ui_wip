-- XXX: Unfinished.

--[[
The main body of a dropdown box.

Closed:

+-----------+-+
| Foobar    |v| --- To open, click anywhere or press space/enter.
+-----------+-+     Press up/down to change the selection without opening.


Opened:

+-----------+-+
| Foobar    |v|
+-----------+-+
| Bazbop    |^| --\
| Foobar    +-+   |
|:Jingle::::| |   |
| Bingo     | |   |--- Pop-up widget with list of selections.
| Pogo      +-+   |
| Stove     |v|   |
+-----------+-+ --/


The dropdown menu object is shared by the body and pop-up widget. The pop-up handles the menu's visual appearance
and mouse actions. The body manages the menu's contents, and handles keyboard actions.
--]]


local context = select(1, ...)


local commonMenu = require(context.conf.prod_ui_req .. "logic.common_menu")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")
local uiShared = require(context.conf.prod_ui_req .. "ui_shared")
local uiTheme = require(context.conf.prod_ui_req .. "ui_theme")
local widShared = require(context.conf.prod_ui_req .. "logic.wid_shared")


local def = {
	skin_id = "dropdown_box1",
}


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


function def:addItem(text, pos, bijou_id)

	-- XXX: Assertions.

	local skin = self.skin
	local font = skin.font

	local items = self.menu.items

	local item = {}

	item.selectable = true

	item.x, item.y = 0, 0
	item.w = font:getWidth(text)
	item.h = math.floor((font:getHeight() * font:getLineHeight()) + skin.item_pad_v)

	item.text = text
	item.bijou_id = bijou_id
	item.tq_bijou = self.context.resources.tex_quads[bijou_id]

	pos = pos or #items + 1

	if pos < 1 or pos > #items + 1 then
		error("addItem: insert position is out of range.")
	end

	table.insert(items, pos, item)

	self:arrange(pos, #items)

	print("addItem text:", item.text, "y: ", item.y)

	-- If there is no chosen item, assign this one as chosen now.
	if not self.chosen then
		local i, tbl = self.menu:hasAnySelectableItems()
		if i then
			self.chosen = tbl
		end
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

	-- Removed item was the last in the list, and was selected:
	if self.menu.index > #self.menu.items then
		local landing_i = self.menu:findSelectableLanding(#self.menu.items, -1)
		if landing_i then
			self:setSelectionByIndex(landing_i)

		else
			self:setSelectionByIndex(0)
		end

	-- Removed item was not selected, and the selected item appears after the removed item in the list:
	elseif self.menu.index > item_i then
		self.menu.index = self.menu.index - 1
	end

	-- Handle the current chosen item being removed.
	if self.chosen == removed then
		-- XXX: fix this so that the new chosen item is close to the removed one's position.
		local i, new_chosen = self.menu:hasAnySelectableItems()
		self.chosen = new_chosen or false
	end

	self:arrange(item_i, #items)

	return removed_item
end


function def:setSelection(item_t)

	-- NOTE: This affects the selection in the pop-up menu, not the current chosen item in the body.

	-- Assertions
	-- [[
	if type(item_t) ~= "table" then uiShared.errBadType(1, item_t, "table") end
	--]]

	local item_i = self.menu:getItemIndex(item_t)
	self:setSelectionByIndex(item_i)
end


function def:setSelectionByIndex(item_i)

	-- NOTE: This affects the selection in the pop-up menu, not the current chosen item in the body.

	-- Assertions
	-- [[
	uiShared.assertNumber(1, item_i)
	--]]

	self.menu:setSelectedIndex(item_i)
end


function def:setChosen(item_t)

	-- Assertions
	-- [[
	if type(item_t) ~= "table" then uiShared.errBadType(1, item_t, "table") end
	--]]

	-- Confirms the item is in the menu list.
	local item_i = self.menu:getItemIndex(item_t)

	self.chosen = item_t
end


function def:uiCall_create(inst)

	if self == inst then
		self.visible = true
		self.allow_hover = true
		self.can_have_thimble = true

		widShared.setupViewport(self, 1)
		widShared.setupViewport(self, 2)

		self.press_busy = false

		commonMenu.instanceSetup(self)

		self.menu = commonMenu.new()

		self.menu.wrap_selection = false

		-- XXX: dropdown button icon.

		-- State flags
		self.enabled = true
		self.hovered = false
		self.pressed = false

		-- When opened, this holds a reference to the pop-up widget.
		self.opened = false

		-- Reference to the current selection displayed in the dropdown body.
		-- This is different from the menu index, which denotes the current selection in the pop-up menu.
		self.chosen = false

		self:skinSetRefs()
		self:skinInstall()

		self:reshape()
	end
end


function def:uiCall_reshape()

	widShared.resetViewport(self, 1)
	widShared.carveViewport(self, 1, "border")
end


local function openPopUpMenu(self)

	-- XXX: create pop-up widget.
	self.opened = true -- XXX: assign pop-up widget to this field.
end


local function closePopUpMenu(self, update_chosen)

	if update_chosen then
		-- XXX
	end

	-- XXX: destroy pop-up widget.
	self.opened = false
end


local function togglePopUpMenu(self, update_chosen)

	if self.opened then
		closePopUpMenu(self, update_chosen)

	else
		openPopUpMenu(self)
	end
end


--- Called in uiCall_keyPressed(). Implements basic keyboard navigation.
-- @param key The key code.
-- @param scancode The scancode.
-- @param isrepeat Whether this is a key-repeat event.
-- @return true to halt keynav and further bubbling of the keyPressed event.
function def:wid_defaultKeyNav(key, scancode, isrepeat)

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


function def:uiCall_thimbleRelease(inst)

	print("def:uiCall_thimbleRelease", self, inst, self == inst)

	if self == inst then
		-- The pop-up menu should not exist if the dropdown body does not have the UI thimble.
		-- This precludes opening a right-click context menu on an item in the pop-up menu, since
		-- the context menu takes the thimble while it exists.
		-- If you require opening context menus on list items, consider using a plain ListBox
		-- widget instead.
		if self.opened then
			closePopUpMenu(self, false)
			return true
		end
	end
end


function def:uiCall_keyPressed(inst, key, scancode, isrepeat)

	if self == inst then
		-- If there is a pop-up menu, send keyboard events to it.
		if self.opened and type(self.opened) == "table" then -- XXX: WIP: remove temporary second check
			return self.opened:wid_forwardKeyPressed(key, scancode, isrepeat)

		else
			local items = self.menu.items
			local old_index = self.menu.index
			local old_item = items[old_index]

			-- Space opens, but does not close the pop-up.
			if key == "space" then
				if not self.opened then
					openPopUpMenu(self)
					return true
				end

			-- Enter toggles the pop-up, updating the chosen selection when closing.
			elseif key == "return" or key == "kpenter" then
				togglePopUpMenu(self, true)
				return true

			-- Escape closes the menu without updating the chosen selection.
			elseif key == "escape" then
				if self.opened then
					closePopUpMenu(self, false)
					return true
				end

			elseif self:wid_defaultKeyNav(key, scancode, isrepeat) then
				return true
			end
		end
	end
end


function def:uiCall_pointerHoverOn(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)

	if self == inst and self.enabled then
		self.hovered = true
	end
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)

	if self == inst and self.enabled then
		self.hovered = false
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)

	if self == inst
	and self.enabled
	and button == self.context.mouse_pressed_button
	then
		if button <= 3 then
			self:tryTakeThimble()
		end

		if button == 1 then
			if self.opened then
				closePopUpMenu(self)

			else
				openPopUpMenu(self)
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

			love.graphics.push("all")

			if self.opened then
				love.graphics.setColor(1, 0, 0, 1)

			else
				love.graphics.setColor(1, 1, 1, 1)
			end

			-- If a chosen item is defined, render it.
			if self.chosen then
				love.graphics.print(self.chosen.text, 0, 0)

			else
				love.graphics.print("WIP <no chosen item>")
			end

			love.graphics.rectangle("line", 0, 0, self.w - 1, self.h - 1)

			-- Debug
			love.graphics.print("self.opened: " .. tostring(self.opened), 0, 48)

			love.graphics.pop()
		end,


		--renderLast = function(self, ox, oy) end,
		--renderThimble = function(self, ox, oy)
	},
}


return def
