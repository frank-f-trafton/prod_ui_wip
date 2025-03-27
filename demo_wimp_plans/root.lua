local plan = {}


local demoShared = require("demo_shared")


function plan.make(panel)
	panel:setLayoutBase("viewport-width")
	panel:setScrollRangeMode("auto")
	panel:setScrollBars(false, true)

	demoShared.makeTitle(panel, nil, "Root Widget")

	demoShared.makeParagraph(panel, nil, [[

The root is an invisible container that regulates events and manages other widgets.

Only one root is allowed in the tree, and it must be, well, the *root*, so we cannot spawn an example widget here. However, the text below will display some information about the current root.

TODO
]])
end


return plan
