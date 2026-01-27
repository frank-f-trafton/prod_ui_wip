
-- ProdUI
local demoShared = require("demo_shared")


local plan = {}


function plan.make(panel)
	demoShared.makeTitle(panel, nil, "Spacers & Separators")

	demoShared.makeParagraphSpacer(panel, "p", 0.5)
	demoShared.makeParagraph(panel, nil, "Left, top to bottom: empty spacer; separators (norm, double). Right: separator (thick)")
	demoShared.makeParagraphSpacer(panel, "p", 1.0)

	local context = panel.context

	panel:layoutSetBase("viewport-width")
	panel:containerSetScrollRangeMode("auto")
	panel:setScrollBars(false, true)

	local xx, yy, ww, hh = 0, 0, 192, 48
	local h_sep = 16

	local wid

	wid = panel:addChild("base/button")
		:geometrySetMode("relative", xx, yy, ww, hh)
		:setLabel("Button")

	yy = yy + hh

	wid = panel:addChild("base/empty")
		:geometrySetMode("relative", xx, yy, ww, h_sep)

	yy = yy + h_sep

	wid = panel:addChild("base/button")
		:geometrySetMode("relative", xx, yy, ww, hh)
		:setLabel("Button")

	yy = yy + hh

	wid = panel:addChild("base/separator")
		:geometrySetMode("relative", xx, yy, ww, h_sep)
		:setPipeStyle("norm")
		:setAxis("x")

	yy = yy + h_sep

	wid = panel:addChild("base/button")
		:geometrySetMode("relative", xx, yy, ww, hh)
		:setLabel("Button")

	yy = yy + hh

	wid = panel:addChild("base/separator")
		:geometrySetMode("relative", xx, yy, ww, h_sep)
		:setPipeStyle("double")
		:setAxis("x")

	yy = yy + h_sep

	wid = panel:addChild("base/button")
		:geometrySetMode("relative", xx, yy, ww, hh)
		:setLabel("Button")

	yy = yy + hh
	xx = xx + ww

	wid = panel:addChild("base/separator")
		:geometrySetMode("relative", xx, 0, h_sep, yy)
		:setPipeStyle("thick")
		:setAxis("y")

	xx = xx + h_sep

	wid = panel:addChild("base/button")
		:geometrySetMode("relative", xx, 0, ww, yy)
		:setLabel("Button")
end


return plan
