-- XXX: This whole file is untested.

--[[
	Common "step" button state and functions.

	Based mostly on 'logic/common_scroll.lua'.

	NOTE: commonScroll and commonStepper are not designed to work in the same widget.
--]]


local commonStep = {}


local REQ_PATH = ... and (...):match("(.-)[^%.]+$") or ""


local _mt_step = {}
_mt_step.__index = _mt_step


local code_map = {}
code_map["pend-pend"] = {}
code_map["pend-pend"]["b1"] = "stepper-b1-pend"
code_map["pend-pend"]["b2"] = "stepper-b2-pend"

code_map["pend-cont"] = {}
code_map["pend-cont"]["b1"] = "stepper-b1-pend"
code_map["pend-cont"]["b2"] = "stepper-b2-pend"

code_map["cont"] = {}
code_map["cont"]["b1"] = "stepper-b1-cont"
code_map["cont"]["b2"] = "stepper-b2-cont"


--- Makes a stepper button pair.
-- @param horizontal When true, the stepper is aligned horizontally. When false, it's vertical.
-- @return The stepper table.
function commonStep.newStepper(is_horizontal)
	is_horizontal = not not is_horizontal

	local self = setmetatable({}, _mt_step)

	self.active = false
	self.horizontal = is_horizontal

	self.button_length = 2^16 -- XXX style
	self.button_length_min = 26 -- XXX style
	self.button_length_max = 2^16 -- XXX style

	self.breadth = 16 -- XXX style

	-- Broad stepper shape and position within the client widget.
	self.x = 0
	self.y = 0
	self.w = 1
	self.h = 1

	-- Button 1 (left or up)
	self.b1 = false -- true to enable
	self.b1_mode = "pend-cont"

	self.b1_x = 0
	self.b1_y = 0
	self.b1_w = 1
	self.b1_h = 1

	self.b1_valid = false

	-- Button 2 (right or down)
	self.b2 = false -- true to enable
	self.b2_mode = "pend-cont"

	self.b2_x = 0
	self.b2_y = 0
	self.b2_w = 1
	self.b2_h = 1

	self.b2_valid = false

	-- Hover and press states:
	self.hover = false -- false, "b1", "b2"
	self.press = false -- false, "b1", "b2"

	return self
end


function _mt_step:testPoint(px, py)
	-- (No broad overlap check.)

	-- In the event of overlap, 'more' gets priority over 'less'.
	if self.b2 and self.b2_valid
	and px >= self.x + self.b2_x and px < self.x + self.b2_x + self.b2_w
	and py >= self.y + self.b2_y and py < self.y + self.b2_y + self.b2_h
	then
		return "b2"

	elseif self.b1 and self.b1_valid
	and px >= self.x + self.b1_x and px < self.x + self.b1_x + self.b1_w
	and py >= self.y + self.b1_y and py < self.y + self.b1_y + self.b1_h
	then
		return "b1"
	end

	return false
end


local function updateShapesH(self)
	-- Too small: disable buttons
	if self.w < 2 then
		self.b1 = false
		self.b2 = false
	else
		-- Special case: Compress buttons if they are at least as long as the broad shape.
		local button_check = (self.b1 and self.button_length or 0) + (self.b2 and self.button_length or 0)
		if button_check >= self.w then
			local shortened_length = math.floor(0.5 + self.w/2)
			if self.b1 then
				self.b1_x = 0
				self.b1_y = 0
				self.b1_w = shortened_length
				self.b1_h = self.h
			end

			if self.b2 then
				self.b2_x = self.w - shortened_length
				self.b2_y = 0
				self.b2_w = shortened_length
				self.b2_h = self.h
			end

		-- Normal positioning.
		else
			local measure = 0

			-- Button 1
			if self.b1 then
				self.b1_x = 0
				self.b1_y = 0
				self.b1_w = self.button_length
				self.b1_h = self.h

				self.b1_valid = true

				measure = measure + self.button_length
			end

			-- Button 2
			if self.b2 then
				self.b2_x = measure
				self.b2_y = 0
				self.b2_w = self.button_length
				self.b2_h = self.h

				self.b2_valid = true
			end
		end
	end
end


local function updateShapesV(self)
	-- Too small: disable buttons
	if self.h < 2 then
		self.b1 = false
		self.b2 = false
	else
		-- Special case: Compress buttons if they are at least as long as the broad shape.
		local button_check = (self.b1 and self.button_length or 0) + (self.b2 and self.button_length or 0)
		if button_check >= self.h then
			local shortened_length = math.floor(0.5 + self.h/2)
			if self.b1 then
				self.b1_x = 0
				self.b1_y = 0
				self.b1_w = self.w
				self.b1_h = shortened_length
			end

			if self.b2 then
				self.b2_x = 0
				self.b2_y = self.h - shortened_length
				self.b2_w = self.w
				self.b2_h = shortened_length
			end
		-- Normal positioning.
		else
			local measure = 0

			-- Button 1
			if self.b1 then
				self.b1_x = 0
				self.b1_y = 0
				self.b1_w = self.w
				self.b1_h = self.button_length

				self.b1_valid = true

				measure = measure + self.button_length
			end

			-- Button 2
			if self.b2 then
				self.b2_x = 0
				self.b2_y = measure
				self.b2_w = self.w
				self.b2_h = self.button_length

				self.b2_valid = true
			end
		end
	end
end


