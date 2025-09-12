local plan = {}


local function _makeBox(self, fill, outline, text_color, text)
	local wid = self:addChild("test/colorful_box")
	wid:setColor(fill, outline, text_color)
	wid:setText(text)

	return wid
end


function plan.make(panel)
	--title("Layout")

	panel:setLayoutBase("viewport")
	panel:setScrollRangeMode("zero")
	panel:setSashesEnabled(true)

	--[[
	┌┈┬┈┬┈┬┈┬┈┐
	│A│C│ │ │ │
	├┈┼┈┤E│FsG│
	│B│D│ │ │ │
	└─┴─┴─┴─┴─┘

	      G
	      |
	   +-----+-+-+-+
	   |     | | | |
	n_grid   E F s G
	   |
	+-+-+-+
	| | | |
	A B C D
	--]]

	local wa = _makeBox(panel, "lightgreen", "green", "black", "(Grid 0,0)")
	local wb = _makeBox(panel, "lightblue", "blue", "white", "(Grid 0,1)")
	local wc = _makeBox(panel, "lightgrey", "darkgrey", "black", "(Grid 1,0)")
	local wd = _makeBox(panel, "lightmagenta", "magenta", "black", "(Grid 1,1)")
	local we = _makeBox(panel, "lightyellow", "darkyellow", "black", "(E)")
	local wf = _makeBox(panel, "darkgrey", "lightgrey", "white", "(F)")
	-- s: no widget
	local wg = _makeBox(panel, "darkblue", "lightblue", "white", "(G)")

	panel.layout_tree:setWidget(wg)

	local n_grid = panel.layout_tree:newNode()
		:setSliceMode("unit", "left", 0.4)
		:setMargin(4, 4, 4, 4)
		:setGridDimensions(2, 2)

	local na = n_grid:newNode()
		:setGridMode(0, 0)
		:setMargin(4, 4, 4, 4)
		:setWidget(wa)

	local nb = n_grid:newNode()
		:setGridMode(0, 1)
		:setMargin(4, 4, 4, 4)
		:setWidget(wb)

	local nc = n_grid:newNode()
		:setGridMode(1, 0)
		:setMargin(4, 4, 4, 4)
		:setWidget(wc)

	local nd = n_grid:newNode()
		:setGridMode(1, 1)
		:setMargin(4, 4, 4, 4)
		:setWidget(wd)

	local ne = panel.layout_tree:newNode()
		:setSliceMode("unit", "left", 0.2)
		:setWidget(we)

	local nf = panel.layout_tree:newNode()
		--:setSliceMode("unit", "left", 0.2)
		:setSliceMode("px", "left", 140)
		:setWidget(wf)

	local ns = panel.layout_tree:newNode()
	-- Sash nodes do not refer to widgets, at least not in the original design.
	panel:configureSashNode(nf, ns)

	-- 'wg' is part of the root node.

	panel:reshape()
end


return plan
