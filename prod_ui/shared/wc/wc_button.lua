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


function wcButton.setupDefPlain(def)
	def.wid_buttonAction = wcButton.wid_buttonAction
	def.wid_buttonAction2 = wcButton.wid_buttonAction2
	def.wid_buttonAction3 = wcButton.wid_buttonAction3

	def.setEnabled = wcButton.setEnabled

	def.evt_pointerHoverOn = wcButton.evt_pointerHoverOn
	def.evt_pointerHoverOff = wcButton.evt_pointerHoverOff
	def.evt_pointerPress = wcButton.evt_pointerPress
	def.evt_pointerRelease = wcButton.evt_pointerReleaseActivate
	def.evt_pointerUnpress = wcButton.evt_pointerUnpress
	def.evt_thimbleAction = wcButton.evt_thimbleAction
	def.evt_thimbleAction2 = wcButton.evt_thimbleAction2
end


function wcButton.setupDefDoubleClick(def)
	def.wid_buttonAction = wcButton.wid_buttonAction
	def.wid_buttonAction2 = wcButton.wid_buttonAction2
	def.wid_buttonAction3 = wcButton.wid_buttonAction3

	def.setEnabled = wcButton.setEnabled

	def.evt_pointerHoverOn = wcButton.evt_pointerHoverOn
	def.evt_pointerHoverOff = wcButton.evt_pointerHoverOff
	def.evt_pointerPress = wcButton.evt_pointerPressDoubleClick
	def.evt_pointerRelease = wcButton.evt_pointerRelease
	def.evt_pointerUnpress = wcButton.evt_pointerUnpress
	def.evt_thimbleAction = wcButton.evt_thimbleAction
	def.evt_thimbleAction2 = wcButton.evt_thimbleAction2
end


function wcButton.setupDefImmediate(def)
	def.wid_buttonAction = wcButton.wid_buttonAction
	def.wid_buttonAction2 = wcButton.wid_buttonAction2
	def.wid_buttonAction3 = wcButton.wid_buttonAction3

	def.setEnabled = wcButton.setEnabled

	def.evt_pointerHoverOn = wcButton.evt_pointerHoverOn
	def.evt_pointerHoverOff = wcButton.evt_pointerHoverOff
	def.evt_pointerPress = wcButton.evt_pointerPressActivate
	def.evt_pointerRelease = wcButton.evt_pointerRelease
	def.evt_pointerUnpress = wcButton.evt_pointerUnpress
	def.evt_thimbleAction = wcButton.evt_thimbleAction
	def.evt_thimbleAction2 = wcButton.evt_thimbleAction2
end


function wcButton.setupDefRepeat(def)
	def.wid_buttonAction = wcButton.wid_buttonAction
	def.wid_buttonAction2 = wcButton.wid_buttonAction2
	def.wid_buttonAction3 = wcButton.wid_buttonAction3

	def.setEnabled = wcButton.setEnabled

	def.evt_pointerHoverOn = wcButton.evt_pointerHoverOn
	def.evt_pointerHoverOff = wcButton.evt_pointerHoverOff
	def.evt_pointerPress = wcButton.evt_pointerPressActivate
	def.evt_pointerPressRepeat = wcButton.evt_pointerPressRepeat
	def.evt_pointerRelease = wcButton.evt_pointerRelease
	def.evt_pointerUnpress = wcButton.evt_pointerUnpress
	def.evt_thimbleAction = wcButton.evt_thimbleAction
	def.evt_thimbleAction2 = wcButton.evt_thimbleAction2
end


function wcButton.setupDefSticky(def)
	def.wid_buttonAction = wcButton.wid_buttonAction
	def.wid_buttonAction2 = wcButton.wid_buttonAction2
	def.wid_buttonAction3 = wcButton.wid_buttonAction3

	def.setEnabled = wcButton.setEnabledSticky
	def.setPressed = wcButton.setPressedSticky

	def.evt_pointerHoverOn = wcButton.evt_pointerHoverOnSticky
	def.evt_pointerHoverOff = wcButton.evt_pointerHoverOff
	def.evt_pointerPress = wcButton.evt_pointerPressSticky
	def.evt_thimbleAction = wcButton.evt_thimbleActionSticky
	def.evt_thimbleAction2 = wcButton.evt_thimbleAction2
end


function wcButton.setupDefCheckbox(def)
	def.wid_buttonAction = wcButton.wid_buttonAction
	def.wid_buttonAction2 = wcButton.wid_buttonAction2
	def.wid_buttonAction3 = wcButton.wid_buttonAction3

	def.setEnabled = wcButton.setEnabled
	def.setChecked = wcButton.setChecked

	def.evt_pointerHoverOn = wcButton.evt_pointerHoverOn
	def.evt_pointerHoverOff = wcButton.evt_pointerHoverOff
	def.evt_pointerPress = wcButton.evt_pointerPress
	def.evt_pointerRelease = wcButton.evt_pointerReleaseCheck
	def.evt_pointerUnpress = wcButton.evt_pointerUnpress
	def.evt_thimbleAction = wcButton.evt_thimbleActionCheck
	def.evt_thimbleAction2 = wcButton.evt_thimbleAction2
end


function wcButton.setupDefCheckboxMulti(def)
	def.wid_buttonAction = wcButton.wid_buttonAction
	def.wid_buttonAction2 = wcButton.wid_buttonAction2
	def.wid_buttonAction3 = wcButton.wid_buttonAction3

	def.setEnabled = wcButton.setEnabled
	def.setValue = wcButton.setValue
	def.setMaxValue = wcButton.setMaxValue
	def.rollValue = wcButton.rollValue

	def.evt_pointerHoverOn = wcButton.evt_pointerHoverOn
	def.evt_pointerHoverOff = wcButton.evt_pointerHoverOff
	def.evt_pointerPress = wcButton.evt_pointerPress
	def.evt_pointerRelease = wcButton.evt_pointerReleaseCheckMulti
	def.evt_pointerUnpress = wcButton.evt_pointerUnpress
	def.evt_thimbleAction = wcButton.evt_thimbleActionCheckMulti
	def.evt_thimbleAction2 = wcButton.evt_thimbleAction2
