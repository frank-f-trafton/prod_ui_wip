local plan = {}


function plan.make(panel)
	local context = panel.context

	do
		local text_block = panel:addChild("wimp/text_block")
		text_block:initialize()
		text_block:register("fit-top")
		text_block:setFontID("h1")
		text_block:setText("The Root Widget")
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

The root is an invisible container that regulates events and manages other widgets.

Only one root is allowed in the tree, and it must be, well, the root, so we cannot spawn an example widget here. However, the text below will display some information about the current root.

TODO
]])
	end

	panel.auto_layout = true
	panel:setScrollBars(false, true)
end


return plan
