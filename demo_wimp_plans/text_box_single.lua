

-- ProdUI
local uiLayout = require("prod_ui.ui_layout")
local widShared = require("prod_ui.common.wid_shared")


local plan = {}


local function makeLabel(panel, x, y, w, h, text, label_mode)
	label_mode = label_mode or "single"

	local label = panel:addChild("base/label")
	label.x, label.y, label.w, label.h = x, y, w, h
	label:initialize()
	label:setLabel(text, label_mode)

	return label
end


function plan.make(panel)
	--title("Input Boxes")
	panel.auto_layout = true
	panel:setScrollBars(false, false)

	-- [=[
	makeLabel(panel, 32, 0, 512, 32, "Single-line text input widget", "single")
	local input_single = panel:addChild("input/text_box_single")
	input_single.x = 32
	input_single.y = 96
	input_single.w = 256
	input_single.h = 32
	input_single:initialize()

	--input_single:setText("Single-Line Text Box")

	--input_single.allow_line_feed = true
	--input_single.allow_enter_line_feed = true

	input_single.wid_action = function(self)
		print("I've been actioned! " .. input_single.line_ed.line)
	end
	--]=]
end


return plan
