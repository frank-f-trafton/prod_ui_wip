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

	demoShared.makeParagraph(panel, nil, "* == Default length override")
	demoShared.makeParagraphSpacer(panel, "p", 0.5)

	local c1 = panel:addChild("base/container_simple")
		:geometrySetMode("relative", 0, 0, 384, 384)
		:layoutSetMargin(4, 4, 4, 4)
		:layoutSetStackFlow("y", 1)
		:layoutSetStackDefaultWidgetSize("pixel", 32)

	for i = 1, 15 do
		local label, mode, len
		if i % 3 == 0 then
			label = tostring(i) .. "*"
			mode, len = "pixel", 20
		else
			label = tostring(i)
			mode, len = false, false
		end

		local c1_box = _makeBox(c1, uiTable.wrap1Array(_color_sequence, i), "darkgrey", "black", label)
		c1_box:geometrySetMode("stack", mode, len)
	end
end


return plan
