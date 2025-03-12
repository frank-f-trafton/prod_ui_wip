local plan = {}


function plan.make(panel)
	local context = panel.context

	do
		local text_block = panel:addChild("wimp/text_block")
		text_block:initialize()
		text_block:register("fit-top")
		text_block:setFontID("h1")
		text_block:setText("Widgets")
		text_block:setAutoSize("v")
	end
	do
		local text_block = panel:addChild("wimp/text_block")
		text_block:initialize()
		text_block:register("fit-top")
		text_block:setFontID("p")
		text_block:setAutoSize("v")
		text_block:setWrapping(true)
		text_block:setText([[

Widgets are the programmable objects that make up an interface.

Most widgets fall under one of the following broad categories:

* Controls, like buttons and sliders

* Containers (of other widgets)

* Informational or cosmetic elements, like this text

Note that there is not an explicit container type, or one superclass of buttons. All such widgets use the same system of event callbacks to implement their functionality.
]])
	end

	panel.auto_layout = true
	panel:setScrollBars(false, true)
end


return plan
