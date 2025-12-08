-- A draggable box, written to test cursor capturing.


local def = {}


local context = select(1, ...)


-- Called when dragging while captured.
function def:wid_dragAction()

end


function def:evt_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 0
	self.allow_focus_capture = true

	-- When true, reposition to be centered on the mouse pointer when dragged
	self.center_on_pointer = false

	-- Offset of the mouse pointer upon initial click-and-drag
	self.mouse_ox = 0
	self.mouse_oy = 0

	-- Drag boundaries relative to the parent contact box
	self.drag_min_x = 0
	self.drag_min_y = 0
	self.drag_max_x = 2^16
	self.drag_max_y = 2^16

	-- Cursor IDs for hover and press states.
	self.cursor_hover = "hand"
	self.cursor_press = "hand"

	-- Status flags.
	self.enabled = true
	self.pressed = false
	self.hovered = false
end


function def:evt_pointerHoverOn(targ, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == targ then
		if self.enabled then
			self.hovered = true
		end
	end
end


function def:evt_pointerHoverOff(targ, mouse_x, mouse_y, mouse_dx, mouse_dy)
	if self == targ then
		if self.enabled then
			self.hovered = false
		end
	end
end


function def:evt_pointerPress(targ, x, y, button, istouch, presses)
	if self == targ then
		if button == self.context.mouse_pressed_button then
			if button == 1 then
				self.pressed = true
				local ax, ay = self:getAbsolutePosition()

				if self.center_on_pointer then
					self.mouse_ox = self.w/2
					self.mouse_oy = self.h/2
				else
					self.mouse_ox = x - ax
					self.mouse_oy = y - ay
				end

				self:captureFocus()
			end
		end
	end
end


function def:cpt_mouseMoved(x, y, dx, dy, istouch)
	-- Update mouse position
	self.context.mouse_x = x
	self.context.mouse_y = y

	local parent = self.parent
	if not parent then
		return true -- XXX perhaps this should be a fatal error.
	end

	local p_x, p_y = parent:getAbsolutePosition()

	self.x = x - p_x + parent.scr_x - self.mouse_ox
	self.y = y - p_y + parent.scr_y - self.mouse_oy

	self.x = math.max(self.drag_min_x, math.min(self.x, self.drag_max_x))
	self.y = math.max(self.drag_min_y, math.min(self.y, self.drag_max_y))

	self:wid_dragAction()
end


function def:cpt_mouseReleased(x, y, button, istouch, presses)
	if button == 1 then
		self.context.current_pressed = false
		self.context.mouse_pressed_button = false

		self:uncaptureFocus() -- XXX need to refresh hover state in case the widget has moved away from the pointer

		self.pressed = false
	end
end


function def:render()
	local r, g, b, a = 1, 1, 0, 1
	if self.pressed then
		r, g, b, a = 1, 0, 0, 1
	end

	love.graphics.setColor(r, g, b, a)

	love.graphics.setLineWidth(2)
	love.graphics.setLineStyle("smooth")
	love.graphics.setLineJoin("miter")

	love.graphics.rectangle("line", 0.5, 0.5, self.w - 1, self.h - 1)
end


return def
