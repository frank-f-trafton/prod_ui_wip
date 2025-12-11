
-- ProdUI
local demoShared = require("demo_shared")


local plan = {}


function plan.make(panel)
	--title("Dials")

	panel:layoutSetBase("viewport-width")
		:containerSetScrollRangeMode("zero")
		:setScrollBars(false, false)

	local v_wid_w = 32
	local v_wid_h = 128
	local space_w = 64
	local xx = 0

	demoShared.makeLabel(panel, xx, 0, 256, 32, "Dial -- **Under construction**")
	local dial1 = panel:addChild("base/dial")
		:geometrySetMode("static", xx, 32, 64, 64)
		:setDialParameters(0, 0, 100, 0, "none") -- (pos, min, max, home, rnd)
end


return plan
