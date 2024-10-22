-- [XXX 15] This is very out-of-date. It was originally used with window frame headers, but they now have
-- the functionality built-in. But it could still be useful in other cases. Clean it up sometime.


local context = select(1, ...)


local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")


local def = {}


function def:uiCall_create(inst)
	if self == inst then
		self.r = 0.25
		self.g = 0.25
		self.b = 1
		self.a = 1

		self.visible = false

		self.allow_hover = true -- set to false to disable sensor
		self.can_have_thimble = false
		self.allow_focus_capture = false -- the container handles the capture loop and resize logic.

		self.is_frame_sensor = true
	end
end


function def:uiCall_reshape()
	if not self.parent then
		return
	end

	-- Just fill the parent rectangle for now.
	self.x = 0
	self.y = 0
	self.w = self.parent.w
	self.h = self.parent.h
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self == inst then
		if button == 1 and self.context.mouse_pressed_button == button then
			local frame = self:findAncestorByField("is_frame", true)

			if not frame then
				error("No frame ancestor to drag.")
			end

			if presses % 2 == 0 then
				if frame.wid_maximize and frame.wid_unmaximize then
					if not frame.maximized then
						frame:wid_maximize()

					else
						frame:wid_unmaximize()
					end

					frame:reshape(true)
				end

			else
				-- Drag (reposition) action
				frame.cap_mode = "drag"

				local a_x, a_y = frame:getAbsolutePosition()
				frame.drag_ox = a_x - x
				frame.drag_oy = a_y - y

				frame.cap_mouse_orig_a_x = x
				frame.cap_mouse_orig_a_y = y

				frame:captureFocus()
			end
		end

		-- Bubble up
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
