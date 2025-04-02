local plan = {}


local demoShared = require("demo_shared")


function plan.make(panel)
	panel:setLayoutBase("viewport-width")
	panel:setScrollRangeMode("auto")
	panel:setScrollBars(false, true)

	demoShared.makeTitle(panel, nil, "Unfinished Stuff")

	demoShared.makeParagraph(panel, nil, "These panels are unfinished. Either their purpose is unclear, or they can crash the demo.")
end


return plan
