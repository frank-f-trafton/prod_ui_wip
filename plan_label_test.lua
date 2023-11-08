
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

	frame:setFrameTitle("Label Tests")

	local content = frame:findTag("frame_content")
	if content then
		content.layout_mode = "resize"
		content:setScrollBars(false, false)

		-- Single-Line.
		local lbl1 = content:addChild("base/label")
		lbl1.x, lbl1.y, lbl1.w, lbl1.h = 0, 0, 240, 32
		lbl1:setLabel("Single-Line Label", "single")

		-- Single-Line with underline.
		local lbl2 = content:addChild("base/label")
		lbl2.x, lbl2.y, lbl2.w, lbl2.h = 0, 64, 240, 32
		lbl2:setLabel("Single-Line Plus _Underline_", "single-ul")

		-- Multi-Line
		local lbl3 = content:addChild("base/label")
		lbl3.x, lbl3.y, lbl3.w, lbl3.h = 0, 96, 240, 64
		lbl3:setLabel("Multi-Line Multi-Line Multi-Line Multi-Line Multi-Line", "multi")
	end

	frame:center(true, true)

	return frame
end


return plan
