
local plan = {}


-- ProdUI
local demoShared = require("demo_shared")


function plan.makeWindowFrame(root)
	local context = root.context

	local wid_id = "wimp/window_frame"
	local skin_id = root.context.widget_defs[wid_id].skin_id .. "_DEMO"
	local frame = root:newWindowFrame(skin_id)
	frame.w = 640
	frame.h = 480
	frame:setFrameTitle("WIMP Window Frame")

	frame:layoutSetBase("viewport-width")
	frame:containerSetScrollRangeMode("auto")
	frame:setScrollBars(false, true)

	local xx, yy, ww, hh = 16, 16, 192, 32

	-- Radio Buttons: Header size
	do
		local text1 = frame:addChild("wimp/text_block")
		-- XXX work on syncing padding with embedded widget labels
		text1:geometrySetMode("static", xx + 9, yy, ww, hh)
		text1:setText("Header size")
		yy = yy + hh

		local r_action = function(self)
			local frame = self:getUIFrame()
			if frame then
				frame:setHeaderSize(self.usr_header_size)
			end
		end

		-- Small
		do
			local rad_btn = frame:addChild("base/radio_button")
			rad_btn:geometrySetMode("static", xx, yy, ww, hh)

			rad_btn.radio_group = "rg_header_size"
			rad_btn:setLabel("Small")
			rad_btn.usr_header_size = "small"
			rad_btn:userCallbackSet("cb_buttonAction", r_action)

			-- initial state
			if frame.header_size == rad_btn.usr_header_size then
				rad_btn:setChecked(true)
			end
			yy = yy + hh
		end

		-- Normal
		do
			local rad_btn = frame:addChild("base/radio_button")
			rad_btn:geometrySetMode("static", xx, yy, ww, hh)

			rad_btn.radio_group = "rg_header_size"
			rad_btn:setLabel("Normal")
			rad_btn.usr_header_size = "normal"
			rad_btn:userCallbackSet("cb_buttonAction", r_action)

			-- initial state
			if frame.header_size == rad_btn.usr_header_size then
				rad_btn:setChecked(true)
			end
			yy = yy + hh
		end

		-- Large
		do
			local rad_btn = frame:addChild("base/radio_button")
			rad_btn:geometrySetMode("static", xx, yy, ww, hh)

			rad_btn.radio_group = "rg_header_size"
			rad_btn:setLabel("Large")
			rad_btn.usr_header_size = "large"
			rad_btn:userCallbackSet("cb_buttonAction", r_action)

			-- initial state
			if frame.header_size == rad_btn.usr_header_size then
				rad_btn:setChecked(true)
			end
			yy = yy + hh
		end
		yy = yy + hh
	end

	-- Checkbox: Enable resizing
	do
		local checkbox = frame:addChild("base/checkbox")
		checkbox:geometrySetMode("static", xx, yy, ww, hh)

		checkbox.checked = frame:getResizable()
		checkbox:setLabel("Resizable frame", "single-ul")

		checkbox:userCallbackSet("cb_buttonAction", function(self)
			local frame = self:getUIFrame()
			if frame then
				frame:setResizable(self.checked)
			end
		end)
		checkbox:reshape()

		yy = yy + hh
	end

	-- Checkbox: Show resize sensors
	do
		local checkbox = frame:addChild("base/checkbox")
		checkbox:geometrySetMode("static", xx, yy, ww, hh)

		checkbox.checked = false
		checkbox:setLabel("S_h_ow resize sensors", "single-ul")

		checkbox:userCallbackSet("cb_buttonAction", function(self)
			local frame = self:getUIFrame()
			if frame then
				frame.DEBUG_show_resize_range = not not self.checked
			end
		end)
		checkbox:reshape()

		yy = yy + hh
	end


	-- Checkbox: Toggle 'Close' button visibility
	do
		local checkbox = frame:addChild("base/checkbox")
		checkbox:geometrySetMode("static", xx, yy, ww, hh)

		checkbox.checked = frame:getCloseControlVisibility()
		checkbox:setLabel("Show 'Close' control", "single-ul")

		checkbox:userCallbackSet("cb_buttonAction", function(self)
			local frame = self:getUIFrame()
			if frame then
				frame:setCloseControlVisibility(self.checked)
			end
		end)
		checkbox:reshape()

		yy = yy + hh
	end


	-- Checkbox: Enable closing the frame
	do
		local checkbox = frame:addChild("base/checkbox")
		checkbox:geometrySetMode("static", xx, yy, ww, hh)

		checkbox.checked = frame:getCloseEnabled()
		checkbox:setLabel("Enable 'Close'", "single-ul")

		checkbox:userCallbackSet("cb_buttonAction", function(self)
			local frame = self:getUIFrame()
			if frame then
				frame:setCloseEnabled(self.checked)
			end
		end)
		checkbox:reshape()

		yy = yy + hh
	end


	-- Checkbox: Toggle 'Maximize' button visibility
	do
		local checkbox = frame:addChild("base/checkbox")
		checkbox:geometrySetMode("static", xx, yy, ww, hh)

		checkbox.checked = frame:getMaximizeControlVisibility()
		checkbox:setLabel("Show 'Maximize' control", "single-ul")

		checkbox:userCallbackSet("cb_buttonAction", function(self)
			local frame = self:getUIFrame()
			if frame then
				frame:setMaximizeControlVisibility(self.checked)
			end
		end)
		checkbox:reshape()

		yy = yy + hh
	end


	-- Checkbox: Allow maximize
	do
		local checkbox = frame:addChild("base/checkbox")
		checkbox:geometrySetMode("static", xx, yy, ww, hh)

		checkbox.checked = frame:getMaximizeEnabled()
		checkbox:setLabel("Enable 'Maximize'", "single-ul")

		checkbox:userCallbackSet("cb_buttonAction", function(self)
			local frame = self:getUIFrame()
			if frame then
				frame:setMaximizeEnabled(self.checked)
			end
		end)
		checkbox:reshape()

		yy = yy + hh
	end


	-- Checkbox: Toggle header visibility
	do
		local checkbox = frame:addChild("base/checkbox")
		checkbox:geometrySetMode("static", xx, yy, ww, hh)

		checkbox.checked = frame:getHeaderVisible()
		checkbox:setLabel("Visible header", "single-ul")

		checkbox:userCallbackSet("cb_buttonAction", function(self)
			local frame = self:getUIFrame()
			if frame then
				frame:setHeaderVisible(self.checked)
			end
		end)
		checkbox:reshape()

		yy = yy + hh
	end


	-- Checkbox: Toggle draggable frame
	do
		local checkbox = frame:addChild("base/checkbox")
		checkbox:geometrySetMode("static", xx, yy, ww, hh)

		checkbox.checked = frame:getDraggable()
		checkbox:setLabel("Draggable header", "single-ul")

		checkbox:userCallbackSet("cb_buttonAction", function(self)
			local frame = self:getUIFrame()
			if frame then
				frame:setDraggable(self.checked)
			end
		end)
		checkbox:reshape()

		yy = yy + hh
	end


	-- Radio Buttons: Control placement
	do
		yy = yy + hh
		local text1 = frame:addChild("wimp/text_block")
		-- XXX work on syncing padding with embedded widget labels
		text1:geometrySetMode("static", xx + 9, yy, ww, hh)

		text1:setText("Control Placement")
		yy = yy + hh

		local r_action = function(self)
			local frame = self:getUIFrame()
			if frame then
				frame:writeSetting("header_button_side", self.usr_button_side)
				frame:reshape()
			end
		end

		-- Left side
		do
			local rad_btn = frame:addChild("base/radio_button")
			rad_btn:geometrySetMode("static", xx, yy, ww, hh)

			rad_btn.radio_group = "rg_control_side"
			rad_btn:setLabel("Left")
			rad_btn.usr_button_side = "left"
			rad_btn:userCallbackSet("cb_buttonAction", r_action)

			-- initial state
			if frame.header_button_side == rad_btn.usr_button_side then
				rad_btn:setChecked(true)
			end
			yy = yy + hh
		end

		-- Right side
		do
			local rad_btn = frame:addChild("base/radio_button")
			rad_btn:geometrySetMode("static", xx, yy, ww, hh)

			rad_btn.radio_group = "rg_control_side"
			rad_btn:setLabel("Right")
			rad_btn.usr_button_side = "right"
			rad_btn:userCallbackSet("cb_buttonAction", r_action)

			-- initial state
			if frame.header_button_side == rad_btn.usr_button_side then
				rad_btn:setChecked(true)
			end
			yy = yy + hh
		end
		yy = yy + hh
	end


	-- Radio Buttons: Header text alignment
	do
		local text1 = frame:addChild("wimp/text_block")
		text1.font = context.resources.fonts.p
		-- XXX work on syncing padding with embedded widget labels
		text1:geometrySetMode("static", xx + 9, yy, ww, hh)

		text1:setText("Header Text Alignment")
		yy = yy + hh

		local r_action = function(self)
			local frame = self:getUIFrame()
			if frame then
				frame.skin.header_text_align_h = self.usr_text_align_h
				frame:reshape()
				print("frame.skin.header_text_align_h", frame.skin.header_text_align_h)
			end
		end

		-- Left
		do
			local rad_btn = frame:addChild("base/radio_button")
			rad_btn:geometrySetMode("static", xx, yy, ww, hh)

			rad_btn.radio_group = "rg_header_text_align_h"
			rad_btn:setLabel("Left")
			rad_btn.usr_text_align_h = 0
			rad_btn:userCallbackSet("cb_buttonAction", r_action)

			-- initial state
			if frame.skin.header_text_align_h == rad_btn.usr_text_align_h then
				rad_btn:setChecked(true)
			end
			yy = yy + hh
		end

		-- Center
		do
			local rad_btn = frame:addChild("base/radio_button")
			rad_btn:geometrySetMode("static", xx, yy, ww, hh)

			rad_btn.radio_group = "rg_header_text_align_h"
			rad_btn:setLabel("Center")
			rad_btn.usr_text_align_h = 0.5
			rad_btn:userCallbackSet("cb_buttonAction", r_action)

			-- initial state
			if frame.skin.header_text_align_h == rad_btn.usr_text_align_h then
				rad_btn:setChecked(true)
			end
			yy = yy + hh
		end

		-- Right
		do
			local rad_btn = frame:addChild("base/radio_button")
			rad_btn:geometrySetMode("static", xx, yy, ww, hh)

			rad_btn.radio_group = "rg_header_text_align_h"
			rad_btn:setLabel("Right")
			rad_btn.usr_text_align_h = 1
			rad_btn:userCallbackSet("cb_buttonAction", r_action)

			-- initial state
			if frame.skin.header_text_align_h == rad_btn.usr_text_align_h then
				rad_btn:setChecked(true)
			end
			yy = yy + hh
		end
		yy = yy + hh
	end

	-- Button: Close
	do
		local btn = frame:addChild("base/button")
		btn:geometrySetMode("static", xx, yy, ww, hh)

		btn:setLabel("Close (forcefully)")
		btn:userCallbackSet("cb_buttonAction", function(self)
			self:getUIFrame():closeFrame(true)
		end)
		yy = yy + hh
	end

	frame:reshape()
	frame:center(true, true)

	return frame
end


return plan
