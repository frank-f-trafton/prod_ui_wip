--[[
Divider development and testing.
--]]


-- ProdUI
local uiLayout = require("prod_ui.ui_layout")


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
	--title("Sashes")

	--[[
	┌┈┬┈┬┈┬┈┬┈┐
	│A│C│ │ │ │
	├┈┼┈┤E│F│G│
	│B│D│ │ │ │
	└─┴─┴─┴─┴─┘

	  G
	  |
	+-+-+-+
	| | | |
	A C E F
	| |
	B D
	--]]

	local wa = _makeBox(divider, "lightgreen", "green", "black", "(A)")
	local wb = _makeBox(divider, "lightblue", "blue", "white", "(B)")
	local wc = _makeBox(divider, "lightgrey", "darkgrey", "black", "(C)")
	local wd = _makeBox(divider, "lightmagenta", "magenta", "black", "(D)")
	local we = _makeBox(divider, "lightyellow", "darkyellow", "black", "(E)")
	local wf = _makeBox(divider, "darkgrey", "lightgrey", "white", "(F)")
	local wg = _makeBox(divider, "darkblue", "lightblue", "white", "(G)")

	divider.node.wid_ref = wg
	-- The root node's placement is whatever space is remaining.

	local na = divider.node:newNode()
	na.wid_ref = wa
	na.placement = "left"

	local nb = na:newNode()
	nb.wid_ref = wb
	nb.placement = "bottom"

	local nc = divider.node:newNode()
	nc.wid_ref = wc
	nc.placement = "left"

	local nd = nc:newNode()
	nd.wid_ref = wd
	nd.placement = "bottom"

	local ne = divider.node:newNode()
	ne.wid_ref = we
	ne.placement = "left"

	local nf = divider.node:newNode()
	nf.wid_ref = wf
	nf.placement = "left"

	-- 'wg' is part of the root node.
--[===[
	--]===]

	divider:reshape()
end


return plan
