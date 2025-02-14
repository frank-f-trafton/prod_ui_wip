
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

	frame:setFrameTitle("Slider Bar Work")

	frame.auto_layout = true
	frame:setScrollBars(false, false)

	local label_w = 128
	local label_h = 32
	local h_wid_w = 128
	local h_wid_h = 32
	local v_wid_w = 32
	local v_wid_h = 128
	local space_w = 64
	local xx = 0

	-- Horizontal slider
	makeLabel(frame, xx, 0, label_w, label_h, "Horizontal")
	local sliderh1 = frame:addChild("base/slider_bar")
	sliderh1.x = xx
	sliderh1.y = 32
	sliderh1.w = h_wid_w
	sliderh1.h = h_wid_h
	sliderh1:initialize()

	sliderh1.trough_vertical = false

	--sliderh1.show_use_line = false

	sliderh1.slider_pos = 0
	sliderh1.slider_max = 5

	sliderh1.round_policy = "nearest"
	sliderh1.count_reverse = false--true
	sliderh1.wheel_dir = 1


	sliderh1:setLabel("Slider")

	--sliderh1.slider_home = 1

	sliderh1:reshape()

	xx = xx + h_wid_w + space_w

	-- Horizontal slider (user input disabled)
	makeLabel(frame, xx, 0, label_w, label_h, "Read-Only")
	local sliderh2 = frame:addChild("base/slider_bar")
	sliderh2.x = xx
	sliderh2.y = 32
	sliderh2.w = h_wid_w
	sliderh2.h = h_wid_h
	sliderh2:initialize()

	sliderh2.trough_vertical = false

	--sliderh2.show_use_line = false

	sliderh2.slider_pos = 0
	sliderh2.slider_max = 5

	sliderh2.round_policy = "nearest"
	sliderh2.count_reverse = false--true
	sliderh2.wheel_dir = 1

	sliderh2:setLabel("Disabled Slider")

	sliderh2:setSliderAllowChanges(false)

	--sliderh2.slider_home = 1

	sliderh2:reshape()

	xx = xx + h_wid_w + space_w

	-- Horizontal slider (whole widget disabled)
	makeLabel(frame, xx, 0, label_w, label_h, "Widget Disabled")
	local sliderh3 = frame:addChild("base/slider_bar")
	sliderh3.x = xx
	sliderh3.y = 32
	sliderh3.w = h_wid_w
	sliderh3.h = h_wid_h
	sliderh3:initialize()

	sliderh3.trough_vertical = false

	--sliderh3.show_use_line = false

	sliderh3.slider_pos = 0
	sliderh3.slider_max = 5

	sliderh3.round_policy = "nearest"
	sliderh3.count_reverse = false--true
	sliderh3.wheel_dir = 1

	sliderh3:setLabel("Disabled Slider")

	sliderh3:setEnabled(false)

	--sliderh3.slider_home = 1

	sliderh3:reshape()

	xx = 0

	-- Vertical slider
	makeLabel(frame, xx, 128, label_w, label_h, "Vertical")
	local sliderv1 = frame:addChild("base/slider_bar")
	sliderv1.x = math.floor(xx + (128 - v_wid_w) * 0.5)
	sliderv1.y = 160
	sliderv1.w = v_wid_w
	sliderv1.h = v_wid_h
	sliderv1:initialize()

	sliderv1.trough_vertical = true

	sliderv1.slider_pos = 0
	sliderv1.slider_max = 64

	sliderv1.round_policy = "nearest"
	sliderv1.count_reverse = true
	sliderv1.wheel_dir = -1

	--sliderv1:setLabel("Vert")
	--sliderv1.slider_home = math.floor(0.5 + slider_v.slider_max/2)

	sliderv1:reshape()

	xx = xx + h_wid_w + space_w

	-- Vertical Read-Only
	makeLabel(frame, xx, 128, label_w, label_h, "Read-Only")
	local sliderv2 = frame:addChild("base/slider_bar")
	sliderv2.x = math.floor(xx + (128 - v_wid_w) * 0.5)
	sliderv2.y = 160
	sliderv2.w = v_wid_w
	sliderv2.h = v_wid_h
	sliderv2:initialize()

	sliderv2.trough_vertical = true

	sliderv2.slider_pos = 0
	sliderv2.slider_max = 64

	sliderv2.round_policy = "nearest"
	sliderv2.count_reverse = true
	sliderv2.wheel_dir = -1

	sliderv2:setSliderAllowChanges(false)

	--sliderv2:setLabel("Vert")
	--sliderv2.slider_home = math.floor(0.5 + slider_v.slider_max/2)

	sliderv2:reshape()

	xx = xx + h_wid_w + space_w

	-- Vertical (Disabled)
	makeLabel(frame, xx, 128, label_w, label_h, "Widget Disabled")
	local sliderv3 = frame:addChild("base/slider_bar")
	sliderv3.x = math.floor(xx + (128 - v_wid_w) * 0.5)
	sliderv3.y = 160
	sliderv3.w = v_wid_w
	sliderv3.h = v_wid_h
	sliderv3:initialize()

	sliderv3.trough_vertical = true

	sliderv3.slider_pos = 0
	sliderv3.slider_max = 64

	sliderv3.round_policy = "nearest"
	sliderv3.count_reverse = true
	sliderv3.wheel_dir = -1

	sliderv3:setEnabled(false)

	--sliderv3:setLabel("Vert")
	--sliderv3.slider_home = math.floor(0.5 + slider_v.slider_max/2)

	sliderv3:reshape()

	xx = xx + h_wid_w + space_w

	frame:reshape(true)
	frame:center(true, true)

	return frame
end


return plan
