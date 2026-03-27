-- A bare-minimum container.


local context = select(1, ...)


local uiDummy = require(context.conf.prod_ui_req .. "ui_dummy")
local widLayout = context:getLua("core/wid_layout")
local widShared = context:getLua("core/wid_shared")


local def = {}


widLayout.setupContainerDef(def)


function def:evt_initialize()
	self.visible = true
	self.allow_hover = true
	self.thimble_mode = 0

	widLayout.setupLayoutList(self)

	-- Don't highlight when holding the UI thimble.
	self.renderThimble = uiDummy.func
end


function def:evt_pointerPress(targ, x, y, button, istouch, presses)
	if self == targ then
		if button == self.context.mouse_pressed_button then
			if button <= 3 then
				self:tryTakeThimble1()
			end
		end
	end
end


function def:evt_getGrowAxisLength(x_axis, cross_length)
	if not x_axis then
		local scale = context.scale
		local skin = self.skin

		local h = 0

		for i, child in ipairs(self.LO_list) do
			local len, do_scale = child:evt_getGrowAxisLength(x_axis, cross_length)
			if len then
				local this_scale = do_scale and scale or 1.0
				h = h + len * this_scale
			end
		end

		local my1, my2 = self.LO_margin_y1, self.LO_margin_y2
		h = h + my1 + my2

		return h, false
	end
end


function def:evt_reshapePre()
	widLayout.resetLayoutSpace(self)
end


return def
