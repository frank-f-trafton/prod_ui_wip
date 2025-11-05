-- To load: local lib = context:getLua("shared/lib")

--[[
Shared (barebones) button logic.

This roughly follows the behavior of `shared/wc/wc_button.lua`. See that file for additional comments.
--]]


local context = select(1, ...)


local wcButtonBare = {}


local uiDummy = require(context.conf.prod_ui_req .. "ui_dummy")


wcButtonBare.wid_buttonAction = uiDummy.func
wcButtonBare.wid_buttonAction2 = uiDummy.func
wcButtonBare.wid_buttonAction3 = uiDummy.func


function wcButtonBare.setEnabled(self, enabled)
	self.enabled = not not enabled

	if not self.enabled then
		self.hovered = false
		self.pressed = false
	end

	return self
end


function wcButtonBare.setEnabledSticky(self, enabled)
	self.enabled = not not enabled

	if not self.enabled then
		self.hovered = false
		-- Do not reset 'pressed' state when disabling sticky buttons.
	end

	return self
end


function wcButtonBare.setPressedSticky(self, pressed)
	self.pressed = not not pressed

	return self
end


function wcButtonBare.setChecked(self, checked)
	self.checked = not not checked

	return self
end


function wcButtonBare.uncheckAllRadioSiblings(self)
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


function wcButtonBare.setCheckedRadio(self, checked)
	wcButtonBare.uncheckAllRadioSiblings(self)
	self.checked = not not checked

	return self
end


function wcButtonBare.setCheckedRadioConditional(self, key, value)
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


function wcButtonBare.uiCall_pointerHoverOn(self, inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		if self.enabled then
			self.hovered = true
		end
	end
end


function wcButtonBare.uiCall_pointerHoverOnSticky(self, inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		if self.enabled then
			if not self.pressed then
				self.hovered = true
			end
		end
	end
end


function wcButtonBare.uiCall_pointerHoverOff(self, inst, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == inst then
		if self.enabled then
			self.hovered = false
		end
	end
end


function wcButtonBare.uiCall_pointerPress(self, inst, x, y, button, istouch, presses)
	if self == inst then
		if self.enabled then
			if button == self.context.mouse_pressed_button then
				if button <= 3 then
					self:tryTakeThimble1()
				end

				if button == 1 then
					self.pressed = true

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


function wcButtonBare.uiCall_pointerPressActivate(self, inst, x, y, button, istouch, presses)
	if self == inst then
		if self.enabled then
			if button == self.context.mouse_pressed_button then
				if button <= 3 then
					self:tryTakeThimble1()
				end

				if button == 1 then
					self.pressed = true

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


function wcButtonBare.uiCall_pointerPressRepeat(self, inst, x, y, button, istouch, reps)
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
function wcButtonBare.uiCall_pointerPressSticky(self, inst, x, y, button, istouch, presses)
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


function wcButtonBare.uiCall_pointerReleaseActivate(self, inst, x, y, button, istouch, presses)
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


function wcButtonBare.uiCall_pointerRelease(self, inst, x, y, button, istouch, presses)
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


function wcButtonBare.uiCall_pointerReleaseCheck(self, inst, x, y, button, istouch, presses)
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


function wcButtonBare.uiCall_pointerReleaseRadio(self, inst, x, y, button, istouch, presses)
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


function wcButtonBare.uiCall_pointerUnpress(self, inst, x, y, button, istouch, presses)
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


function wcButtonBare.uiCall_thimbleAction(self, inst, key, scancode, isrepeat)
	if self == inst then
		if self.enabled then
			self:wid_buttonAction()
		end
	end
end


function wcButtonBare.uiCall_thimbleAction2(self, inst, key, scancode, isrepeat)
	if self == inst then
		if self.enabled then
			self:wid_buttonAction2()
		end
	end
end


-- (There is no built-in keyboard handling for tertiary actions.)


function wcButtonBare.uiCall_thimbleActionCheck(self, inst, key, scancode, isrepeat)
	if self == inst then
		if self.enabled then
			self:setChecked(not self.checked)
			self:wid_buttonAction()
		end
	end
end


function wcButtonBare.uiCall_thimbleActionRadio(self, inst, key, scancode, isrepeat)
	if self == inst then
		if self.enabled then
			self:setChecked(true)
			self:wid_buttonAction()
		end
	end
end


function wcButtonBare.uiCall_thimbleActionSticky(self, inst, key, scancode, isrepeat)
	if self == inst then
		if self.enabled then
			if not self.pressed then
				self.pressed = true
				self:wid_buttonAction()
			end
		end
	end
end


return wcButtonBare
