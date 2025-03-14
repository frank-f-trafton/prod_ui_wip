local plan = {}


local demoShared = require("demo_shared")


function plan.make(panel)
	local context = panel.context

	demoShared.makeTitle(panel, nil, "Welcome")

	demoShared.makeParagraph(panel, nil, [[
ProdUI is a user interface library for the LÖVE Framework. It is currently in development, and not yet ready for real games and applications.

Once complete, this demo will provide examples of all built-in widgets and most features of the library.]])

	demoShared.makeHyperlink(panel, nil, "* LINK: ProdUI repository on GitHub", "https://www.github.com/rabbitboots/prod_ui_wip")

	demoShared.makeHyperlink(panel, nil, "* LINK: ProdUI documentation (work in progress)", "https://github.com/rabbitboots/prod_ui_wip/tree/main/mkdocs/docs")

	panel.auto_layout = true
	panel:setScrollBars(false, true)
end


return plan
