
-- ProdUI
local demoShared = require("demo_shared")


local plan = {}


function plan.make(panel)
	--title("Number Box")

	panel:setLayoutBase("viewport-width")
	panel:setScrollRangeMode("zero")
	panel:setScrollBars(false, false)

	local num_box = panel:addChild("wimp/number_box")

	num_box.wid_action = function(self)
		-- WIP
	end

	demoShared.setStaticLayout(panel, num_box, 32, 96, 256, 32)
end


return plan
