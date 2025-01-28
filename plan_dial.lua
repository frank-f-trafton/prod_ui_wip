
-- ProdUI
local uiLayout = require("prod_ui.ui_layout")
local widShared = require("prod_ui.common.wid_shared")


local plan = {}


local function makeLabel(content, x, y, w, h, text, label_mode)
	label_mode = label_mode or "single"

	local label = content:addChild("base/label")
	label.x, label.y, label.w, label.h = x, y, w, h
	label:setLabel(text, label_mode)

	return label
end


function plan.make(parent)
	local context = parent.context

	local frame = parent:addChild("wimp/window_frame")

	frame.w = 640
	frame.h = 480

	frame:setFrameTitle("Dials")

	local content = frame:findTag("frame_content")
	if content then
		content.layout_mode = "resize"
		content:setScrollBars(false, false)

		local v_wid_w = 32
		local v_wid_h = 128
		local space_w = 64
		local xx = 0

		makeLabel(content, xx, 0, 256, 32, "Dial -- **Under construction**")
		local dial1 = content:addChild("base/slider_radial")

		dial1.x = xx
		dial1.y = 32
		dial1.w = 64
		dial1.h = 64

		dial1.slider_pos = 0
		dial1.slider_max = 5

		dial1.round_policy = "nearest"
	end

	frame:reshape(true)
	frame:center(true, true)

	return frame
end


return plan
