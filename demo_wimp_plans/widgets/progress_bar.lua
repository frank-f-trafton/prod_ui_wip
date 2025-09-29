
-- ProdUI
local demoShared = require("demo_shared")


local plan = {}


function plan.make(panel)
	--title("Progress Bar Stuff")

	panel:layoutSetBase("viewport-width")
	panel:setScrollRangeMode("zero")
	panel:setScrollBars(false, false)

	local starting_pos = 23
	local starting_max = 42

	local bar_x, bar_y = 32, 32
	local h_bar_width, h_bar_height = 160, 40
	local v_bar_width, v_bar_height = 100, 160

	local p_bar = panel:addChild("status/progress_bar")
	p_bar:geometrySetMode("static", bar_x, bar_y, h_bar_width, h_bar_height)
	p_bar:setTag("demo_prog_bar")

	p_bar.pos = starting_pos
	p_bar.max = starting_max

	p_bar:setLabel("Progress Bar", "single")

	p_bar.wid_barChanged = function(self, old_pos, old_max, new_pos, new_max)
		print("wid_barChanged: old / new progress bar values: ", old_pos, old_max, new_pos, new_max)
	end

	p_bar:setActive(true)

	local btn_active = panel:addChild("base/button")
	btn_active:geometrySetMode("static", 256, 32, 128, 40)
	btn_active:setLabel("setActive()")

	btn_active.wid_buttonAction = function(self)
		local pb = self:findSiblingTag("demo_prog_bar")
		if pb then
			pb:setActive(not pb.active)
		end
	end


	local btn_vertical = panel:addChild("base/button")
	btn_vertical:geometrySetMode("static", 256, 32+40, 128, 40)
	btn_vertical:setLabel("Orientation")

	btn_vertical.wid_buttonAction = function(self)
		local pb = self:findSiblingTag("demo_prog_bar")
		if pb then
			pb.vertical = not pb.vertical
			if pb.vertical then
				pb:geometrySetMode("static", bar_x, bar_y, v_bar_width, v_bar_height)
			else
				pb:geometrySetMode("static", bar_x, bar_y, h_bar_width, h_bar_height)
			end
			pb.parent:reshape()
			print(pb.vertical, pb:geometryGetMode())
		end
	end


	local btn_far_end = panel:addChild("base/button")
	btn_far_end:geometrySetMode("static", 256, 32+40+40, 128, 40)
	btn_far_end:setLabel("Near/Far Start")

	btn_far_end.wid_buttonAction = function(self)
		local pb = self:findSiblingTag("demo_prog_bar")
		if pb then
			pb.far_end = not pb.far_end
			pb:reshape()
		end
	end

	-- Two sliders control the demo progress bar's position and maximum value.

	-- A shared action callback for both sliders.
	local slider_action = function(self)
		local p_bar = self:findSiblingTag("demo_prog_bar")
		local sld_pos = self:findSiblingTag("position_slider")
		local sld_max = self:findSiblingTag("maximum_slider")
		if p_bar and sld_pos and sld_max then
			p_bar:setCounter(sld_pos.slider_pos, sld_max.slider_pos)

			if p_bar.max == 0 then
				p_bar:setLabel("(Div/0)")
			else
				p_bar:setLabel(string.format("%.2f%%", (p_bar.pos / p_bar.max) * 100))
			end

			local l_pos = self:findSiblingTag("position_label")
			if l_pos then
				l_pos:setLabel("Position: " .. tostring(p_bar.pos))
			end

			local l_max = self:findSiblingTag("maximum_label")
			if l_max then
				l_max:setLabel("Maximum: " .. tostring(p_bar.max))
			end
		end
	end

	local lbl_pos = demoShared.makeLabel(panel, 256, 160, 256, 32, "Position")
	lbl_pos:setTag("position_label")

	local sld_pos = panel:addChild("base/slider_bar")
	sld_pos:geometrySetMode("static", 256, 160+32+8, 256, 32)
	sld_pos:setTag("position_slider")

	sld_pos.slider_pos = starting_pos
	sld_pos.slider_max = 100

	sld_pos.round_policy = "nearest"

	sld_pos.wid_actionSliderChanged = slider_action


	local lbl_max = demoShared.makeLabel(panel, 256, 160+32+8+32, 256, 32, "Maximum")
	lbl_max:setTag("maximum_label")

	local sld_max = panel:addChild("base/slider_bar")
	sld_max:geometrySetMode("static", 256, 160+32+8+32+32+8, 256, 32)
	sld_max:setTag("maximum_slider")

	sld_max.slider_pos = starting_max
	sld_max.slider_max = 100

	sld_max.round_policy = "nearest"

	sld_max.wid_actionSliderChanged = slider_action
end


return plan