--- Conditionally updates the component of the stepper based on the broad shape.
function _mt_step:updateShapes()
	if self.horizontal then
		updateShapesH(self)
	else
		updateShapesV(self)
	end
end



-- * Widget plug-in methods *


--- Plug-in to make, remake or remove embedded stepper buttons.
-- @param self The client widget.
-- @param enabled True to populate a stepper table, false/nil to delete any existing stepper.
-- @param is_horizontal True for the step buttons to be aligned horizontally, false for vertical alignment.
-- @return Nothing.
function commonStep.setButtons(self, enabled, is_horizontal)
	if not enabled then
		self.stepper = nil
	else
		self.stepper = commonStep.newStepper(is_horizontal)
		local stepper = self.stepper

		stepper.active = true

		stepper.b1 = true
		stepper.b2 = true
	end

	-- If there was a state change, reshape the widget after calling.
end


--- Plug-in for the client's uiCall_pointerPress(). Detects clicks on embedded stepper components and initiates
-- the dragging state. It modifies 'self.press_busy', and state fields within the stepper tables.
-- @param self The widget to test and modify.
-- @param x Mouse X position in UI space.
-- @param y Mouse Y position in UI space.
-- @return True if the stepper is considered activated by the click.
function commonStep.widgetStepperPress(self, x, y)
	-- Don't override existing 'busy' state.
	if self.press_busy then
		return
	end

	-- Check for clicking on stepper buttons, and initiate dragging states.
	local ax, ay = self:getAbsolutePosition()
	x = x - ax
	y = y - ay

	local stepper = self.stepper

	--print("stepper", stepper, "active", stepper.active)
	if stepper and stepper.active then
		local test_code = stepper:testPoint(x, y)
		--print("", "test_code", test_code)
		if test_code then
			stepper.hover = false
			stepper.press = test_code

			if test_code == "b1" then
				self.press_busy = code_map[stepper.b1_mode][test_code]
				if self.press_busy == "stepper-b1-pend" then
					self:wid_stepperB1Pend(stepper)
				end
				return true

			elseif test_code == "b2" then
				self.press_busy = code_map[stepper.b2_mode][test_code]
				if self.press_busy == "stepper-b2-pend" then
					self:wid_stepperB2Pend(stepper)
				end
				return true
			end
		end
	end
end


--- Plug-in for client's uiCall_pointerPressRepeat(), which implements repeated 'pend' button motions.
function commonStep.widgetStepperPressRepeat(self, x, y)
	local stepper = self.stepper
	local busy_code = self.press_busy

	if stepper and stepper.active then
		if busy_code == "b1-pend" then
			if stepper.b1 then
				if stepper.b1_mode == "pend-cont" then
					self.press_busy = "stepper-b1-cont"
				else
					self:wid_stepperB1Pend(stepper)
				end
			end

		elseif busy_code == "v2-pend" then
			if stepper.b2 then
				if stepper.b2_mode == "pend-cont" then
					self.press_busy = "stepper-b2-cont"
				else
					self:wid_stepperB2Pend(stepper)
				end
			end
		end
	end
end


function commonStep.widgetProcessHover(self, mx, my)
	local skip = false
	local stepper = self.stepper

	if stepper then
		stepper.hover = stepper:testPoint(mx, my)
	end
end


--- A plug-in for 'uiCall_pointerHoverOff()', which just turns off the hover state.
-- @param self The client widget.
-- @return Nothing.
function commonStep.widgetClearHover(self)
	local stepper = self.stepper

	if stepper then
		stepper.hover = false
	end
end


--- A plug-in for 'uiCall_pointerUnpress()', which just turns off the press state.
-- @param self The client widget.
-- @return Nothing.
function commonStep.widgetClearPress(self)
	local stepper = self.stepper

	if stepper then
		stepper.press = false
	end
end


--- A plug-in for 'uiCall_update()' that controls stepper buttons while the mouse presses and moves.
-- @param self The client widget.
-- @param mx Mouse X, relative to widget top-left.
-- @param my Mouse Y, relative to widget top-left.
-- @param dt The frame delta time, passed to callbacks if one of the stepper buttons triggers in continuous mode.
-- @return true if an action was taken, false if not.
function commonStep.widgetDragLogic(self, mx, my, dt)
	local mode = self.press_busy
	local stepper = self.stepper

	if mode and stepper and stepper.active then
		if mode == "stepper-b1-cont" and stepper.b1 then
			self:wid_stepperB1Cont(stepper, dt)
			return true

		elseif mode == "stepper-b2-cont" and stepper.b2 then
			self:wid_stepperB2Cont(stepper, dt)
			return true
		end
	end
end


--- Plug-in for clients that positions the stepper. The client viewport region needs to be set to a default size and
-- position, from which the stepper will carve out space. Stepper shapes then need to be updated afterwards.
-- @param self The client widget, with 'self.stepper' populated.
-- @param far_end If true, hori-steppers go to the bottom and vert-steppers go to the right. If false, hori-steppers go to the top, vert-steppers to the left.
function commonStep.arrangeStepper(self, far_end)
	local stepper = self.stepper
	if not stepper then
		return
	end

	--stepper.breadth

	if stepper.horizontal then
		stepper.w = self.w
		stepper.h = stepper.breadth
		stepper.x = 0
		stepper.y = (far_end) and stepper.h - stepper.breadth or 0
	else
		stepper.w = stepper.breadth
		stepper.h = self.h
		stepper.x = (far_end) and stepper.w - stepper.breadth or 0
		stepper.y = 0
	end
end


return commonStep
