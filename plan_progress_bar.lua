
-- ProdUI
local uiLayout = require("prod_ui.ui_layout")
local widShared = require("prod_ui.logic.wid_shared")


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

	frame:setFrameTitle("Progress Bar Stuff")

	local content = frame:findTag("frame_content")
	if content then
		content.layout_mode = "resize"
		content:setScrollBars(false, false)

		local starting_pos = 23
		local starting_max = 42

		local h_bar_width, h_bar_height = 160, 40
		local v_bar_width, v_bar_height = 100, 160

		local p_bar = content:addChild("status/progress_bar")
		p_bar:setTag("demo_prog_bar")
		p_bar.x = 32
		p_bar.y = 32
		p_bar.w = h_bar_width
		p_bar.h = h_bar_height

		p_bar.pos = starting_pos
		p_bar.max = starting_max

		p_bar:setLabel("Progress Bar", "single")

		p_bar.wid_barChanged = function(self, old_pos, old_max, new_pos, new_max)
			print("wid_barChanged: old / new progress bar values: ", old_pos, old_max, new_pos, new_max)
		end

		p_bar:setActive(true)
		p_bar:reshape()


		local btn_active = content:addChild("base/button")
		btn_active.x = 256
		btn_active.y = 32
		btn_active.w = 128
		btn_active.h = 40

		btn_active:setLabel("setActive()")

		btn_active.wid_buttonAction = function(self)
			local pb = self:findSiblingTag("demo_prog_bar")
			if pb then
				pb:setActive(not pb.active)
			end
		end


		local btn_vertical = content:addChild("base/button")
		btn_vertical.x = 256
		btn_vertical.y = 32+40
		btn_vertical.w = 128
		btn_vertical.h = 40

		btn_vertical:setLabel("Orientation")

		btn_vertical.wid_buttonAction = function(self)
			local pb = self:findSiblingTag("demo_prog_bar")
			if pb then
				pb.vertical = not pb.vertical
				if pb.vertical then
					pb.w, pb.h = v_bar_width, v_bar_height

				else
					pb.w, pb.h = h_bar_width, h_bar_height
				end
				pb:reshape()
			end
		end


		local btn_far_end = content:addChild("base/button")
		btn_far_end.x = 256
		btn_far_end.y = 32+40+40
		btn_far_end.w = 128
		btn_far_end.h = 40

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

		local lbl_pos = makeLabel(content, 256, 160, 256, 32, "Position")
		lbl_pos:setTag("position_label")

		local sld_pos = content:addChild("base/slider_bar")
		sld_pos:setTag("position_slider")

		sld_pos.x = 256
		sld_pos.y = 160+32+8
		sld_pos.w = 256
		sld_pos.h = 32

		sld_pos.slider_pos = starting_pos
		sld_pos.slider_max = 100

		sld_pos.round_policy = "nearest"

		sld_pos.wid_actionSliderChanged = slider_action

		sld_pos:reshape()


		local lbl_max = makeLabel(content, 256, 160+32+8+32, 256, 32, "Maximum")
		lbl_max:setTag("maximum_label")

		local sld_max = content:addChild("base/slider_bar")
		sld_max:setTag("maximum_slider")

		sld_max.x = 256
		sld_max.y = 160+32+8+32+32+8
		sld_max.w = 256
		sld_max.h = 32

		sld_max.slider_pos = starting_max
		sld_max.slider_max = 100

		sld_max.round_policy = "nearest"

		sld_max.wid_actionSliderChanged = slider_action

		sld_max:reshape()
	end

	frame:reshape(true)
	frame:center(true, true)

	return frame
end


return plan
