
-- ProdUI
local demoShared = require("demo_shared")


local plan = {}


function plan.make(panel)
	panel:setLayoutBase("viewport-width")
	panel:setScrollRangeMode("zero")
	panel:setScrollBars(false, false)

	-- [=[
	demoShared.makeLabel(panel, 32, 0, 512, 32, "Single-line text input widget", "single")
	local input_single = panel:addChild("input/text_box_single")
	demoShared.setStaticLayout(panel, input_single, 32, 96, 256, 32)

	--input_single:setText("Single-Line Text Box")

	--input_single.LE_allow_line_feed = true
	--input_single.LE_allow_enter_line_feed = true

	input_single.wid_action = function(self)
		print("input_single: Pressed 'enter': " .. input_single.LE.line)
	end
	--]=]
end


return plan
