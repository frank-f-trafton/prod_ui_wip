-- ProdUI
local commonWimp = require("prod_ui.common.common_wimp")
local uiLayout = require("prod_ui.ui_layout")


local plan = {}


function plan.make(panel)
	local context = panel.context

	do
		local text_block = panel:addChild("wimp/text_block")
		text_block:initialize()
		text_block:register("fit-top")
		text_block:setFontID("h1")
		text_block:setText("Welcome")
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

ProdUI is a user interface library for the LÖVE Framework. It is currently in development, and not yet ready for real games and applications.

Once complete, this demo will provide examples of all built-in widgets and most features of the library.]])
	end

	panel.auto_layout = true
	panel:setScrollBars(false, true)
end


return plan
