
-- ProdUI
local uiLayout = require("prod_ui.ui_layout")
local widShared = require("prod_ui.common.wid_shared")


local plan = {}


function plan.make(parent)
	local context = parent.context

	local frame = parent:addChild("wimp/window_frame")
	frame.w = 640
	frame.h = 480
	frame:initialize()

	frame:setFrameTitle("DragBox Test")

	frame.auto_layout = true
	frame:setScrollBars(false, false)

	-- Drag box.
	local dbox = frame:addChild("test/drag_box")
	dbox.x, dbox.y, dbox.w, dbox.h = 400, 16, 64, 64
	dbox:initialize()

	frame:reshape(true)
	frame:center(true, true)

	return frame
end


return plan
