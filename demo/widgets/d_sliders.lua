
-- ProdUI
local demoShared = require("demo_shared")


local plan = {}


function plan.make(panel)
	demoShared.makeTitle(panel, nil, "Slider Bar")

	panel:layoutSetBase("viewport-width")
	panel:containerSetScrollRangeMode("zero")
	panel:setScrollBars(false, false)

	local slider_breadth = 40

	local s_box_x = 16
	local s_box_y = 16
	local s_box_w = 200
	local s_box_h = 200

	local default_vertical = false

	local shx, shy, shw, shh = 0, 0, 0, 0


	local controls_x = 400
	local controls_y = 0
	local controls_w = 188
	local controls_h = 32
	local controls_spacing_y = 8

	local labels_w = 200
	local labels_x = controls_x - labels_w


	local function _determineSliderCoords(vert)
		if vert then
			shx = math.floor((s_box_w - slider_breadth) * .5)
			shy = s_box_y
			shw = slider_breadth
			shh = s_box_h
		else
			shx = s_box_x
			shy = math.floor((s_box_h - slider_breadth) * .5)
			shw = s_box_w
			shh = slider_breadth
		end
	end

	_determineSliderCoords(default_vertical)

	local function _updateSlider(self)
		-- NOTE: 'self' could be any of the sibling controls.

		local sld = self:findSiblingTag("demo_sld")
		if not sld then
			print("WARNING: couldn't locate the slider to update!")
			return
		end

		local c_max = sld:findSiblingTag("demo_sld_max")
		if c_max then
			local v = c_max:getValue()
			if v then
				sld:sliderSetMax(v)
			else
				print("WARNING: couldn't read slider 'max' from control")
			end
		end

		local c_home = sld:findSiblingTag("demo_sld_home")
		if c_home then
			local v = c_home:getValue()
			if v then
				sld:sliderSetHome(v)
			else
				print("WARNING: couldn't read slider 'home' from control")
			end
		end

		local c_orientation = sld:findSiblingTag("demo_sld_orientation")
		if c_orientation then
			local orientation = c_orientation:getSelectedOption()
			if orientation then
				sld:sliderSetOrientation(orientation)
			else
				print("WARNING: couldn't read slider 'orientation' from control")
			end
		end

		local c_use_line = sld:findSiblingTag("demo_sld_use_line")
		if c_use_line then
			local use_line = c_use_line:getChecked()
			sld:sliderSetShowUseLine(use_line)
		end

		local c_reverse = sld:findSiblingTag("demo_sld_reverse")
		if c_reverse then
			local reverse = c_reverse:getChecked()
			sld:sliderSetCountReverse(reverse)
		end

		local c_gran = sld:findSiblingTag("demo_sld_granularity")
		if c_gran then
			local v = c_gran:getValue()
			if v then
				sld:sliderSetGranularity(v)
			else
				print("WARNING: couldn't read slider 'granularity' from control")
			end
		end

		local c_wheel_dir = sld:findSiblingTag("demo_sld_wheel")
		if c_wheel_dir then
			local wheel_dir = tonumber(c_wheel_dir:getSelectedOption())
			if wheel_dir then
				sld:sliderSetWheelDirection(wheel_dir)
			else
				print("WARNING: couldn't read slider 'wheel_dir' from control")
			end
		end

		local c_allow_changes = sld:findSiblingTag("demo_sld_allow_changes")
		if c_allow_changes then
			local allow_changes = c_allow_changes:getChecked()
			sld:sliderSetAllowChanges(allow_changes)
		end

		_determineSliderCoords(sld:sliderGetOrientation() == "vertical")
		sld:geometrySetMode("static", shx, shy, shw, shh, true)
		sld.parent:reshape()
	end


	local slider = panel:addChild("base/slider_bar")
	slider:geometrySetMode("static", shx, shy, shw, shh, true)
		:setTag("demo_sld")
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

	--slider.wid_actionSliderChanged =

	local xx, yy = controls_x, controls_y

	demoShared.makeLabel(panel, labels_x, yy, labels_w, controls_h, true, "Max", "single")
	local c_max = panel:addChild("wimp/number_box")
		:setTag("demo_sld_max")
		:geometrySetMode("static", xx, yy, controls_w, controls_h, true)
		:setValue(5)

	c_max.wid_action = function(self)
		_updateSlider(self)
	end

	yy = yy + controls_h + controls_spacing_y

	demoShared.makeLabel(panel, labels_x, yy, labels_w, controls_h, true, "'Home' position", "single")
	local c_home = panel:addChild("wimp/number_box")
		:setTag("demo_sld_home")
		:geometrySetMode("static", xx, yy, controls_w, controls_h, true)
		:setValue(0)

	c_home.wid_action = function(self)
		_updateSlider(self)
	end

	yy = yy + controls_h + controls_spacing_y

	demoShared.makeLabel(panel, labels_x, yy, labels_w, controls_h, true, "Orientation", "single")
	local c_orientation = panel:addChild("base/stepper")
		:setTag("demo_sld_orientation")
		:geometrySetMode("static", xx, yy, controls_w, controls_h, true)

	c_orientation:insertOption("horizontal")
	c_orientation:insertOption("vertical")

	c_orientation.wid_buttonAction = function(self)
		_updateSlider(self)
	end

	yy = yy + controls_h + controls_spacing_y

	demoShared.makeLabel(panel, labels_x, yy, labels_w, controls_h, true, "Show 'use' line", "single")
	local c_use_line = panel:addChild("base/checkbox")
		:setTag("demo_sld_use_line")
		:geometrySetMode("static", xx, yy, controls_w, controls_h, true)
		:setChecked(false)

	c_use_line.wid_buttonAction = function(self)
		_updateSlider(self)
	end

	yy = yy + controls_h + controls_spacing_y

	demoShared.makeLabel(panel, labels_x, yy, labels_w, controls_h, true, "Reverse count", "single")
	local c_reverse = panel:addChild("base/checkbox")
		:setTag("demo_sld_reverse")
		:geometrySetMode("static", xx, yy, controls_w, controls_h, true)
		:setChecked(false)

	c_reverse.wid_buttonAction = function(self)
		_updateSlider(self)
	end

	yy = yy + controls_h + controls_spacing_y

	demoShared.makeLabel(panel, labels_x, yy, labels_w, controls_h, true, "Granularity", "single")
	local c_gran = panel:addChild("wimp/number_box")
		:setTag("demo_sld_granularity")
		:geometrySetMode("static", xx, yy, controls_w, controls_h, true)
		:setValue(1)

	c_gran.wid_action = function(self)
		_updateSlider(self)
	end

	yy = yy + controls_h + controls_spacing_y

	demoShared.makeLabel(panel, labels_x, yy, labels_w, controls_h, true, "Wheel scroll dir", "single")
	local c_wheel_dir = panel:addChild("base/stepper")
		:setTag("demo_sld_wheel")
		:geometrySetMode("static", xx, yy, controls_w, controls_h, true)

	c_wheel_dir:insertOption("1")
	c_wheel_dir:insertOption("-1")

	c_wheel_dir.wid_buttonAction = function(self)
		_updateSlider(self)
	end

	yy = yy + controls_h + controls_spacing_y

	demoShared.makeLabel(panel, labels_x, yy, labels_w, controls_h, true, "Allow user changes", "single")
	local c_allow_changes = panel:addChild("base/checkbox")
		:setTag("demo_sld_allow_changes")
		:geometrySetMode("static", xx, yy, controls_w, controls_h, true)
		:setChecked(true)

	c_allow_changes.wid_buttonAction = function(self)
		_updateSlider(self)
	end

	yy = yy + controls_h + controls_spacing_y

	local c_update = panel:addChild("base/button")
		:setTag("demo_sld_update")
		:geometrySetMode("static", xx, yy, controls_w, controls_h, true)
		:setLabel("Update!", "single")

	c_update.wid_buttonAction = _updateSlider

	_updateSlider(c_update)

	return panel
end


return plan
