local plan = {}


local demoShared = require("demo_shared")
local uiTable = require("prod_ui.ui_table")


local function _makeBox(self, fill, outline, text_color, text)
	local wid = self:addChild("test/colorful_box")
	wid:setColor(fill, outline, text_color)
	wid:setText(text)

	return wid
end


local _color_sequence = {
	"lightred",
	"lightgreen",
	"lightblue",
	"lightcyan",
	"lightmagenta",
	"lightyellow",
}


function plan.make(panel)
	--title("")

	panel:layoutSetBase("viewport")
	panel:containerSetScrollRangeMode("zero")
	panel:setSashesEnabled(true)

	local c1 = panel:addChild("base/container_simple")
		:geometrySetMode("static", 0, 0, 256, 256)
		:layoutSetMargin(4, 4, 4, 4)
		:layoutSetWalletCardSize("pixel", "pixel", 50, 60)
		:layoutSetWalletCardsPerLine(4)
		:layoutSetWalletFlow("x", 1, 1)

	for i = 1, 15 do
		local c1_box = _makeBox(c1, uiTable.wrap1Array(_color_sequence, i), "darkgrey", "black", tostring(i))
		c1_box:geometrySetMode("wallet")
	end
end


return plan
