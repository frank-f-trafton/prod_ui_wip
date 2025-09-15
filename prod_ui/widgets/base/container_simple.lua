-- A bare-minimum container.


local context = select(1, ...)


local widShared = context:getLua("core/wid_shared")


local def = {}


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 0

	-- Don't highlight when holding the UI thimble.
	self.renderThimble = widShared.dummy
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self == inst then
		if button == self.context.mouse_pressed_button then
			if button <= 3 then
				self:tryTakeThimble1()
			end
		end
	end
end


return def
