local plan = {
	container_type = "wimp/divider"
}


local function _makeBox(self, fill, outline, text_color, text)
	local wid = self:addChild("test/colorful_box")
	wid:initialize()
	wid:setColor(fill, outline, text_color)
	wid:setText(text)

	return wid
end


function plan.make(divider)
	--title("Dividers")

	--[[
	┌┈┬┈┬┈┬┈┬┈┐
	│A│C│ │ │ │
	├┈┼┈┤E│F│G│
	│B│D│ │ │ │
	└─┴─┴─┴─┴─┘

	      G
	      |
	   +-----+-+-+
	   |     | | |
	n_grid   E F G
	   |
	+-+-+-+
	| | | |
	A B C D
	--]]

	local wa = _makeBox(divider, "lightgreen", "green", "black", "(Grid 0,0)")
	local wb = _makeBox(divider, "lightblue", "blue", "white", "(Grid 0,1)")
	local wc = _makeBox(divider, "lightgrey", "darkgrey", "black", "(Grid 1,0)")
	local wd = _makeBox(divider, "lightmagenta", "magenta", "black", "(Grid 1,1)")
	local we = _makeBox(divider, "lightyellow", "darkyellow", "black", "(E)")
	local wf = _makeBox(divider, "darkgrey", "lightgrey", "white", "(F)")
	local wg = _makeBox(divider, "darkblue", "lightblue", "white", "(G)")

	divider.node.wid_ref = wg

	local n_grid = divider.node:newNode()
	n_grid:setMode("slice", "unit-original", "left", 0.4)
	n_grid:setMargin(4, 4, 4, 4)
	n_grid:setGridDimensions(2, 2)

	local na = n_grid:newNode()
	na.wid_ref = wa
	na:setMode("grid", 0, 0)
	na:setMargin(4, 4, 4, 4)

	local nb = n_grid:newNode()
	nb.wid_ref = wb
	nb:setMode("grid", 0, 1)
	nb:setMargin(4, 4, 4, 4)

	local nc = n_grid:newNode()
	nc.wid_ref = wc
	nc:setMode("grid", 1, 0)
	nc:setMargin(4, 4, 4, 4)

	local nd = n_grid:newNode()
	nd.wid_ref = wd
	nd:setMode("grid", 1, 1)
	nd:setMargin(4, 4, 4, 4)

	local ne = divider.node:newNode()
	ne.wid_ref = we
	ne:setMode("slice", "unit-original", "left", 0.2)

	local nf = divider.node:newNode()
	nf.wid_ref = wf
	nf:setMode("slice", "unit-original", "left", 0.2)

	-- 'wg' is part of the root node.

	divider:reshape()
end


return plan
