
local plan = {}


local commonWimp = require("prod_ui.common.common_wimp")
local pTable = require("prod_ui.lib.pile_table")


function plan.make(parent)
	local context = parent.context

	-- Clone the skin to avoid messing up other frames.
	local skin_clone = context.resources:cloneSkinDef("wimp_frame")

	local function _userDestroy(self)
		self.context.resources:removeSkinDef(skin_clone)
	end

	local frame = parent:addChild("wimp/window_frame")
	frame.skin_id = skin_clone
	frame.w = 640
	frame.h = 480
	frame.userDestroy = _userDestroy
	frame:initialize()

	frame:setFrameTitle("WIMP Window Frame")

	local content = frame:findTag("frame_content")
	if content then
		content.layout_mode = "resize"
		content:setScrollBars(false, true)

		local xx, yy, ww, hh = 16, 16, 192, 32

		-- Radio Buttons: Header size
		do
			local text1 = content:addChild("base/text")
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
				local rad_btn = content:addChild("base/radio_button")
				rad_btn.x = xx
				rad_btn.y = yy
				rad_btn.w = ww
				rad_btn.h = hh
				rad_btn:initialize()
				rad_btn.bijou_side = "right"
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
				local rad_btn = content:addChild("base/radio_button")
				rad_btn.x = xx
				rad_btn.y = yy
				rad_btn.w = ww
				rad_btn.h = hh
				rad_btn:initialize()
				rad_btn.bijou_side = "right"
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
				local rad_btn = content:addChild("base/radio_button")
				rad_btn.x = xx
				rad_btn.y = yy
				rad_btn.w = ww
				rad_btn.h = hh
				rad_btn:initialize()
				rad_btn.bijou_side = "right"
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
			local checkbox = content:addChild("base/checkbox")
			checkbox.x = xx
			checkbox.y = yy
			checkbox.w = ww
			checkbox.h = hh
			checkbox:initialize()
			checkbox.checked = frame:getResizable()
			checkbox.bijou_side = "right"
			checkbox:setLabel("Resizable frame", "single-ul")

			checkbox.wid_buttonAction = function(self)
				local frame = commonWimp.getFrame(self)
				print(frame)
				if frame then
					frame:setResizable(self.checked)
				end
				print(
					"self.checked", self.checked, "\n",
					"frame.frame_resizable", frame.frame_resizable, "\n",
					"frame.settings.frame_resizable", frame.settings.frame_resizable, "\n",
					"frame.default_settings.frame_resizable", frame.default_settings.frame_resizable
				)
			end
			checkbox:reshape()

			yy = yy + hh
		end

		-- Checkbox: Show resize sensors
		do
			local checkbox = content:addChild("base/checkbox")
			checkbox.x = xx
			checkbox.y = yy
			checkbox.w = ww
			checkbox.h = hh
			checkbox:initialize()
			checkbox.checked = false
			checkbox.bijou_side = "right"
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
			local checkbox = content:addChild("base/checkbox")
			checkbox.x = xx
			checkbox.y = yy
			checkbox.w = ww
			checkbox.h = hh
			checkbox:initialize()
			checkbox.checked = frame:getCloseControlVisibility()
			checkbox.bijou_side = "right"
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


		-- Checkbox: 'Close' button enabled state
		do
			local checkbox = content:addChild("base/checkbox")
			checkbox.x = xx
			checkbox.y = yy
			checkbox.w = ww
			checkbox.h = hh
			checkbox:initialize()
			checkbox.checked = frame:getCloseEnabled()
			checkbox.bijou_side = "right"
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


		-- Checkbox: Toggle 'Size' button visibility
		do
			local checkbox = content:addChild("base/checkbox")
			checkbox.x = xx
			checkbox.y = yy
			checkbox.w = ww
			checkbox.h = hh
			checkbox:initialize()
			checkbox.checked = frame:getSizeControlVisibility()
			checkbox.bijou_side = "right"
			checkbox:setLabel("Show 'Size' control", "single-ul")

			checkbox.wid_buttonAction = function(self)
				local frame = commonWimp.getFrame(self)
				if frame then
					frame:setSizeControlVisibility(self.checked)
				end
			end
			checkbox:reshape()

			yy = yy + hh
		end


		-- Checkbox: 'Size' button enabled state
		do
			local checkbox = content:addChild("base/checkbox")
			checkbox.x = xx
			checkbox.y = yy
			checkbox.w = ww
			checkbox.h = hh
			checkbox:initialize()
			checkbox.checked = frame:getSizeEnabled()
			checkbox.bijou_side = "right"
			checkbox:setLabel("Enable 'Size'", "single-ul")

			checkbox.wid_buttonAction = function(self)
				local frame = commonWimp.getFrame(self)
				if frame then
					frame:setSizeEnabled(self.checked)
				end
			end
			checkbox:reshape()

			yy = yy + hh
		end


		-- Checkbox: Toggle header visibility
		do
			local checkbox = content:addChild("base/checkbox")
			checkbox.x = xx
			checkbox.y = yy
			checkbox.w = ww
			checkbox.h = hh
			checkbox:initialize()
			checkbox.checked = frame:getHeaderVisible()
			checkbox.bijou_side = "right"
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
			local checkbox = content:addChild("base/checkbox")
			checkbox.x = xx
			checkbox.y = yy
			checkbox.w = ww
			checkbox.h = hh
			checkbox:initialize()
			checkbox.checked = frame:getDraggable()
			checkbox.bijou_side = "right"
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
			local text1 = content:addChild("base/text")
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
					frame:reshape(true)
				end
			end

			-- Left side
			do
				local rad_btn = content:addChild("base/radio_button")
				rad_btn.x = xx
				rad_btn.y = yy
				rad_btn.w = ww
				rad_btn.h = hh
				rad_btn:initialize()
				rad_btn.bijou_side = "right"
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
				local rad_btn = content:addChild("base/radio_button")
				rad_btn.x = xx
				rad_btn.y = yy
				rad_btn.w = ww
				rad_btn.h = hh
				rad_btn:initialize()
				rad_btn.bijou_side = "right"
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
			local text1 = content:addChild("base/text")
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
					skin_clone.header_text_align_h = self.usr_text_align_h
					self.context.resources:refreshSkinDefInstance(skin_clone)
					frame:reshape(true)
					print("skin_clone.header_text_align_h", skin_clone.header_text_align_h)
					print("frame.skin.header_text_align_h", frame.skin.header_text_align_h)
				end
			end

			-- Left
			do
				local rad_btn = content:addChild("base/radio_button")
				rad_btn.x = xx
				rad_btn.y = yy
				rad_btn.w = ww
				rad_btn.h = hh
				rad_btn:initialize()
				rad_btn.bijou_side = "right"
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
				local rad_btn = content:addChild("base/radio_button")
				rad_btn.x = xx
				rad_btn.y = yy
				rad_btn.w = ww
				rad_btn.h = hh
				rad_btn:initialize()
				rad_btn.bijou_side = "right"
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
				local rad_btn = content:addChild("base/radio_button")
				rad_btn.x = xx
				rad_btn.y = yy
				rad_btn.w = ww
				rad_btn.h = hh
				rad_btn:initialize()
				rad_btn.bijou_side = "right"
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
			local btn = content:addChild("base/button")
			btn.x = xx
			btn.y = yy
			btn.w = ww
			btn.h = hh
			btn:initialize()
			btn:setLabel("Close Window")
			btn.wid_buttonAction = function(self)
				self:bubbleEvent("frameCall_close")
			end
			yy = yy + hh
		end
	end

	frame:reshape(true)
	frame:center(true, true)

	return frame
end


return plan
