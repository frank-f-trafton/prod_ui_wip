
-- ProdUI
local demoShared = require("demo_shared")


local plan = {}


function plan.make(panel)
	demoShared.makeTitle(panel, nil, "Groups of Controls")
	demoShared.makeParagraph(panel, nil, "\n***Under Construction***\n")

	local context = panel.context

	panel:layoutSetBase("viewport-width")
	panel:containerSetScrollRangeMode("auto")
	panel:setScrollBars(false, true)

	local group = panel:addChild("base/group")
		:geometrySetMode("relative", 0, 0, 256, 256)
		:setText("Group")


	local xx, yy, ww, hh = 0, 0, 192, 40

	local rdo

	rdo = group:addChild("base/radio_button")
		:geometrySetMode("static", xx, yy, ww, hh)
		:setRadioGroup("a")
		:setLabel("Radio Button")
		--:userCallbackSet("cb_buttonAction", nil)

	yy = yy + hh
end


return plan
