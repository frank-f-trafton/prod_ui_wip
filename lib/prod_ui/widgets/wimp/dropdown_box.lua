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


def.movePrev = commonMenu.widgetMovePrev
def.moveNext = commonMenu.widgetMoveNext
def.moveFirst = commonMenu.widgetMoveFirst
def.moveLast = commonMenu.widgetMoveLast


def.wid_buttonAction = uiShared.dummyFunc
def.wid_buttonAction2 = uiShared.dummyFunc
def.wid_buttonAction3 = uiShared.dummyFunc


--def.uiCall_thimbleAction
--def.uiCall_thimbleAction2


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
			if self.opened and type(self.opened) == "table" then -- XXX: the second condition is a temporary debug check.
				love.graphics.print("WIP <render chosen item>")

			else
				love.graphics.print("WIP <no chosen item>")
			end

			love.graphics.rectangle("line", 0, 0, self.w - 1, self.h - 1)

			love.graphics.pop()
		end,


		--renderLast = function(self, ox, oy) end,
		--renderThimble = function(self, ox, oy)
	},
}


return def
