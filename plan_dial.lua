
-- ProdUI
local uiLayout = require("prod_ui.ui_layout")
local widShared = require("prod_ui.common.wid_shared")


local plan = {}


local function makeLabel(frame, x, y, w, h, text, label_mode)
	label_mode = label_mode or "single"

	local label = frame:addChild("base/label")
	label.x, label.y, label.w, label.h = x, y, w, h
	label:initialize()
	label:setLabel(text, label_mode)

	return label
end


function plan.make(parent)
	local context = parent.context

	local frame = parent:addChild("wimp/window_frame")
	frame.w = 640
	frame.h = 480
	frame:initialize()

	frame:setFrameTitle("Dials")

	frame.auto_layout = true
	frame:setScrollBars(false, false)

	local v_wid_w = 32
	local v_wid_h = 128
	local space_w = 64
	local xx = 0

	makeLabel(frame, xx, 0, 256, 32, "Dial -- **Under construction**")
	local dial1 = frame:addChild("base/dial")
	dial1.x = xx
	dial1.y = 32
	dial1.w = 64
	dial1.h = 64
	dial1:initialize()

	--:setDialParameters(pos, min, max, home, rnd)
	dial1:setDialParameters(0, 0, 100, 0, "none")

	frame:reshape(true)
	frame:center(true, true)

	return frame
end


return plan
