-- A bare-minimum container.


local context = select(1, ...)


local widLayout = context:getLua("core/wid_layout")


local def = {}


widLayout.setupContainerDef(def)


function def:evt_initialize()
	self.visible = true
	self.allow_hover = true

	widLayout.setupLayoutList(self)
end


function def:evt_getGrowAxisLength(x_axis, cross_length)
	if not x_axis then
		local scale = context.scale

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


function def:evt_pointerPress(targ, x, y, button, istouch, presses)
	if self == targ then
		-- Try directing thimble1 to the container's UI Frame ancestor.
		if button <= 3 then
			local wid = self
			while wid do
				if wid.frame_type then
					break
				end
				wid = wid.parent
			end
			if wid then
				wid:tryTakeThimble1()
			end
		end
	end
end


return def