end


function wcButton.setupDefRadioButton(def)
	def.wid_buttonAction = wcButton.wid_buttonAction
	def.wid_buttonAction2 = wcButton.wid_buttonAction2
	def.wid_buttonAction3 = wcButton.wid_buttonAction3

	def.setEnabled = wcButton.setEnabled
	def.setChecked = wcButton.setCheckedRadio
	def.setCheckedConditional = wcButton.setCheckedRadioConditional
	def.uncheckAll = wcButton.uncheckAllRadioSiblings
	def.setRadioGroup = wcButton.setRadioGroup
	def.getRadioGroup = wcButton.getRadioGroup

	def.evt_pointerHoverOn = wcButton.evt_pointerHoverOn
	def.evt_pointerHoverOff = wcButton.evt_pointerHoverOff
	def.evt_pointerPress = wcButton.evt_pointerPress
	def.evt_pointerRelease = wcButton.evt_pointerReleaseRadio
	def.evt_pointerUnpress = wcButton.evt_pointerUnpress
	def.evt_thimbleAction = wcButton.evt_thimbleActionRadio
	def.evt_thimbleAction2 = wcButton.evt_thimbleAction2
end


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


function wcButton.setRadioGroup(self, id)
	uiAssert.type(1, id, "string")

	self.radio_group = id

	return self
end


function wcButton.getRadioGroup(self)
	return self.radio_group
end


--- Turns off a radio button, plus all sibling radio buttons with the same group ID.
function wcButton.uncheckAllRadioSiblings(self)
	local parent = self.parent

	for i, sibling in ipairs(parent.nodes) do
		if sibling.is_radio_button and sibling.radio_group == self.radio_group then
			sibling.checked = false
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
	local parent = self:nodeAssertParent()
	local siblings = parent.nodes

	for i, wid in ipairs(parent.nodes) do
		if wid.is_radio_button and wid.radio_group == self.radio_group and wid[key] == value then
			wid:setChecked(true)
			break
		end
	end

	return self
end


-- * ProdUI Callbacks *


--- Mouse callback for when the cursor overlaps a widget.
function wcButton.evt_pointerHoverOn(self, inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		if self.enabled then
			self.hovered = true
			self.cursor_hover = self.skin.cursor_on
		end
	end
end


--- Mouse callback for when the cursor overlaps a sticky button.
function wcButton.evt_pointerHoverOnSticky(self, inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
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
function wcButton.evt_pointerHoverOff(self, inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		if self.enabled then
			self.hovered = false
			self.cursor_hover = nil
		end
	end
end


--- Mouse callback for pressing normal buttons (whose primary actions don't activate upon click-down).
function wcButton.evt_pointerPress(self, inst, x, y, button, istouch, presses)
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
function wcButton.evt_pointerPressActivate(self, inst, x, y, button, istouch, presses)
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
function wcButton.evt_pointerPressDoubleClick(self, inst, x, y, button, istouch, presses)
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
function wcButton.evt_pointerPressRepeat(self, inst, x, y, button, istouch, reps)
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
function wcButton.evt_pointerPressSticky(self, inst, x, y, button, istouch, presses)
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
function wcButton.evt_pointerReleaseActivate(self, inst, x, y, button, istouch, presses)
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
function wcButton.evt_pointerRelease(self, inst, x, y, button, istouch, presses)
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
function wcButton.evt_pointerReleaseCheck(self, inst, x, y, button, istouch, presses)
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


function wcButton.evt_pointerReleaseCheckMulti(self, inst, x, y, button, istouch, presses)
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
function wcButton.evt_pointerReleaseRadio(self, inst, x, y, button, istouch, presses)
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
function wcButton.evt_pointerUnpress(self, inst, x, y, button, istouch, presses)
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
function wcButton.evt_thimbleAction(self, inst, key, scancode, isrepeat)
	if self == inst then
		if self.enabled then
			self:wid_buttonAction()
		end
	end
end


--- Callback for secondary thimble action (ie user presses "application" KeyConstant) on normal buttons.
function wcButton.evt_thimbleAction2(self, inst, key, scancode, isrepeat)
	if self == inst then
		if self.enabled then
			self:wid_buttonAction2()
		end
	end
end


-- (There is no built-in keyboard handling for tertiary actions.)


--- Callback for primary thimble action (ie user presses Enter) on checkboxes.
function wcButton.evt_thimbleActionCheck(self, inst, key, scancode, isrepeat)
	if self == inst then
		if self.enabled then
			self:setChecked(not self.checked)
			self:wid_buttonAction()
		end
	end
end


--- Primary thimble action for multi-state checkboxes.
function wcButton.evt_thimbleActionCheckMulti(self, inst, key, scancode, isrepeat)
	if self == inst then
		if self.enabled then
			self:rollValue(1)
			self:wid_buttonAction()
		end
	end
end


--- Callback for primary thimble action (ie user presses Enter) on radio buttons.
function wcButton.evt_thimbleActionRadio(self, inst, key, scancode, isrepeat)
	if self == inst then
		if self.enabled then
			self:setChecked(true)
			self:wid_buttonAction()
		end
	end
end


--- Callback for primary thimble action (ie user presses Enter) on sticky buttons.
function wcButton.evt_thimbleActionSticky(self, inst, key, scancode, isrepeat)
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
