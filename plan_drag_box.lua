
-- ProdUI
local commonMenu = require("lib.prod_ui.logic.common_menu")
local uiLayout = require("lib.prod_ui.ui_layout")
local widShared = require("lib.prod_ui.logic.wid_shared")


local plan = {}


function plan.make(parent)

	local context = parent.context

	local frame = parent:addChild("wimp/window_frame")

	frame.w = 640
	frame.h = 480

	frame:setFrameTitle("DragBox Test")

	local content = frame:findTag("frame_content")
	if content then
		content.layout_mode = "resize"
		content:setScrollBars(false, false)

		-- Drag box.
		local dbox = content:addChild("test/drag_box")
		dbox.x, dbox.y, dbox.w, dbox.h = 400, 16, 64, 64
	end

	frame:reshape(true)
	frame:center(true, true)

	return frame
end


return plan
