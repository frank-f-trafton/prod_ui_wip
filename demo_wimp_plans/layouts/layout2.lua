local plan = {}


local function _makeBox(self, fill, outline, text_color, text)
	local wid = self:addChild("test/colorful_box")
	wid:setColor(fill, outline, text_color)
	wid:setText(text)

	return wid
end


function plan.make(panel)
	--title("")

	panel:layoutSetBase("viewport")
	panel:setScrollRangeMode("zero")
	panel:setSashesEnabled(true)

	--[[
	   C1      C2
	┌──────┐┌──────┐
	│A┈┈┈┈B││╭┈┈┈┈╮│
	│┆    ┆││┆E  F┆│
	│┆    ┆││┆G  H┆│
	│C┈┈┈┈D││╰┈┈┈┈╯│
	└──────┘└──────┘

	All nodes are in static position mode.

	C1: not relative; C2: relative

	Flipping:
	       ┌───┬───┐
	       | X | Y |
	┌──────┼───┼───┤
	| A, E |   |   |
	| B, F | * |   |
	| C, G |   | * |
	| D, H | * | * |
	└──────┴───┴───┘
	--]]

	local c1 = panel:addChild("base/container_simple")
		:layoutSetMode("static", 0, 0, 256, 256, false, false, false)
		:layoutSetMargin(16, 16, 16, 16)
		:layoutAdd()

	local c1_box = _makeBox(c1, "lightyellow", "darkyellow", "black", "Not Relative")

	local wa = _makeBox(c1, "lightgreen", "green", "black", "(A)")
		:layoutSetMode("static", 0, 0, 48, 48, false, false, false)
		:layoutAdd()

	local wb = _makeBox(c1, "lightblue", "blue", "white", "(B)")
		:layoutSetMode("static", 0, 0, 48, 48, false, true, false)
		:layoutAdd()

	local wc = _makeBox(c1, "lightgrey", "darkgrey", "black", "(C)")
		:layoutSetMode("static", 0, 0, 48, 48, false, false, true)
		:layoutAdd()

	local wd = _makeBox(c1, "lightmagenta", "magenta", "black", "(D)")
		:layoutSetMode("static", 0, 0, 48, 48, false, true, true)
		:layoutAdd()

	c1_box:layoutSetMode("remaining")
		:layoutAdd()


	local c2 = panel:addChild("base/container_simple")
		:layoutSetMode("static", 0+256+32, 0, 256, 256, false, false, false)
		:layoutSetMargin(16, 16, 16, 16)
		:layoutAdd()

	local c2_box = _makeBox(c2, "darkgrey", "lightgrey", "white", "Relative")

	local we = _makeBox(c2, "lightgreen", "green", "black", "(E)")
		:layoutSetMode("static", 0, 0, 48, 48, true, false, false)
		:layoutAdd()

	local wf = _makeBox(c2, "lightblue", "blue", "white", "(F)")
		:layoutSetMode("static", 0, 0, 48, 48, true, true, false)
		:layoutAdd()

	local wg = _makeBox(c2, "lightgrey", "darkgrey", "black", "(G)")
		:layoutSetMode("static", 0, 0, 48, 48, true, false, true)
		:layoutAdd()

	local wh = _makeBox(c2, "lightmagenta", "magenta", "black", "(H)")
		:layoutSetMode("static", 0, 0, 48, 48, true, true, true)
		:layoutAdd()

	c2_box:layoutSetMode("remaining")
		:layoutAdd()

	panel:reshape()
end


return plan
