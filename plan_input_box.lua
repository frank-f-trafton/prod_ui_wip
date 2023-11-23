

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

	frame:setFrameTitle("Input Boxes")

	local content = frame:findTag("frame_content")
	if content then
		content.layout_mode = "resize"
		content:setScrollBars(false, false)

		local input_box_s = content:addChild("barebones/input_box")

		input_box_s.x = 32
		input_box_s.y = 32
		input_box_s.w = 256
		input_box_s.h = 32

		input_box_s:setText("Barebones Input Box")

		--input_box_s:setMaxCodePoints(4)

		--[[
		local input_single = content:addChild("input/text_box_single")

		input_single.x = 32
		input_single.y = 96
		input_single.w = 256
		input_single.h = 32

		--input_box_s:setText("Single-Line Text Box")
		--]]
	end

	frame:reshape(true)
	frame:center(true, true)

	return frame
end


return plan
