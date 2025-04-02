
-- ProdUI
local demoShared = require("demo_shared")


local plan = {}


function plan.make(panel)
	--title("Dials")

	panel:setLayoutBase("viewport-width")
	panel:setScrollRangeMode("zero")
	panel:setScrollBars(false, false)

	local v_wid_w = 32
	local v_wid_h = 128
	local space_w = 64
	local xx = 0

	demoShared.makeLabel(panel, xx, 0, 256, 32, "Dial -- **Under construction**")
	local dial1 = panel:addChild("base/dial")
	dial1.x = xx
	dial1.y = 32
	dial1.w = 64
	dial1.h = 64
	dial1:initialize()

	--:setDialParameters(pos, min, max, home, rnd)
	dial1:setDialParameters(0, 0, 100, 0, "none")
end


return plan
