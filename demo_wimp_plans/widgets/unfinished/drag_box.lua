local plan = {}


function plan.make(panel)
	--title("DragBox Test")

	panel:layoutSetBase("viewport-width")
	panel:setScrollRangeMode("zero")
	panel:setScrollBars(false, false)

	-- Drag box.
	local dbox = panel:addChild("test/drag_box")
	dbox.x, dbox.y, dbox.w, dbox.h = 400, 16, 64, 64
end


return plan
