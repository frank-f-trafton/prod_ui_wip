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
	In both containers, the edges have been shortened by four segments.

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

	Note that non-relative mode doesn't ignore the parent's margins, because those are applied
	before 'widLayout.applyLayout()' calculates the "original" layout space.
	--]]

	local c1 = panel:addChild("base/container_simple")
		:geometrySetMode("static", 0, 0, 256, 256, false, false, false)
		:layoutSetMargin(16, 16, 16, 16)

	-- cut off some of the edges
	_makeBox(c1, "black", "black", "black")
		:geometrySetMode("segment", "left", 16)

	_makeBox(c1, "black", "black", "black")
		:geometrySetMode("segment", "top", 16)

	_makeBox(c1, "black", "black", "black")
		:geometrySetMode("segment", "right", 16)

	_makeBox(c1, "black", "black", "black")
		:geometrySetMode("segment", "bottom", 16)

	local c1_box = _makeBox(c1, "lightyellow", "darkyellow", "black", "Not Relative")

	local wa = _makeBox(c1, "lightgreen", "green", "black", "(A)")
		:geometrySetMode("static", 0, 0, 48, 48, false, false, false)

	local wb = _makeBox(c1, "lightblue", "blue", "white", "(B)")
		:geometrySetMode("static", 0, 0, 48, 48, false, true, false)

	local wc = _makeBox(c1, "lightgrey", "darkgrey", "black", "(C)")
		:geometrySetMode("static", 0, 0, 48, 48, false, false, true)

	local wd = _makeBox(c1, "lightmagenta", "magenta", "black", "(D)")
		:geometrySetMode("static", 0, 0, 48, 48, false, true, true)

	c1_box:geometrySetMode("remaining")


	local c2 = panel:addChild("base/container_simple")
		:geometrySetMode("static", 0+256+32, 0, 256, 256, false, false, false)
		:layoutSetMargin(16, 16, 16, 16)

	-- cut off some of the edges
	_makeBox(c2, "black", "black", "black")
		:geometrySetMode("segment", "left", 16)

	_makeBox(c2, "black", "black", "black")
		:geometrySetMode("segment", "top", 16)

	_makeBox(c2, "black", "black", "black")
		:geometrySetMode("segment", "right", 16)

	_makeBox(c2, "black", "black", "black")
		:geometrySetMode("segment", "bottom", 16)

	local c2_box = _makeBox(c2, "darkgrey", "lightgrey", "white", "Relative")

	local we = _makeBox(c2, "lightgreen", "green", "black", "(E)")
		:geometrySetMode("static", 0, 0, 48, 48, true, false, false)

	local wf = _makeBox(c2, "lightblue", "blue", "white", "(F)")
		:geometrySetMode("static", 0, 0, 48, 48, true, true, false)

	local wg = _makeBox(c2, "lightgrey", "darkgrey", "black", "(G)")
		:geometrySetMode("static", 0, 0, 48, 48, true, false, true)

	local wh = _makeBox(c2, "lightmagenta", "magenta", "black", "(H)")
		:geometrySetMode("static", 0, 0, 48, 48, true, true, true)

	c2_box:geometrySetMode("remaining")

	panel:reshape()
end


return plan
