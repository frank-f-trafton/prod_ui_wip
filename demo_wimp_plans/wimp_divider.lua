local plan = {}


local function _makeBox(self, fill, outline, text_color, text)
	local wid = self:addChild("test/colorful_box")
	wid:initialize()
	wid:setColor(fill, outline, text_color)
	wid:setText(text)

	return wid
end


function plan.make(panel)
	--title("Dividers")

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

	panel:setLayoutNode(wg, panel.layout_tree)

	local n_grid = panel.layout_tree:newNode()
	n_grid:setMode("slice", "unit", "left", 0.4)
	n_grid:setMargin(4, 4, 4, 4)
	n_grid:setGridDimensions(2, 2)

	local na = n_grid:newNode()
	panel:setLayoutNode(wa, na)
	na:setMode("grid", 0, 0)
	na:setMargin(4, 4, 4, 4)

	local nb = n_grid:newNode()
	panel:setLayoutNode(wb, nb)
	nb:setMode("grid", 0, 1)
	nb:setMargin(4, 4, 4, 4)

	local nc = n_grid:newNode()
	panel:setLayoutNode(wc, nc)
	nc:setMode("grid", 1, 0)
	nc:setMargin(4, 4, 4, 4)

	local nd = n_grid:newNode()
	panel:setLayoutNode(wd, nd)
	nd:setMode("grid", 1, 1)
	nd:setMargin(4, 4, 4, 4)

	local ne = panel.layout_tree:newNode()
	panel:setLayoutNode(we, ne)
	ne:setMode("slice", "unit", "left", 0.2)

	local nf = panel.layout_tree:newNode()
	panel:setLayoutNode(wf, nf)
	nf:setMode("slice", "px", "left", 140)
	--nf:setMode("slice", "unit", "left", 0.2)

	local ns = panel.layout_tree:newNode()
	-- Sash nodes do not refer to widgets, at least not in the original design.
	panel:configureSashNode(nf, ns)

	-- 'wg' is part of the root node.

	panel:reshape()
end


return plan
