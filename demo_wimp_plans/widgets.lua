local plan = {
	container_type = "base/container"
}


local demoShared = require("demo_shared")


function plan.make(panel)
	local context = panel.context

	demoShared.makeTitle(panel, nil, "Widgets")

	demoShared.makeParagraph(panel, nil, [[

Widgets are the programmable objects that make up an interface.

Most widgets fall under one of the following broad categories:

* Controls, like buttons and sliders

* Containers (of other widgets)

* Informational or cosmetic elements, like this text

Note that there is not an explicit container type, or one superclass of buttons. All such widgets use the same system of event callbacks to implement their functionality.
]])

	panel:setScrollBars(false, true)
end


return plan
