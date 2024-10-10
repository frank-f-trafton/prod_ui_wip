
-- ProdUI
local commonMenu = require("prod_ui.logic.common_menu")
local uiLayout = require("prod_ui.ui_layout")
local widShared = require("prod_ui.logic.wid_shared")


local plan = {}


function plan.make(parent)
	local context = parent.context

	local frame = parent:addChild("wimp/window_frame")

	frame.w = 640
	frame.h = 480

	frame:setFrameTitle("Barebones widgets")

	local content = frame:findTag("frame_content")
	if content then
		content.layout_mode = "resize"

		content:setScrollBars(false, true)

		local xx, yy = 0, 0
		local ww, hh = 224, 64

		local bb_button = content:addChild("barebones/button", {x = xx, y = yy, w = ww, h = hh})

		bb_button:setLabel("<Button>")

		bb_button.wid_buttonAction = function(self)
			self:setLabel(">Button<")
		end

		yy = yy + hh

		local bb_rep = content:addChild("barebones/button_repeat", {x = xx, y = yy, w = ww, h = hh})

		bb_rep:setLabel("<Repeat #0>")
		bb_rep.usr_count = 0

		bb_rep.wid_buttonAction = function(self)
			self.usr_count = self.usr_count + 1
			self:setLabel(">Repeat #" .. tostring(self.usr_count) .. "<")
		end

		yy = yy + hh

		local bb_instant = content:addChild("barebones/button_instant", {x = xx, y = yy, w = ww, h = hh})

		bb_instant:setLabel("Instant-Action Button")
		bb_instant.usr_n = 0

		bb_instant.wid_buttonAction = function(self)
			self.usr_n = self.usr_n + 1
			self:setLabel("Activated! #" .. self.usr_n)
		end

		yy = yy + hh

		local bb_stick = content:addChild("barebones/button_sticky", {x = xx, y = yy, w = ww, h = hh})

		bb_stick:setLabel("Sticky Button")

		bb_stick.wid_buttonAction = function(self)
			self:setLabel("Stuck!")
		end

		yy = yy + hh

		local bb_checkbox = content:addChild("barebones/checkbox", {x = xx, y = yy, w = ww, h = hh})

		bb_checkbox:setLabel("Checkbox")

		yy = yy + hh

		local bb_radio
		bb_radio = content:addChild("barebones/radio_button", {x = xx, y = yy, w = ww, h = hh})

		bb_radio.radio_group = "bare1"
		bb_radio:setLabel("Radio1")

		yy = yy + hh

		bb_radio = content:addChild("barebones/radio_button", {x = xx, y = yy, w = ww, h = hh})

		bb_radio.radio_group = "bare1"
		bb_radio:setLabel("Radio2")

		yy = yy + hh

		local bb_lbl
		bb_lbl = content:addChild("barebones/label", {x = xx, y = yy, w = ww, h = hh})

		bb_lbl.enabled = true
		bb_lbl:setLabel("Label (enabled)")

		yy = yy + hh

		bb_lbl = content:addChild("barebones/label", {x = xx, y = yy, w = ww, h = hh})

		bb_lbl.enabled = false
		bb_lbl:setLabel("Label (disabled)")

		yy = yy + hh

		local bb_sl1 = content:addChild("barebones/slider_bar", {x = xx, y = yy, w = ww, h = hh})

		bb_sl1.trough_vertical = false
		bb_sl1:setLabel("Barebones Slider Bar")

		bb_sl1.slider_pos = 0
		bb_sl1.slider_def = 0
		bb_sl1.slider_max = 64

		--yy = yy + hh

		local bb_sl2 = content:addChild("barebones/slider_bar", {x = xx + ww, y = yy, w = hh, h = ww})

		bb_sl2.trough_vertical = true
		bb_sl2:setLabel("Vertical")

		bb_sl2.slider_pos = 0
		bb_sl2.slider_def = 0
		bb_sl2.slider_max = 64

		yy = yy + ww

		local bb_input = content:addChild("barebones/input_box", {x = xx, y = yy, w = ww, h = 32})

		bb_input:setText("Barebones Input Box")
		--bb_input:setMaxCodePoints(4)
	end

	frame:reshape(true)
	frame:center(true, true)

	return frame
end


return plan
