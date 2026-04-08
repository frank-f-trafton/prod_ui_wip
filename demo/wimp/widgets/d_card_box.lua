local plan = {}


local shared = require("demo.wimp.shared")


function plan.make(panel)
	shared.makeTitle(panel, nil, "CardBox")
	shared.makeParagraph(panel, nil, "\n***Under Construction***\n")

	panel:layoutSetBase("viewport-width")
	panel:containerSetScrollRangeMode("zero")
	panel:setScrollBars(false, false)

	local card_box = panel:addChild("wimp/card_box")
		:setScrollBars(true, true)
		:geometrySetMode("relative", 16, 16, 512, 512)
		:setArrangeMode("lrtb")

	for i = 1, 100 do
		local item = card_box:addItem(tostring(i), nil, "big_file")
	end
end


return plan
