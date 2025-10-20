--[[
TODO:

* What is 'trough_rate'?
--]]


-- To load: local lib = context:getLua("shared/lib")


--[[
Shared widget code for slider bar functionality.
--]]


local context = select(1, ...)


local lgcSlider = {}


local pMath = require(context.conf.prod_ui_req .. "lib.pile_math")
local uiAssert = require(context.conf.prod_ui_req .. "ui_assert")
local uiTable = require(context.conf.prod_ui_req .. "ui_table")


local _lerp = pMath.lerp


local _slider_axes = uiTable.newEnumV("SliderAxis", "horizontal", "vertical")


local slider_keys = {
	-- Horizontal
	[false] = {
		thp1 = "thumb_x", thp2 = "thumb_y", thl1 = "thumb_w", thl2 = "thumb_h",
		trp1 = "trough_x", trp2 = "trough_y", trl1 = "trough_w", trl2 = "trough_h"
	},
	-- Vertical
	[true] = {
		thp1 = "thumb_y", thp2 = "thumb_x", thl1 = "thumb_h", thl2 = "thumb_w",
		trp1 = "trough_y", trp2 = "trough_x", trl1 = "trough_h", trl2 = "trough_w"
	},
}


function lgcSlider.setup(self)
	-- When false, the slider control should not respond to user input.
	-- This field does not prevent API calls from modifying the slider state. Nor does it affect
	-- the status of the parent widget as a whole (as in, it may still be capable of holding
	-- the UI thimble).
	self.slider_allow_changes = true

	-- Slider value state.
	-- Internally, the slider position ranges from 0 to 'slider_max' in a linear fashion.
	self.slider_pos = 0
	self.slider_max = 0
	self.slider_def = 0 -- default
	self.slider_home = 0 -- "home" position, usually zero.

	-- Trough and thumb state.
	self.trough_x = 0
	self.trough_y = 0
	self.trough_w = 0
	self.trough_h = 0

	self.thumb_x = 0
	self.thumb_y = 0
	self.thumb_w = 0
	self.thumb_h = 0

	self.trough_vertical = false
	self.round_policy = "none" -- "none", "floor", "ceil", "nearest"

	-- false to make sliders count left-to-right or top-to-bottom.
	-- true to make them count right-to-left or bottom-to-top.
	self.count_reverse = false

	-- Set to -1 to flip the value added or subtracted when moving the mouse wheel over the slider.
	self.wheel_dir = 1

	-- Lighten the "used" side of the trough.
	self.show_use_line = true

	-- Cached offset of the "home" position within the trough.
	self.trough_home = 0
end


function lgcSlider.reshapeSliderComponent(self, x, y, w, h, thumb_w, thumb_h)
	if self.trough_vertical then
		-- On the active axis, trim half of the thumb length from the trough length.
		self.trough_x = math.floor(x)
		self.trough_y = math.floor(y + thumb_h / 2)
		self.trough_w = math.max(0, w)
		self.trough_h = math.max(0, h - thumb_h)

		-- Center the thumb in the trough along its non-active axis.
		self.thumb_x = math.floor(self.trough_w / 2)
	else
		self.trough_x = math.floor(x + thumb_w / 2)
		self.trough_y = math.floor(y)
		self.trough_w = math.max(0, w - thumb_w)
		self.trough_h = math.max(0, h)

		self.thumb_y = math.floor(self.trough_h / 2)
	end

	self.thumb_w = math.min(thumb_w, self.trough_w)
	self.thumb_h = math.min(thumb_h, self.trough_h)

	--print("lgcSlider.reshapeSliderComponent(): Trough: ", self.trough_x, self.trough_y, self.trough_w, self.trough_h)
	--print("lgcSlider.reshapeSliderComponent(): Thumb: ", self.thumb_x, self.thumb_y, self.thumb_w, self.thumb_h)
end


function lgcSlider.roundPos(self)
	local mode = self.round_policy

	if mode == "none" then
		return

	elseif mode == "floor" then
		self.slider_pos = math.floor(self.slider_pos)

	elseif mode == "ceil" then
		self.slider_pos = math.ceil(self.slider_pos)

	elseif mode == "nearest" then
		self.slider_pos = math.floor(0.5 + self.slider_pos)

	else
		error("invalid round mode: " .. tostring(mode))
	end
