
-- ProdUI
local demoShared = require("demo_shared")


local plan = {}


function plan.make(panel)
	demoShared.makeTitle(panel, nil, "CardBox")
	demoShared.makeParagraph(panel, nil, "\n***Under Construction***\n")

	panel:layoutSetBase("viewport-width")
	panel:containerSetScrollRangeMode("zero")
	panel:setScrollBars(false, false)

	local card_box = panel:addChild("wimp/card_box")
		:setScrollBars(true, true)
		:geometrySetMode("relative", 16, 16, 256, 256)

	for i = 1, 100 do
		local item = card_box:addItem(tostring(i))
	end
end


return plan
