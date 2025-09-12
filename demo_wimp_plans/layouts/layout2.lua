local plan = {}


local function _makeBox(self, fill, outline, text_color, text)
	local wid = self:addChild("test/colorful_box")
	wid:setColor(fill, outline, text_color)
	wid:setText(text)

	return wid
end


function plan.make(panel)
	--title("")

	panel:setLayoutBase("viewport")
	panel:setScrollRangeMode("zero")
	panel:setSashesEnabled(true)

	--[[
	   C1      C2
	┌┈┈┈┈┈┈┐┌┈┈┈┈┈┈┐
	│A┈┈┈┈B││┌┈┈┈┈┐│
	││    ││││E  F││
	││    ││││G  H││
	│C┈┈┈┈D││└┈┈┈┈┘│
	└───┈──┘└──┈───┘

	All nodes are in static position mode.

	C1: not relative; C2: relative

	Flipping:
	       ┌┈┈┈┬┈┈┈┐
	       | X | Y |
	┌┈┈┈┈┈┈┼┈┈┈┼┈┈┈┤
	| A, E |   |   |
	| B, F | * |   |
	| C, G |   | * |
	| D, H | * | * |
	└┈┈┈┈┈┈┴┈┈┈┴┈┈┈┘
	--]]

	local c1 = panel:addChild("base/container")
	c1.x = 0
	c1.y = 0
	c1.w = 256
	c1.h = 256
	c1.layout_tree:setMargin(16, 16, 16, 16)

	local c1_box = _makeBox(c1, "lightyellow", "darkyellow", "black", "Not Relative")
	c1.layout_tree:setWidget(c1_box)

	local wa = _makeBox(c1, "lightgreen", "green", "black", "(A)")
	local na = c1.layout_tree:newNode()
		:setStaticMode(0, 0, 48, 48, false, false, false)
		:setWidget(wa)

	local wb = _makeBox(c1, "lightblue", "blue", "white", "(B)")
	local nb = c1.layout_tree:newNode()
		:setStaticMode(0, 0, 48, 48, false, true, false)
		:setWidget(wb)

	local wc = _makeBox(c1, "lightgrey", "darkgrey", "black", "(C)")
	local nc = c1.layout_tree:newNode()
		:setStaticMode(0, 0, 48, 48, false, false, true)
		:setWidget(wc)

	local wd = _makeBox(c1, "lightmagenta", "magenta", "black", "(D)")
	local nd = c1.layout_tree:newNode()
		:setStaticMode(0, 0, 48, 48, false, true, true)
		:setWidget(wd)


	local c2 = panel:addChild("base/container")
	c2.x = c1.x + c1.w + 32
	c2.y = 0
	c2.w = 256
	c2.h = 256
	c2.layout_tree:setMargin(16, 16, 16, 16)

	local c2_box = _makeBox(c2, "darkgrey", "lightgrey", "white", "Relative")
	c2.layout_tree:setWidget(c2_box)

	local we = _makeBox(c2, "lightgreen", "green", "black", "(E)")
	local ne = c2.layout_tree:newNode()
		:setStaticMode(0, 0, 48, 48, true, false, false)
		:setWidget(we)

	local wf = _makeBox(c2, "lightblue", "blue", "white", "(F)")
	local nf = c2.layout_tree:newNode()
		:setStaticMode(0, 0, 48, 48, true, true, false)
		:setWidget(wf)

	local wg = _makeBox(c2, "lightgrey", "darkgrey", "black", "(G)")
	local ng = c2.layout_tree:newNode()
		:setStaticMode(0, 0, 48, 48, true, false, true)
		:setWidget(wg)

	local wh = _makeBox(c2, "lightmagenta", "magenta", "black", "(H)")
	local nh = c2.layout_tree:newNode()
		:setStaticMode(0, 0, 48, 48, true, true, true)
		:setWidget(wh)


	panel:reshape()
end


return plan
