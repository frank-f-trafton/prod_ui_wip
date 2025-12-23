
-- ProdUI
local demoShared = require("demo_shared")


local plan = {}


local slider_length = 200
local slider_breadth = 40
local default_vertical = false

local shx, shy, shw, shh = 0, 0, 0, 0


local controls_x = 400
local controls_y = 0
local controls_w = 160
local controls_h = 32
local controls_spacing_y = 8

local labels_w = 200
local labels_x = controls_x - labels_w


local function _determineSliderCoords(vert)
	if vert then
		shw, shh = slider_breadth, slider_length
	else
		shw, shh = slider_length, slider_breadth
	end
end


function plan.make(panel)
	demoShared.makeTitle(panel, nil, "Slider Bars")

	panel:layoutSetBase("viewport-width")
	panel:containerSetScrollRangeMode("zero")
	panel:setScrollBars(false, false)

	local xx = 0

	_determineSliderCoords(default_vertical)

	local slider = panel:addChild("base/slider_bar")
	slider:geometrySetMode("static", shx, shy, shw, shh, true)
		:sliderSetMax(5)
		:sliderSetPosition(0)
		:sliderSetOrientation("horizontal")
		:sliderSetShowUseLine(true)
		:sliderSetCountReverse(false)
		:sliderSetGranularity(1)
		:sliderSetWheelDirection(1)
		:sliderSetHome(0)
		:sliderSetAllowChanges(true)
		:setLabel("Slider")

	local xx, yy = controls_x, controls_y

	demoShared.makeLabel(panel, labels_x, yy, labels_w, controls_h, true, "Position", "single")
	local c_pos = panel:addChild("wimp/number_box")
		:geometrySetMode("static", xx, yy, controls_w, controls_h, true)

	yy = yy + controls_h + controls_spacing_y

	demoShared.makeLabel(panel, labels_x, yy, labels_w, controls_h, true, "Max", "single")
	local c_max = panel:addChild("wimp/number_box")
		:geometrySetMode("static", xx, yy, controls_w, controls_h, true)

	yy = yy + controls_h + controls_spacing_y

	demoShared.makeLabel(panel, labels_x, yy, labels_w, controls_h, true, "'Home' position", "single")
	local c_home = panel:addChild("wimp/number_box")
		:geometrySetMode("static", xx, yy, controls_w, controls_h, true)

	yy = yy + controls_h + controls_spacing_y

	demoShared.makeLabel(panel, labels_x, yy, labels_w, controls_h, true, "Orientation", "single")
	local c_orientation = panel:addChild("base/stepper")
		:geometrySetMode("static", xx, yy, controls_w, controls_h, true)

	yy = yy + controls_h + controls_spacing_y

	demoShared.makeLabel(panel, labels_x, yy, labels_w, controls_h, true, "Show 'use' line", "single")
	local c_use_line = panel:addChild("base/checkbox")
		:geometrySetMode("static", xx, yy, controls_w, controls_h, true)

	yy = yy + controls_h + controls_spacing_y

	demoShared.makeLabel(panel, labels_x, yy, labels_w, controls_h, true, "Reverse count", "single")
	local c_reverse = panel:addChild("base/checkbox")
		:geometrySetMode("static", xx, yy, controls_w, controls_h, true)

	yy = yy + controls_h + controls_spacing_y

	demoShared.makeLabel(panel, labels_x, yy, labels_w, controls_h, true, "Granularity", "single")
	local c_gran = panel:addChild("wimp/number_box")
		:geometrySetMode("static", xx, yy, controls_w, controls_h, true)

	yy = yy + controls_h + controls_spacing_y

	demoShared.makeLabel(panel, labels_x, yy, labels_w, controls_h, true, "Wheel scroll dir", "single")
	local c_wheel_dir = panel:addChild("base/stepper")
		:geometrySetMode("static", xx, yy, controls_w, controls_h, true)

	yy = yy + controls_h + controls_spacing_y

	demoShared.makeLabel(panel, labels_x, yy, labels_w, controls_h, true, "Allow changes", "single")
	local c_allow_changes = panel:addChild("base/checkbox")
		:geometrySetMode("static", xx, yy, controls_w, controls_h, true)

	return panel
end


return plan
