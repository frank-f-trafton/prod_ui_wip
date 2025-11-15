local context = select(1, ...)


local wcButton2 = {}


local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiDummy = require(context.conf.prod_ui_req .. "ui_dummy")
local uiTable = require(context.conf.prod_ui_req .. "ui_table")


local _nm_button_mode = uiTable.newNamedMapV("ButtonMode", "push-release", "push", "repeat", "double", "sticky")


-- Called when the user left-clicks on the button or presses 'space', 'return' or 'kpenter' while the button has thimble focus.
-- Args: (<implicit self>)
wcButton2.wid_buttonAction = uiDummy.func


-- Called when the user right-clicks on the button, or presses the 'application' KeyConstant while the button has thimble focus.
-- Args: (<implicit self>)
wcButton2.wid_buttonAction2 = uiDummy.func


-- Called when the user middle-clicks on the button. There is no built-in keyboard trigger.
-- Args: (<implicit self>)
wcButton2.wid_buttonAction3 = uiDummy.func


local methods = {}
wcButton2.methods = methods



function methods:buttonSetMode(mode)
	uiAssert.namedMap(1, mode, _nm_button_mode)

	self.BT_mode = mode

	self.hovered = false
	self.pressed = false
	self.cursor_hover = nil
	self.cursor_press = nil

	return self
end


function methods:buttonSetEnabled(enabled)
	self.BT_enabled = not not enabled

	if not self.BT_enabled then
		self.hovered = false
		-- Do not reset 'pressed' state when disabling sticky buttons.
		if self.BT_mode ~= "sticky" then
			self.pressed = false
		end
		self.cursor_hover = nil
		self.cursor_press = nil
	end

	return self
end


function methods:buttonSetSticking(sticking)
	if self.BT_mode ~= "sticky" then
		error("button is not in sticky mode.")
	end

	self.pressed = not not sticking
end



return wcButton2
