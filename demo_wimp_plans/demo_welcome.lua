local plan = {}


local demoShared = require("demo_shared")


function plan.make(panel)
	panel:layoutSetBase("viewport-width")
	panel:setScrollRangeMode("auto")
	panel:setScrollBars(false, true)

	demoShared.makeTitle(panel, nil, "Welcome")

	demoShared.makeParagraph(panel, nil, [[
ProdUI is a user interface library for the LÖVE Framework.]])

	demoShared.makeParagraph(panel, nil, "")

	demoShared.makeHyperlink(panel, nil, "* LINK: ProdUI repository on GitHub", "https://www.github.com/frank-f-trafton/prod_ui_wip")

	demoShared.makeHyperlink(panel, nil, "* LINK: ProdUI documentation (work in progress)", "https://github.com/frank-f-trafton/prod_ui_docs")

	demoShared.makeParagraph(panel, nil, "\n\n")

	demoShared.makeParagraph(panel, nil, [[
DEMO DEBUG KEYS:
Ctrl + Shift + 1: Show context info
Ctrl + Shift + 2: Show performance info
Ctrl + Shift + 3: Show a crosshair at the mouse position
Ctrl + Shift + 4: Toggle zoom mode
Ctrl + `: Toggle scale (1.0; 1.5)

When zoom mode is enabled:
	'-': Zoom out
	'=': Zoom in
]])
end


return plan
