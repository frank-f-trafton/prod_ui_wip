
-- ProdUI
local uiLayout = require("prod_ui.ui_layout")
local widShared = require("prod_ui.common.wid_shared")


local plan = {}


function plan.make(panel)
	--title("Barebones widgets")

	panel.auto_layout = true
	panel:setScrollBars(false, true)

	local xx, yy = 0, 0
	local ww, hh = 224, 64

	local bb_button = panel:addChild("barebones/button")
	bb_button.x = xx
	bb_button.y = yy
	bb_button.w = ww
	bb_button.h = hh
	bb_button:initialize()

	bb_button:setLabel("<Button>")

	bb_button.wid_buttonAction = function(self)
		self:setLabel(">Button<")
	end

	yy = yy + hh

	local bb_rep = panel:addChild("barebones/button_repeat")
	bb_rep.x = xx
	bb_rep.y = yy
	bb_rep.w = ww
	bb_rep.h = hh
	bb_rep:initialize()

	bb_rep:setLabel("<Repeat #0>")
	bb_rep.usr_count = 0

	bb_rep.wid_buttonAction = function(self)
		self.usr_count = self.usr_count + 1
		self:setLabel(">Repeat #" .. tostring(self.usr_count) .. "<")
	end

	yy = yy + hh

	local bb_instant = panel:addChild("barebones/button_instant")
	bb_instant.x = xx
	bb_instant.y = yy
	bb_instant.w = ww
	bb_instant.h = hh
	bb_instant:initialize()

	bb_instant:setLabel("Instant-Action Button")
	bb_instant.usr_n = 0

	bb_instant.wid_buttonAction = function(self)
		self.usr_n = self.usr_n + 1
		self:setLabel("Activated! #" .. self.usr_n)
	end

	yy = yy + hh

	local bb_stick = panel:addChild("barebones/button_sticky")
	bb_stick.x = xx
	bb_stick.y = yy
	bb_stick.w = ww
	bb_stick.h = hh
	bb_stick:initialize()

	bb_stick:setLabel("Sticky Button")

	bb_stick.wid_buttonAction = function(self)
		self:setLabel("Stuck!")
	end

	yy = yy + hh

	local bb_checkbox = panel:addChild("barebones/checkbox")
	bb_checkbox.x = xx
	bb_checkbox.y = yy
	bb_checkbox.w = ww
	bb_checkbox.h = hh
	bb_checkbox:initialize()

	bb_checkbox:setLabel("Checkbox")

	yy = yy + hh

	local bb_radio
	bb_radio = panel:addChild("barebones/radio_button")
	bb_radio.x = xx
	bb_radio.y = yy
	bb_radio.w = ww
	bb_radio.h = hh
	bb_radio:initialize()

	bb_radio.radio_group = "bare1"
	bb_radio:setLabel("Radio1")

	yy = yy + hh

	bb_radio = panel:addChild("barebones/radio_button")
	bb_radio.x = xx
	bb_radio.y = yy
	bb_radio.w = ww
	bb_radio.h = hh
	bb_radio:initialize()

	bb_radio.radio_group = "bare1"
	bb_radio:setLabel("Radio2")

	yy = yy + hh

	local bb_lbl
	bb_lbl = panel:addChild("barebones/label")
	bb_lbl.x = xx
	bb_lbl.y = yy
	bb_lbl.w = ww
	bb_lbl.h = hh
	bb_lbl:initialize()

	bb_lbl.enabled = true
	bb_lbl:setLabel("Label (enabled)")

	yy = yy + hh

	bb_lbl = panel:addChild("barebones/label")
	bb_lbl.x = xx
	bb_lbl.y = yy
	bb_lbl.w = ww
	bb_lbl.h = hh
	bb_lbl:initialize()

	bb_lbl.enabled = false
	bb_lbl:setLabel("Label (disabled)")

	yy = yy + hh

	local bb_sl1 = panel:addChild("barebones/slider_bar")
	bb_sl1.x = xx
	bb_sl1.y = yy
	bb_sl1.w = ww
	bb_sl1.h = hh
	bb_sl1:initialize()

	bb_sl1.trough_vertical = false
	bb_sl1:setLabel("Barebones Slider Bar")

	bb_sl1.slider_pos = 0
	bb_sl1.slider_def = 0
	bb_sl1.slider_max = 64

	yy = yy + hh

	local bb_sl2 = panel:addChild("barebones/slider_bar")
	bb_sl2.x = xx
	bb_sl2.y = yy
	bb_sl2.w = ww
	bb_sl2.h = hh
	bb_sl2:initialize()

	bb_sl2.trough_vertical = true
	bb_sl2:setLabel("Vertical")

	bb_sl2.slider_pos = 0
	bb_sl2.slider_def = 0
	bb_sl2.slider_max = 64

	yy = yy + ww

	local bb_input = panel:addChild("barebones/input_box")
	bb_input.x = xx
	bb_input.y = yy
	bb_input.w = ww
	bb_input.h = 32
	bb_input:initialize()

	bb_input:setText("Barebones Input Box")
	--bb_input:setMaxCodePoints(4)
end


return plan