end


function lgcSlider.clampPos(self)
	self.slider_pos = math.max(0, math.min(self.slider_pos, self.slider_max))
end


function lgcSlider.updateTroughHome(self)
	local trough_ext = self.skin.trough_ext

	-- If the home position is the first or last value, add the trough extension to the trough home point.
	-- It looks nicer that way.
	if self.slider_home == 0 then
		if self.count_reverse then
			if self.trough_vertical then
				self.trough_home = self.trough_h + trough_ext
			else
				self.trough_home = self.trough_w + trough_ext
			end
		else
			self.trough_home = -trough_ext
		end

	elseif self.slider_home == self.slider_max then
		if self.count_reverse then
			self.trough_home = -trough_ext
		else
			if self.trough_vertical then
				self.trough_home = self.trough_h + trough_ext
			else
				self.trough_home = self.trough_w + trough_ext
			end
		end

	else
		local trough_length = (self.trough_vertical) and self.trough_h or self.trough_w
		self.trough_home = math.floor(0.5 + _lerp(0, trough_length, self.slider_home / self.slider_max))
	end
end


function lgcSlider.updateSlider(self, vertical)
	local unit_pos = (vertical) and (self.thumb_y / self.trough_h) or (self.thumb_x / self.trough_w)

	-- Reverse flipping
	unit_pos = self.count_reverse and (1 - unit_pos) or unit_pos

	self.slider_pos = unit_pos * self.slider_max

	lgcSlider.roundPos(self)
	lgcSlider.clampPos(self)
end


function lgcSlider.updateThumb(self, vertical)
	local resolved_pos = self.slider_pos
	if self.count_reverse then
		resolved_pos = self.slider_max - resolved_pos
	end

	local keys = slider_keys[not not self.trough_vertical]
	local thumb_key, trough_key = keys["thp1"], keys["trl1"]

	if self.slider_max == 0 then
		self[thumb_key] = 0
	else
		self[thumb_key] = math.floor(0.5 + _lerp(0, self[trough_key], resolved_pos / self.slider_max))
		--print("trough_key", trough_key)
		--print("self[trough_key]", self[trough_key])
		--print("resolved_pos / self.slider_max", resolved_pos / self.slider_max)
		--print("new thumb position", self[thumb_key])
	end
end


-- Update after having moved the thumb.
function lgcSlider.processMovedThumb(self)
	local slider_pos_old = self.slider_pos

	-- Update internal slider position based on the thumbs's location within the trough.
	-- Then reposition the thumb based on the new internal slider position.
	local vert = not not self.trough_vertical
	lgcSlider.updateSlider(self, vert)
	lgcSlider.updateThumb(self, vert)
end


-- Update after having changed the internal slider position.
function lgcSlider.processMovedSliderPos(self)
	lgcSlider.roundPos(self)
	lgcSlider.clampPos(self)
	lgcSlider.updateThumb(self, not not self.trough_vertical)
end


function lgcSlider.troughIntersect(self, x, y)
	-- NOTE: Assumes X and Y are relative to the trough top-left.
	local tw, th = self.trough_w, self.trough_h

	return x >= tx and x < tx + tw and y >= ty and y < ty + th
end



function lgcSlider.checkMousePress(self, x, y, click_anywhere)
	x = x - self.trough_x
	y = y - self.trough_y

	if self.slider_allow_changes then
		if click_anywhere or lgcSlider.troughIntersect(self, x, y) then
			if self.trough_vertical then
				self.thumb_y = y
			else
				self.thumb_x = x
			end

			local slider_pos_old = self.slider_pos
			lgcSlider.processMovedThumb(self)
			if self.slider_pos ~= slider_pos_old then
				self:wid_actionSliderChanged()
			end

			return true
		end
	end
end


