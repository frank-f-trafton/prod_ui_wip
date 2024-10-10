--[[
	A bare-minimum container.
--]]

local context = select(1, ...)


local widShared = require(context.conf.prod_ui_req .. "logic.wid_shared")


local def = {}


-- Called when the user clicks on the container's blank space (no widgets, no embedded controls).
function def:wid_pressed(x, y, button, istouch, presses)

end


function def:uiCall_create(inst)
	if self == inst then
		self.visible = true
		self.allow_hover = true
		self.can_have_thimble = false
		self.clip_hover = false
		self.clip_scissor = false

		widShared.setupMinMaxDimensions(self)

		-- Don't highlight when holding the UI thimble.
		self.renderThimble = widShared.dummy
	end
end


function def:uiCall_pointerPress(inst, x, y, button, istouch, presses)
	if self == inst then
		if button == self.context.mouse_pressed_button then
			if button <= 3 then
				self:tryTakeThimble()
			end

			self:wid_pressed(x, y, button, istouch, presses)
		end
	end
end


--[[
function def:uiCall_reshape()
	widShared.enforceLimitedDimensions(self)
end
--]]


return def
