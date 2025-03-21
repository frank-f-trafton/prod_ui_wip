
local plan = {
	container_type = "base/container"
}


local uiLayout = require("prod_ui.ui_layout")


function plan.make(panel)
	--title("Label Tests")

	panel:setScrollBars(false, false)

	-- Single-Line.
	local lbl1 = panel:addChild("base/label")
	lbl1.x, lbl1.y, lbl1.w, lbl1.h = 0, 0, 240, 32
	lbl1:initialize()
	lbl1:register("static")
	lbl1:setLabel("Single-Line Label", "single")

	-- Single-Line with underline.
	local lbl2 = panel:addChild("base/label")
	lbl2.x, lbl2.y, lbl2.w, lbl2.h = 0, 64, 240, 32
	lbl2:initialize()
	lbl2:register("static")
	lbl2:setLabel("Single-Line Plus _Underline_", "single-ul")

	-- Multi-Line
	local lbl3 = panel:addChild("base/label")
	lbl3.x, lbl3.y, lbl3.w, lbl3.h = 0, 96, 240, 64
	lbl3:initialize()
	lbl3:register("static")
	lbl3:setLabel("Multi-Line Multi-Line Multi-Line Multi-Line Multi-Line", "multi")
end


return plan
