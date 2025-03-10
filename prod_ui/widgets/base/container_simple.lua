--[[
	A bare-minimum container.
--]]

local context = select(1, ...)


local widShared = context:getLua("core/wid_shared")


local def = {}


-- Called when the user clicks on the container's blank space (no widgets, no embedded controls).
function def:wid_pressed(x, y, button, istouch, presses)

end


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true
	self.can_have_thimble = false
	--self.clip_hover = true
	--self.clip_scissor = true

	widShared.setupMinMaxDimensions(self)

	-- Don't highlight when holding the UI thimble.
	self.renderThimble = widShared.dummy
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self == inst then
		if button == self.context.mouse_pressed_button then
			if button <= 3 then
				self:tryTakeThimble1()
			end

			self:wid_pressed(x, y, button, istouch, presses)
		end
	end
end


--[[
function def:uiCall_reshape???()
	widShared.enforceLimitedDimensions(self)
end
--]]


return def
