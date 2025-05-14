
local plan = {}


local commonWimp = require("prod_ui.common.common_wimp")
local pTable = require("prod_ui.lib.pile_table")


function plan.makeWindowFrame(root)
	local context = root.context

	local frame = root:newWindowFrame()
	frame.skin_id = frame.skin_id .. "_DEMO"
	frame.w = 640
	frame.h = 480
	frame:initialize()
	frame:setFrameTitle("WIMP Window Frame")

	frame:setLayoutBase("viewport-width")
	frame:setScrollRangeMode("auto")
	frame:setScrollBars(false, true)

	local xx, yy, ww, hh = 16, 16, 192, 32

	-- Radio Buttons: Header size
	do
		local text1 = frame:addChild("base/text")
		text1.x = xx
		text1.y = yy
		text1.w = ww
		text1.h = hh
		text1.font = context.resources.fonts.p
		text1:initialize()
		text1.text = "Header size"
		text1.x = text1.x + 9 -- XXX work on syncing padding with embedded widget labels
		text1:refreshText()
		yy = yy + hh

		local r_action = function(self)
			local frame = commonWimp.getFrame(self)
			if frame then
				frame:setHeaderSize(self.usr_header_size)
			end
		end

		-- Small
		do
			local rad_btn = frame:addChild("base/radio_button")
			rad_btn.x = xx
			rad_btn.y = yy
			rad_btn.w = ww
			rad_btn.h = hh
			rad_btn:initialize()
			rad_btn.radio_group = "rg_header_size"
			rad_btn:setLabel("Small")
			rad_btn.usr_header_size = "small"
			rad_btn.wid_buttonAction = r_action

			-- initial state
			if frame.header_size == rad_btn.usr_header_size then
				rad_btn:setChecked(true)
			end
			yy = yy + hh
		end

		-- Normal
		do
			local rad_btn = frame:addChild("base/radio_button")
			rad_btn.x = xx
			rad_btn.y = yy
			rad_btn.w = ww
			rad_btn.h = hh
			rad_btn:initialize()
			rad_btn.radio_group = "rg_header_size"
			rad_btn:setLabel("Normal")
			rad_btn.usr_header_size = "normal"
			rad_btn.wid_buttonAction = r_action

			-- initial state
			if frame.header_size == rad_btn.usr_header_size then
				rad_btn:setChecked(true)
			end
			yy = yy + hh
		end

		-- Large
		do
			local rad_btn = frame:addChild("base/radio_button")
			rad_btn.x = xx
			rad_btn.y = yy
			rad_btn.w = ww
			rad_btn.h = hh
			rad_btn:initialize()
			rad_btn.radio_group = "rg_header_size"
			rad_btn:setLabel("Large")
			rad_btn.usr_header_size = "large"
			rad_btn.wid_buttonAction = r_action

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
		checkbox.x = xx
		checkbox.y = yy
		checkbox.w = ww
		checkbox.h = hh
		checkbox:initialize()
		checkbox.checked = frame:getResizable()
		checkbox:setLabel("Resizable frame", "single-ul")

		checkbox.wid_buttonAction = function(self)
			local frame = commonWimp.getFrame(self)
			if frame then
				frame:setResizable(self.checked)
			end
		end
		checkbox:reshape()

		yy = yy + hh
	end

	-- Checkbox: Show resize sensors
	do
		local checkbox = frame:addChild("base/checkbox")
		checkbox.x = xx
		checkbox.y = yy
		checkbox.w = ww
		checkbox.h = hh
		checkbox:initialize()
		checkbox.checked = false
		checkbox:setLabel("S_h_ow resize sensors", "single-ul")

		checkbox.wid_buttonAction = function(self)
			local frame = commonWimp.getFrame(self)
			if frame then
				frame.DEBUG_show_resize_range = not not self.checked
			end
		end
		checkbox:reshape()

		yy = yy + hh
	end


	-- Checkbox: Toggle 'Close' button visibility
	do
		local checkbox = frame:addChild("base/checkbox")
		checkbox.x = xx
		checkbox.y = yy
		checkbox.w = ww
		checkbox.h = hh
		checkbox:initialize()
		checkbox.checked = frame:getCloseControlVisibility()
		checkbox:setLabel("Show 'Close' control", "single-ul")

		checkbox.wid_buttonAction = function(self)
			local frame = commonWimp.getFrame(self)
			if frame then
				frame:setCloseControlVisibility(self.checked)
			end
		end
		checkbox:reshape()

		yy = yy + hh
	end


	-- Checkbox: Enable closing the frame
	do
		local checkbox = frame:addChild("base/checkbox")
		checkbox.x = xx
		checkbox.y = yy
		checkbox.w = ww
		checkbox.h = hh
		checkbox:initialize()
		checkbox.checked = frame:getCloseEnabled()
		checkbox:setLabel("Enable 'Close'", "single-ul")

		checkbox.wid_buttonAction = function(self)
			local frame = commonWimp.getFrame(self)
			if frame then
				frame:setCloseEnabled(self.checked)
			end
		end
		checkbox:reshape()

		yy = yy + hh
	end


	-- Checkbox: Toggle 'Maximize' button visibility
	do
		local checkbox = frame:addChild("base/checkbox")
		checkbox.x = xx
		checkbox.y = yy
		checkbox.w = ww
		checkbox.h = hh
		checkbox:initialize()
		checkbox.checked = frame:getMaximizeControlVisibility()
		checkbox:setLabel("Show 'Maximize' control", "single-ul")

		checkbox.wid_buttonAction = function(self)
			local frame = commonWimp.getFrame(self)
			if frame then
				frame:setMaximizeControlVisibility(self.checked)
			end
		end
		checkbox:reshape()

		yy = yy + hh
	end


	-- Checkbox: Allow maximize
	do
		local checkbox = frame:addChild("base/checkbox")
		checkbox.x = xx
		checkbox.y = yy
		checkbox.w = ww
		checkbox.h = hh
		checkbox:initialize()
		checkbox.checked = frame:getMaximizeEnabled()
		checkbox:setLabel("Enable 'Maximize'", "single-ul")

		checkbox.wid_buttonAction = function(self)
			local frame = commonWimp.getFrame(self)
			if frame then
				frame:setMaximizeEnabled(self.checked)
			end
		end
		checkbox:reshape()

		yy = yy + hh
	end


	-- Checkbox: Toggle header visibility
	do
		local checkbox = frame:addChild("base/checkbox")
		checkbox.x = xx
		checkbox.y = yy
		checkbox.w = ww
		checkbox.h = hh
		checkbox:initialize()
		checkbox.checked = frame:getHeaderVisible()
		checkbox:setLabel("Visible header", "single-ul")

		checkbox.wid_buttonAction = function(self)
			local frame = commonWimp.getFrame(self)
			if frame then
				frame:setHeaderVisible(self.checked)
			end
		end
		checkbox:reshape()

		yy = yy + hh
	end


	-- Checkbox: Toggle draggable frame
	do
		local checkbox = frame:addChild("base/checkbox")
		checkbox.x = xx
		checkbox.y = yy
		checkbox.w = ww
		checkbox.h = hh
		checkbox:initialize()
		checkbox.checked = frame:getDraggable()
		checkbox:setLabel("Draggable header", "single-ul")

		checkbox.wid_buttonAction = function(self)
			local frame = commonWimp.getFrame(self)
			if frame then
				frame:setDraggable(self.checked)
			end
		end
		checkbox:reshape()

		yy = yy + hh
	end


	-- Radio Buttons: Control placement
	do
		yy = yy + hh
		local text1 = frame:addChild("base/text")
		text1.x = xx
		text1.y = yy
		text1.w = ww
		text1.h = hh
		text1.font = context.resources.fonts.p
		text1:initialize()
		text1.text = "Control Placement"
		text1.x = text1.x + 9 -- XXX work on syncing padding with embedded widget labels
		text1:refreshText()
		yy = yy + hh

		local r_action = function(self)
			local frame = commonWimp.getFrame(self)
			if frame then
				frame:writeSetting("header_button_side", self.usr_button_side)
				frame:reshape()
			end
		end

		-- Left side
		do
			local rad_btn = frame:addChild("base/radio_button")
			rad_btn.x = xx
			rad_btn.y = yy
			rad_btn.w = ww
			rad_btn.h = hh
			rad_btn:initialize()
			rad_btn.radio_group = "rg_control_side"
			rad_btn:setLabel("Left")
			rad_btn.usr_button_side = "left"
			rad_btn.wid_buttonAction = r_action

			-- initial state
			if frame.header_button_side == rad_btn.usr_button_side then
				rad_btn:setChecked(true)
			end
			yy = yy + hh
		end

		-- Right side
		do
			local rad_btn = frame:addChild("base/radio_button")
			rad_btn.x = xx
			rad_btn.y = yy
			rad_btn.w = ww
			rad_btn.h = hh
			rad_btn:initialize()
			rad_btn.radio_group = "rg_control_side"
			rad_btn:setLabel("Right")
			rad_btn.usr_button_side = "right"
			rad_btn.wid_buttonAction = r_action

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
		local text1 = frame:addChild("base/text")
		text1.x = xx
		text1.y = yy
		text1.w = ww
		text1.h = hh
		text1.font = context.resources.fonts.p
		text1:initialize()
		text1.text = "Header Text Alignment"
		text1.x = text1.x + 9 -- XXX work on syncing padding with embedded widget labels
		text1:refreshText()
		yy = yy + hh

		local r_action = function(self)
			local frame = commonWimp.getFrame(self)
			if frame then
				frame.skin.header_text_align_h = self.usr_text_align_h
				frame:reshape()
				print("frame.skin.header_text_align_h", frame.skin.header_text_align_h)
			end
		end

		-- Left
		do
			local rad_btn = frame:addChild("base/radio_button")
			rad_btn.x = xx
			rad_btn.y = yy
			rad_btn.w = ww
			rad_btn.h = hh
			rad_btn:initialize()
			rad_btn.radio_group = "rg_header_text_align_h"
			rad_btn:setLabel("Left")
			rad_btn.usr_text_align_h = 0
			rad_btn.wid_buttonAction = r_action

			-- initial state
			if frame.skin.header_text_align_h == rad_btn.usr_text_align_h then
				rad_btn:setChecked(true)
			end
			yy = yy + hh
		end

		-- Center
		do
			local rad_btn = frame:addChild("base/radio_button")
			rad_btn.x = xx
			rad_btn.y = yy
			rad_btn.w = ww
			rad_btn.h = hh
			rad_btn:initialize()
			rad_btn.radio_group = "rg_header_text_align_h"
			rad_btn:setLabel("Center")
			rad_btn.usr_text_align_h = 0.5
			rad_btn.wid_buttonAction = r_action

			-- initial state
			if frame.skin.header_text_align_h == rad_btn.usr_text_align_h then
				rad_btn:setChecked(true)
			end
			yy = yy + hh
		end

		-- Right
		do
			local rad_btn = frame:addChild("base/radio_button")
			rad_btn.x = xx
			rad_btn.y = yy
			rad_btn.w = ww
			rad_btn.h = hh
			rad_btn:initialize()
			rad_btn.radio_group = "rg_header_text_align_h"
			rad_btn:setLabel("Right")
			rad_btn.usr_text_align_h = 1
			rad_btn.wid_buttonAction = r_action

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
		btn.x = xx
		btn.y = yy
		btn.w = ww
		btn.h = hh
		btn:initialize()
		btn:setLabel("Close (forcefully)")
		btn.wid_buttonAction = function(self)
			self:bubbleEvent("frameCall_close", true)
		end
		yy = yy + hh
	end

	frame:reshape()
	frame:center(true, true)

	return frame
end


return plan
