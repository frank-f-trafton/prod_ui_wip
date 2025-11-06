--[[
Widget Component: Button

Usage:

* Attach functions to widget defs or instances and call them with the method (colon) syntax.
--]]


local context = select(1, ...)


local wcButton = {}


local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiDummy = require(context.conf.prod_ui_req .. "ui_dummy")


-- * Widget Action Callbacks *


-- Called when the user left-clicks on the button or presses 'space', 'return' or 'kpenter' while the button has thimble focus.
-- Args: (<implicit self>)
wcButton.wid_buttonAction = uiDummy.func


-- Called when the user right-clicks on the button, or presses the 'application' KeyConstant while the button has thimble focus.
-- Args: (<implicit self>)
wcButton.wid_buttonAction2 = uiDummy.func


-- Called when the user middle-clicks on the button. There is no built-in keyboard trigger.
-- Args: (<implicit self>)
wcButton.wid_buttonAction3 = uiDummy.func


-- * Widget Plug-In Methods *


--- Enables or disables a button.
function wcButton.setEnabled(self, enabled)
	self.enabled = not not enabled

	if not self.enabled then
		self.hovered = false
		self.pressed = false
		self.cursor_hover = nil
		self.cursor_press = nil
	end

	return self
end


--- Enables or disables a sticky button.
function wcButton.setEnabledSticky(self, enabled)
	self.enabled = not not enabled

	if not self.enabled then
		self.hovered = false
		-- Do not reset 'pressed' state when disabling sticky buttons.
	end

	return self
end


--- Sets the 'pressed' state of a sticky button.
function wcButton.setPressedSticky(self, pressed)
	self.pressed = not not pressed

	return self
end


--- Sets or unsets a checkbox.
function wcButton.setChecked(self, checked)
	self.checked = not not checked

	return self
end


--- Sets the value of a multi-state checkbox.
function wcButton.setValue(self, value)
	uiAssert.integerRange(2, value, 1, self.value_max)

	self.value = value

	return self
end


--- Increments or decrements the value of a multi-state checkbox, wrapping when the first or last state is passed.
function wcButton.rollValue(self, dir)
	dir = dir or 1
	if dir ~= -1 and dir ~= 1 then error("invalid roll direction") end
	self.value = ((self.value-1 + dir) % self.value_max) + 1

	return self
end


--- Sets the maximum value for multi-state checkboxes.
function wcButton.setMaxValue(self, max)
	uiAssert.integerGE(1, max, 1)

	self.value_max = max

	return self
end


--- Turns off a radio button, plus all sibling radio buttons with the same group ID.
function wcButton.uncheckAllRadioSiblings(self)
	local parent = self.parent

	-- No parent (this is the root, or the widget data is corrupt): just uncheck self.
	if not parent then
		self.checked = false
	else
		for i, sibling in ipairs(parent.children) do
			if sibling.is_radio_button and sibling.radio_group == self.radio_group then
				sibling.checked = false
			end
		end
	end

	return self
end


--- Sets or unsets a radio button. All radio button siblings with the same group ID will be turned off as a side effect.
function wcButton.setCheckedRadio(self, checked)
	wcButton.uncheckAllRadioSiblings(self)
	self.checked = not not checked

	return self
end


--- Sets a radio button within a group of siblings, choosing the first radio button where `self[key] == value`.
-- @param self The widget.
-- @param key The key to check.
-- @param value The value to check.
-- @return self (for chaining).
function wcButton.setCheckedRadioConditional(self, key, value)
	local parent = self:getParent()
	local siblings = parent.children

	for i, wid in ipairs(parent.children) do
		if wid.is_radio_button and wid.radio_group == self.radio_group and wid[key] == value then
			wid:setChecked(true)
			break
		end
	end

	return self
end


-- * ProdUI Callbacks *


