local plan = {}


function plan.make(panel)
	--title("Label Tests")

	panel:layoutSetBase("viewport-width")
	panel:containerSetScrollRangeMode("zero")
	panel:setScrollBars(false, false)

	local xx, yy, ww, hh = 0, 0, 256, 32

	local grp = panel:addChild("base/group")
		:geometrySetMode("relative", 0, 0, 256, 256)
		:layoutSetStackFlow("y", 1)
		:layoutSetStackDefaultWidgetSize("pixel", 32)
		:setText("Control Labels")

	do
		local lbl1 = grp:addChild("base/control_label")
			:geometrySetMode("stack")
			:setHorizontalAlignment("left")
			:setText("Left")

		yy = yy + hh
	end

	do
		local lbl1 = grp:addChild("base/control_label")
			:geometrySetMode("stack")
			:setHorizontalAlignment("center")
			:setText("Center")

		yy = yy + hh
	end

	do
		local lbl1 = grp:addChild("base/control_label")
			:geometrySetMode("stack")
			:setHorizontalAlignment("right")
			:setText("Right")

		yy = yy + hh
	end

	do
		local font_id = "code"
		local lbl1 = grp:addChild("base/control_label")
			:geometrySetMode("stack")
			:setHorizontalAlignment("left")
			:setFontID(font_id)
			:setText("setFontID(\"" .. font_id .. "\")")

		yy = yy + hh
	end

	do
		local enabled = false
		local lbl1 = grp:addChild("base/control_label")
			:geometrySetMode("stack")
			:setHorizontalAlignment("left")
			:setEnabled(enabled)
			:setText("setEnabled(" .. tostring(enabled) ..")")

		yy = yy + hh
	end
end


return plan
