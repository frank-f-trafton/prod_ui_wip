
-- ProdUI
local uiLayout = require("prod_ui.ui_layout")
local widShared = require("prod_ui.common.wid_shared")


local plan = {}


function plan.make(panel)
	--title("DragBox Test")

	panel.auto_layout = true
	panel:setScrollBars(false, false)

	-- Drag box.
	local dbox = panel:addChild("test/drag_box")
	dbox.x, dbox.y, dbox.w, dbox.h = 400, 16, 64, 64
	dbox:initialize()
	dbox:register("static")
end


return plan