--- Mouse callback for when the cursor overlaps a widget.
function wcButton.uiCall_pointerHoverOn(self, inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		if self.enabled then
			self.hovered = true
			self.cursor_hover = self.skin.cursor_on
		end
	end
end


--- Mouse callback for when the cursor overlaps a sticky button.
function wcButton.uiCall_pointerHoverOnSticky(self, inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		if self.enabled then
			if not self.pressed then
				self.hovered = true
				self.cursor_hover = self.skin.cursor_on
			end
		end
	end
end


--- Mouse callback for when the cursor leaves a widget.
function wcButton.uiCall_pointerHoverOff(self, inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		if self.enabled then
			self.hovered = false
			self.cursor_hover = nil
		end
	end
end


--- Mouse callback for pressing normal buttons (whose primary actions don't activate upon click-down).
function wcButton.uiCall_pointerPress(self, inst, x, y, button, istouch, presses)
	if self == inst then
		if self.enabled then
			if button == self.context.mouse_pressed_button then
				if button <= 3 then
					self:tryTakeThimble1()
				end

				if button == 1 then
					self.pressed = true
					self.cursor_press = self.skin.cursor_press

				elseif button == 2 then
					-- Instant second action.
					self:wid_buttonAction2()

				elseif button == 3 then
					-- Instant tertiary action.
					self:wid_buttonAction3()
				end
			end
		end
	end
end


--- Mouse callback for pressing buttons which activate upon first click-down.
function wcButton.uiCall_pointerPressActivate(self, inst, x, y, button, istouch, presses)
	if self == inst then
		if self.enabled then
			if button == self.context.mouse_pressed_button then
				if button <= 3 then
					self:tryTakeThimble1()
				end

				if button == 1 then
					self.pressed = true
					self.cursor_press = self.skin.cursor_press

					-- First-press action.
					self:wid_buttonAction()

				elseif button == 2 then
					-- Instant secondary action.
					self:wid_buttonAction2()

				elseif button == 3 then
					-- Instant tertiary action.
					self:wid_buttonAction3()
				end
			end
		end
	end
end


--- Mouse callback for pressing buttons which activate upon double-click.
function wcButton.uiCall_pointerPressDoubleClick(self, inst, x, y, button, istouch, presses)
	if self == inst then
		if self.enabled then
			if button == self.context.mouse_pressed_button then
				if button <= 3 then
					self:tryTakeThimble1()
				end

				if button == 1 then
					if self.context.cseq_widget == self and self.context.cseq_presses % 2 == 0 then

						-- First-press action.
						self:wid_buttonAction()
					end

				elseif button == 2 then
					-- Instant secondary action.
					self:wid_buttonAction2()

				elseif button == 3 then
					-- Instant tertiary action.
					self:wid_buttonAction3()
				end
			end
		end
	end
end


--- Mouse callback for pressing buttons which activate repeatedly while held down.
function wcButton.uiCall_pointerPressRepeat(self, inst, x, y, button, istouch, reps)
	if self == inst then
		if self.enabled then
			if button == self.context.mouse_pressed_button then
				if button == 1 then
					-- Repeat-press actions
					self:wid_buttonAction()
				end

				-- Secondary and tertiary actions do not repeat.
			end
		end
	end
end


--- Mouse callback for pressing buttons which activate upon first click-down, but which do not have a repeat-held action.
function wcButton.uiCall_pointerPressSticky(self, inst, x, y, button, istouch, presses)
	if self == inst then
		if self.enabled then
			if button == self.context.mouse_pressed_button then
				if button <= 3 then
					self:tryTakeThimble1()
				end

				if button == 1 then
					-- Only run the action if the button is not already in a pressed state.
					if not self.pressed then
						self.pressed = true

						-- Do not set the high cursor ID.
						-- Clear the low cursor ID.
						self.cursor_hover = nil

						-- Press action
						self:wid_buttonAction()
					end

				elseif button == 2 then
					-- Instant secondary action.
					-- NOTE: This callback runs even if the sticky button is already depressed.
					self:wid_buttonAction2()

				elseif button == 3 then
					-- Instant tertiary action.
					-- NOTE: This callback runs even if the sticky button is already depressed.
					self:wid_buttonAction3()
				end
			end
		end
	end
end


--- Mouse callback for releasing buttons which activate upon click-up (while hovered over the widget).
function wcButton.uiCall_pointerReleaseActivate(self, inst, x, y, button, istouch, presses)
	if self == inst then
		if self.enabled then
			if button == self.context.mouse_pressed_button then
				if button == 1 then
					self.pressed = false
					self:wid_buttonAction()
				end
			end
		end
	end
end


--- Mouse callback for releasing buttons which do not activate upon click-up.
function wcButton.uiCall_pointerRelease(self, inst, x, y, button, istouch, presses)
	if self == inst then
		if self.enabled then
			if button == self.context.mouse_pressed_button then
				if button == 1 then
					self.pressed = false
				end
			end
		end
	end
end


--- Mouse callback for releasing checkboxes, which toggle and activate upon click-up.
function wcButton.uiCall_pointerReleaseCheck(self, inst, x, y, button, istouch, presses)
	if self == inst then
		if self.enabled then
			if button == self.context.mouse_pressed_button then
				if button == 1 then
					self.pressed = false
					self:setChecked(not self.checked)
					self:wid_buttonAction()
				end
			end
		end
	end
end


function wcButton.uiCall_pointerReleaseCheckMulti(self, inst, x, y, button, istouch, presses)
	if self == inst then
		if self.enabled then
			if button == self.context.mouse_pressed_button then
				if button == 1 then
					self.pressed = false
					self:rollValue(1)
					self:wid_buttonAction()
				end
			end
		end
	end
end


--- Mouse callback for releasing radio buttons. Upon click-up, they turn on, while turning off all siblings with the same group ID.
function wcButton.uiCall_pointerReleaseRadio(self, inst, x, y, button, istouch, presses)
	if self == inst then
		if self.enabled then
			if button == self.context.mouse_pressed_button then
				if button == 1 then
					self.pressed = false
					self:setChecked(true)
					self:wid_buttonAction()
				end
			end
		end
	end
end


-- (Sticky buttons do not have a pointerRelease callback.)


--- Mouse callback for releasing normal buttons upon click-up (in general, regardless of the cursor location).
function wcButton.uiCall_pointerUnpress(self, inst, x, y, button, istouch, presses)
	if self == inst then
		if self.enabled then
			if button == self.context.mouse_pressed_button then
				if button == 1 then
					self.pressed = false
					self.cursor_press = nil
				end
			end
		end
	end
end


--- Callback for primary thimble action (ie user presses Enter) on normal buttons.
function wcButton.uiCall_thimbleAction(self, inst, key, scancode, isrepeat)
	if self == inst then
		if self.enabled then
			self:wid_buttonAction()
		end
	end
end


--- Callback for secondary thimble action (ie user presses "application" KeyConstant) on normal buttons.
function wcButton.uiCall_thimbleAction2(self, inst, key, scancode, isrepeat)
	if self == inst then
		if self.enabled then
			self:wid_buttonAction2()
		end
	end
end


-- (There is no built-in keyboard handling for tertiary actions.)


--- Callback for primary thimble action (ie user presses Enter) on checkboxes.
function wcButton.uiCall_thimbleActionCheck(self, inst, key, scancode, isrepeat)
	if self == inst then
		if self.enabled then
			self:setChecked(not self.checked)
			self:wid_buttonAction()
		end
	end
end


--- Primary thimble action for multi-state checkboxes.
function wcButton.uiCall_thimbleActionCheckMulti(self, inst, key, scancode, isrepeat)
	if self == inst then
		if self.enabled then
			self:rollValue(1)
			self:wid_buttonAction()
		end
	end
end


--- Callback for primary thimble action (ie user presses Enter) on radio buttons.
function wcButton.uiCall_thimbleActionRadio(self, inst, key, scancode, isrepeat)
	if self == inst then
		if self.enabled then
			self:setChecked(true)
			self:wid_buttonAction()
		end
	end
end


--- Callback for primary thimble action (ie user presses Enter) on sticky buttons.
function wcButton.uiCall_thimbleActionSticky(self, inst, key, scancode, isrepeat)
	if self == inst then
		if self.enabled then
			if not self.pressed then
				self.pressed = true
				self:wid_buttonAction()
			end
		end
	end
end


return wcButton
