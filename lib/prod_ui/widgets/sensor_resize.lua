
--[[
	sensor_resize: A generic mouse drag sensor that can be used by containers to initiate a resize event.

	This widget is invisible by default.
--]]


local context = select(1, ...)


local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")


local def = {}


function def:uiCall_create(inst)

	if self == inst then
		-- When true, renders a debug rectangle
		self.visible = false

		self.axis_x = 0 -- -1, 0, 1
		self.axis_y = 0 -- -1, 0, 1
		-- [0][0] makes one big sensor.

		self.allow_hover = true -- setting to false disables the sensor
		self.can_have_thimble = false
		self.allow_focus_capture = false -- the container handles the capture loop and resize logic.

		-- ID fields
		self.is_frame_sensor = true

		-- Should be set by the owning widget.
		self.sensor_pad = 1
	end
end


--- Allow clicks that are not the primary mouse button to pass through the sensor.
function def:ui_evaluatePress(x, y, button, istouch, presses)
	return button == 1
end


function def:uiCall_reshape()

	if not self.parent then
		return
	end

	-- Resize and position self around the container based on the current alignment.
	local axis_x = self.axis_x
	local axis_y = self.axis_y

	-- x0y0 == one big sensor covering all 8 resize directions
	if axis_x == 0 and axis_y == 0 then
		self.x = -self.sensor_pad
		self.w = self.parent.w + self.sensor_pad*2
		self.y = -self.sensor_pad
		self.h = self.parent.h + self.sensor_pad*2

	-- Smaller sensor along one side or corner
	else

		if axis_x < 0 then
			self.x = -self.sensor_pad

		elseif axis_x > 0 then
			self.x = self.parent.w
		end

		if axis_x == 0 then
			self.w = self.parent.w
		else
			self.w = self.sensor_pad
		end

		if axis_y < 0 then
			self.y = -self.sensor_pad

		elseif axis_y > 0 then
			self.y = self.parent.h
		end

		if axis_y == 0 then
			self.h = self.parent.h
		else
			self.h = self.sensor_pad
		end
	end
end


local function getCursorCode(a_x, a_y)

	return (a_y == 0 and a_x ~= 0) and "sizewe" -- -
	or (a_y ~= 0 and a_x == 0) and "sizens" -- |
	or ((a_y == 1 and a_x == 1) or (a_y == -1 and a_x == -1)) and "sizenwse" -- \
	or ((a_y == -1 and a_x == 1) or (a_y == 1 and a_x == -1)) and "sizenesw" -- /
	or false -- unknown

	-- [XXX 16] on Fedora 36/37 + GNOME, a different cursor design is used for diagonal resize
	-- which has four orientations (up-left, up-right, down-left, down-right) instead
	-- of just two. It looks a bit incorrect when resizing a window from the bottom-left
	-- or bottom-right corners.
end


local function determineBigResizeMode(self, mouse_x, mouse_y)

	local ax, ay = self:getAbsolutePosition()
	local mx, my = mouse_x - ax, mouse_y - ay

	local hw, hh = self.w/2, self.h/2

	local pad = self.sensor_pad

	local axis_x = mx <= pad and -1 or mx > self.w - pad*2 and 1 or 0
	local axis_y = my <= pad and -1 or my > self.h - pad*2 and 1 or 0

	--print("hoverOn", "axis_x", axis_x, "axis_y", axis_y)
	--print(mx, my)

	return axis_x, axis_y
end


function def:uiCall_pointerHoverMove(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)

	if self == inst then
		-- Update mouse cursor
		local axis_x, axis_y

		-- Big sensor
		if self.axis_x == 0 and self.axis_y == 0 then
			axis_x, axis_y = determineBigResizeMode(self, mouse_x, mouse_y)

		-- Little sensor
		else
			axis_x = self.axis_x
			axis_y = self.axis_y
		end

		self:setCursorLow(getCursorCode(axis_x, axis_y))

		return true
	end
end


function def:uiCall_pointerHoverOff(inst, mouse_x, mouse_y, mouse_dx, mouse_dy)

	if self == inst then
		-- Restore mouse cursor state.
		self:setCursorLow()

		return true
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)

	-- NOTE: when the parent is maximized, it should turn off 'allow_hover' in its resize sensors.
	if self == inst then
		if button == 1 and self.context.mouse_pressed_button == button then
			local parent = self.parent

			local axis_x, axis_y = self.axis_x, self.axis_y
			if axis_x == 0 and axis_y == 0 then
				axis_x, axis_y = determineBigResizeMode(self, x, y)
			end

			if not parent then
				error("no parent widget to resize.")
			end

			-- The parent handles resizing via event capture functions.
			-- (Passing 0,0 here is an error.)
			if not (axis_x == 0 and axis_y == 0) then
				parent:initiateResizeMode(axis_x, axis_y)
			end
		end

		--return true
	end
end


-- Debug visualizer
function def:render(os_x, os_y)

	love.graphics.setScissor()

	love.graphics.setColor(0.8, 0.1, 0.2, 0.8)

	love.graphics.setLineWidth(1)
	love.graphics.setLineJoin("miter")
	love.graphics.setLineStyle("rough")

	love.graphics.rectangle("line", 0.5, 0.5, self.w - 1, self.h - 1)
end


return def
