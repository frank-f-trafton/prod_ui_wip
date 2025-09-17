local plan = {}


local function _makeBox(self, fill, outline, text_color, text)
	local wid = self:addChild("test/colorful_box")
	wid:setColor(fill, outline, text_color)
	wid:setText(text)

	return wid
end


function plan.make(panel)
	--title("Layout")

	panel:layoutSetBase("viewport")
	panel:setScrollRangeMode("zero")
	panel:setSashesEnabled(true)

	--[[
	  H
	┌─┴─┐
	┌─┬─┬─┬─┬─┐
	│A│C│ │ │ │
	├─┼─┤E│FsG│
	│B│D│ │ │ │
	└─┴─┴─┴─┴─┘

	    panel
	      │
	   ┌──┴──┬─┬─┬─┐
	   │     │ │ │ │
	   H     E F s G
	   │
	┌─┬─┬─┐
	│ │ │ │
	A B C D
	--]]

	local container_h = panel:addChild("base/container_simple")
		:layoutSetMode("slice", "unit", "left", 0.4)
		:layoutSetMargin(16, 16, 16, 16)
		:layoutSetGridDimensions(2, 2)
		:layoutAdd()

	local wa = _makeBox(container_h, "lightgreen", "green", "black", "(Grid 0,0)")
		:layoutSetMode("grid", 0, 0)
		--:layoutSetPadding(4, 4, 4, 4)
		:layoutAdd()

	local wb = _makeBox(container_h, "lightblue", "blue", "white", "(Grid 0,1)")
		:layoutSetMode("grid", 0, 1)
		--:layoutSetPadding(4, 4, 4, 4)
		:layoutAdd()

	local wc = _makeBox(container_h, "lightgrey", "darkgrey", "black", "(Grid 1,0)")
		:layoutSetMode("grid", 1, 0)
		--:layoutSetPadding(4, 4, 4, 4)
		:layoutAdd()

	local wd = _makeBox(container_h, "lightmagenta", "magenta", "black", "(Grid 1,1)")
		:layoutSetMode("grid", 1, 1)
		--:layoutSetPadding(4, 4, 4, 4)
		:layoutAdd()

	local we = _makeBox(panel, "lightyellow", "darkyellow", "black", "(E)")
		:layoutSetMode("slice", "unit", "left", 0.2)
		:layoutAdd()

	local wf = _makeBox(panel, "darkgrey", "lightgrey", "white", "(F)")
		--:layoutSetMode("slice", "unit", "left", 0.2)
		:layoutSetMode("slice", "px", "left", 140)
		:layoutAdd()

	--[[
	local sash = panel:addChild("base/sash")
		:setLayoutMode("slice", "px", " -- TODO
	--]]
	--panel:configureSashNode(nf, ns) TODO: fix this up

	local wg = _makeBox(panel, "darkblue", "lightblue", "white", "(G)")
		:layoutSetMode("remaining")
		:layoutAdd()

	panel:reshape()
end


return plan
