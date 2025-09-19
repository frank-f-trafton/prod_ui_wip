-- A bare-minimum container.


local context = select(1, ...)


local widLayout = context:getLua("core/wid_layout")
local widShared = context:getLua("core/wid_shared")


local def = {}


widLayout.setupContainerDef(def)


function def:uiCall_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 0

	widLayout.setupLayoutList(self)

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


function def:uiCall_reshapePre()
	widLayout.resetLayoutSpace(self)
end


return def
