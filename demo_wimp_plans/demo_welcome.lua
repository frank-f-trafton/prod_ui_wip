local plan = {
	container_type = "base/container"
}


local demoShared = require("demo_shared")


function plan.make(panel)
	local context = panel.context
-- [====[
	demoShared.makeTitle(panel, nil, "Welcome")

	demoShared.makeParagraph(panel, nil, [[
ProdUI is a user interface library for the LÖVE Framework. It is currently in development, and not yet ready for real games and applications.

Once complete, this demo will provide examples of all built-in widgets and most features of the library.]])

	demoShared.makeHyperlink(panel, nil, "* LINK: ProdUI repository on GitHub", "https://www.github.com/rabbitboots/prod_ui_wip")

	demoShared.makeHyperlink(panel, nil, "* LINK: ProdUI documentation (work in progress)", "https://github.com/rabbitboots/prod_ui_docs")

	demoShared.makeParagraph(panel, nil, "\n\n")

	demoShared.makeParagraph(panel, nil, [[
DEMO DEBUG KEYS:
Ctrl + Shift + 1: Show context info
Ctrl + Shift + 2: Show performance info
Ctrl + Shift + 3: Show a crosshair at the mouse position
Ctrl + Shift + 4: Toggle zoom mode

When zoom mode is enabled:
	'-': Zoom out
	'=': Zoom in
]])
	--]====]
	panel:setScrollBars(false, true)
end


return plan
