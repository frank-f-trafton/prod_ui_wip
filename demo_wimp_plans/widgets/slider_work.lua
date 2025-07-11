
-- ProdUI
local demoShared = require("demo_shared")


local plan = {}


function plan.make(panel)
	--title("Slider Bar Work")

	panel:setLayoutBase("viewport-width")
	panel:setScrollRangeMode("zero")
	panel:setScrollBars(false, false)

	local label_w = 128
	local label_h = 32
	local h_wid_w = 128
	local h_wid_h = 32
	local v_wid_w = 32
	local v_wid_h = 128
	local space_w = 64
	local xx = 0

	-- Horizontal slider
	-- [===[
	demoShared.makeLabel(panel, xx, 0, label_w, label_h, "Horizontal")
	local sliderh1 = panel:addChild("base/slider_bar")
	demoShared.setStaticLayout(panel, sliderh1, xx, 32, h_wid_w, h_wid_h)

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
	--]===]

	xx = xx + h_wid_w + space_w

	-- Horizontal slider (user input disabled)
	-- [===[
	demoShared.makeLabel(panel, xx, 0, label_w, label_h, "Read-Only")
	local sliderh2 = panel:addChild("base/slider_bar")
	demoShared.setStaticLayout(panel, sliderh2, xx, 32, h_wid_w, h_wid_h)

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
	--]===]

	xx = xx + h_wid_w + space_w

	-- Horizontal slider (whole widget disabled)
	-- [===[
	demoShared.makeLabel(panel, xx, 0, label_w, label_h, "Widget Disabled")
	local sliderh3 = panel:addChild("base/slider_bar")
	demoShared.setStaticLayout(panel, sliderh3, xx, 32, h_wid_w, h_wid_h)

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
	--]===]

	xx = 0

	-- Vertical slider
	-- [===[
	demoShared.makeLabel(panel, xx, 128, label_w, label_h, "Vertical")
	local sliderv1 = panel:addChild("base/slider_bar")
	demoShared.setStaticLayout(panel, sliderv1, math.floor(xx + (128 - v_wid_w) * 0.5), 160, v_wid_w, v_wid_h)

	sliderv1.trough_vertical = true

	sliderv1.slider_pos = 0
	sliderv1.slider_max = 64

	sliderv1.round_policy = "nearest"
	sliderv1.count_reverse = true
	sliderv1.wheel_dir = -1

	--sliderv1:setLabel("Vert")
	--sliderv1.slider_home = math.floor(0.5 + slider_v.slider_max/2)

	sliderv1:reshape()
	--]===]

	xx = xx + h_wid_w + space_w

	-- Vertical Read-Only
	-- [===[
	demoShared.makeLabel(panel, xx, 128, label_w, label_h, "Read-Only")
	local sliderv2 = panel:addChild("base/slider_bar")
	demoShared.setStaticLayout(panel, sliderv2, math.floor(xx + (128 - v_wid_w) * 0.5), 160, v_wid_w, v_wid_h)

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
	--]===]

	xx = xx + h_wid_w + space_w

	-- Vertical (Disabled)
	-- [===[
	demoShared.makeLabel(panel, xx, 128, label_w, label_h, "Widget Disabled")
	local sliderv3 = panel:addChild("base/slider_bar")
	demoShared.setStaticLayout(panel, sliderv3, math.floor(xx + (128 - v_wid_w) * 0.5), 160, v_wid_w, v_wid_h)

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
	--]===]

	xx = xx + h_wid_w + space_w

	return panel
end


return plan