function lgcSlider.checkKeyPress(self, key, scancode, isrepeat)
	if self.slider_allow_changes then
		local additive = self.trough_rate_focus or 1 -- XXX expose in config?
		local dir

		local slider_pos_old = self.slider_pos

		-- Catch left/right for horizontal bars and up/down for vertical bars.
		if self.trough_vertical then
			if scancode == "up" then
				dir = -1

			elseif scancode == "pageup" then
				dir = -1
				additive = additive * 10

			elseif scancode == "down" then
				dir = 1

			elseif scancode == "pagedown" then
				dir = 1
				additive = additive * 10
			end
			if self.count_reverse then
				additive = -additive
			end
		else
			if scancode == "left" then
				dir = -1

			elseif scancode == "pageup" then
				dir = -1
				additive = additive * 10

			elseif scancode == "right" then
				dir = 1

			elseif scancode == "pagedown" then
				dir = 1
				additive = additive * 10
			end
			if self.count_reverse then
				additive = -additive
			end
		end

		if dir then
			self.slider_pos = self.slider_pos + additive * dir
			lgcSlider.processMovedSliderPos(self)

			if self.slider_pos ~= slider_pos_old then
				self:wid_actionSliderChanged()
			end

			return true
		end
	end
end


function lgcSlider.getTroughAdditive(self)
	-- Additive value for when clicking on the trough body or using the mouse wheel.
	-- Wheel may need a separate value depending on how different operating systems handle wheel actions.
	-- (ie do Windows wheelmoved events contain larger XY values than those on Linux?)
	local additive = self.trough_rate or math.ceil(self.slider_max / 12) -- XXX expose in config?
	if self.count_reverse then
		additive = -additive
	end

	return additive
end


function lgcSlider.mouseWheelLogic(self, x, y)
	if self.slider_allow_changes then
		local slider_pos_old = self.slider_pos

		-- XXX horizontal scroll wheel support as well?
		local dir = false
		if y > 0 then
			dir = 1
		elseif y < 0 then
			dir = -1
		end

		if dir then
			dir = dir * self.wheel_dir

			local additive = lgcSlider.getTroughAdditive(self)
			self.slider_pos = math.max(0, math.min(self.slider_pos + additive * dir, self.slider_max))

			lgcSlider.processMovedSliderPos(self)

			if self.slider_pos ~= slider_pos_old then
				self:wid_actionSliderChanged()
			end
		end

		-- Always halt bubbling on mousewheel event.
		-- This may interfere with mouse-wheel scrolling if there is no margin space to move the cursor.
		-- [[
		return true
		--]]

		-- Halt bubbling if the slider is at position 0 or max, and no change occurred.
		-- (Better or worse?)
		--[[
		if slider_pos_old == self.slider_pos and (self.slider_pos == 0 or self.slider_pos == max) then
			return true
		end
		--]]
	end
end


function lgcSlider.widSetSliderPosition(self, pos)
	uiAssert.numberNotNaN(1, pos)

	-- Does not check `self.enabled` or `self.slider_allow_changes`.

	local slider_pos_old = self.slider_pos

	self.slider_pos = math.max(0, math.min(pos, self.slider_max))

	lgcSlider.processMovedSliderPos(self)

	if self.slider_pos ~= slider_pos_old then
		self:wid_actionSliderChanged()
	end
end


function lgcSlider.widSetSliderMax(self, max)
	uiAssert.numberNotNaN(1, max)

	-- Does not check `self.enabled` or `self.slider_allow_changes`.

	local slider_pos_old = self.slider_pos

	self.slider_max = math.max(0, max)

	lgcSlider.processMovedSliderPos(self)

	if self.slider_pos ~= slider_pos_old then
		self:wid_actionSliderChanged()
	end
end


function lgcSlider.widSetSliderAxis(self, axis)
	uiAssert.enum(1, axis, _slider_axes)

	self.trough_vertical = (axis == "vertical") and true or false
	self:reshape()
end


function lgcSlider.widSetSliderAllowChanges(self, enabled)
	self.slider_allow_changes = not not enabled
end


--- Apply Slider Bar methods to a widget definition or instance.
-- @param self The widget def or instance (usually the former).
function lgcSlider.setupMethods(self)
	self.setSliderPosition = lgcSlider.widSetSliderPosition
	self.setSliderMax = lgcSlider.widSetSliderMax
	self.setSliderAxis = lgcSlider.widSetSliderAxis
	self.setSliderAllowChanges = lgcSlider.widSetSliderAllowChanges
end


return lgcSlider
