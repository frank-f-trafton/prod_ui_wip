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
		:geometrySetMode("slice", "unit", "left", 0.4)
		:layoutSetMargin(16, 16, 16, 16)
		:layoutSetGridDimensions(2, 2)

	local wa = _makeBox(container_h, "lightgreen", "green", "black", "(Grid 0,0)")
		:geometrySetMode("grid", 0, 0)
		--:geometrySetPadding(4, 4, 4, 4)

	local wb = _makeBox(container_h, "lightblue", "blue", "white", "(Grid 0,1)")
		:geometrySetMode("grid", 0, 1)
		--:geometrySetPadding(4, 4, 4, 4)

	local wc = _makeBox(container_h, "lightgrey", "darkgrey", "black", "(Grid 1,0)")
		:geometrySetMode("grid", 1, 0)
		--:geometrySetPadding(4, 4, 4, 4)

	local wd = _makeBox(container_h, "lightmagenta", "magenta", "black", "(Grid 1,1)")
		:geometrySetMode("grid", 1, 1)
		--:geometrySetPadding(4, 4, 4, 4)

	local we = _makeBox(panel, "lightyellow", "darkyellow", "black", "(E)")
		:geometrySetMode("slice", "unit", "left", 0.2)

	local wf = _makeBox(panel, "darkgrey", "lightgrey", "white", "(F)")
		--:geometrySetMode("slice", "unit", "left", 0.2)
		:geometrySetMode("slice", "px", "left", 140)

	local sash = panel:addChild("base/sash")
	panel:configureSashWidget(wf, sash)

	local wg = _makeBox(panel, "darkblue", "lightblue", "white", "(G)")
		:geometrySetMode("remaining")

	panel:reshape()
end


return plan
