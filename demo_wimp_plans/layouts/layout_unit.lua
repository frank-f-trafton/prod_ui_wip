local plan = {}


local pMath = require("prod_ui.lib.pile_math")


local function _makeBox(self, fill, outline, text_color, text)
	local wid = self:addChild("test/colorful_box")
	wid:setColor(fill, outline, text_color)
	wid:setText(text)

	return wid
end


local carousel_colors = {
	"lightred",
	"lightgreen",
	"lightblue",
	"lightcyan",
	"lightmagenta",
	"lightyellow"
}

local carousel_sides = {
	"left",
	"top",
	"right",
	"bottom"
}


function plan.make(panel)
	--title("Layout")

	panel:layoutSetBase("viewport")
	panel:setScrollRangeMode("zero")
	--panel:setSashesEnabled(true)

	local unit = 0.025
	local unit_mult = 0.99
	for i = 1, 128 do
		_makeBox(panel,
			pMath.wrap1Array(carousel_colors, i),
			"black",
			"white"
		):geometrySetMode("segment-unit", pMath.wrap1Array(carousel_sides, i), unit)
		unit = unit * unit_mult
	end

	local w_rem = _makeBox(panel, "darkblue", "lightblue", "white", "!?")
		:geometrySetMode("remaining")

	panel:reshape()
end


return plan
