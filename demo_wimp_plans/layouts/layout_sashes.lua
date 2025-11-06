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
	panel:containerSetScrollRangeMode("zero")
	panel:setSashesEnabled(true)

	--[[
	     work_box
	┌───┬─────────────┐
	│   │    C        │
	│   ├─────────┬───┤
	│   │         │   │
	│ A │    E    │ B │
	│   │         │   │
	│   ├─────────┴───┤
	│   │    D        │
	└───┴─────────────┘

	-- Layout + Order:
	A: segment/left
	C: segment/top
	D: segment/bottom
	B: segment/right
	E: remaining
	--]]

	local work_box = panel:addChild("base/container")
		:geometrySetMode("static", 16, 16, 512, 512)
		:setSashesEnabled(true)

	local wa = _makeBox(work_box, "lightblue", "blue", "white", "A")
		:geometrySetMode("segment", "left", 96, "norm")

	local wc = _makeBox(work_box, "lightgreen", "green", "black", "C")
		:geometrySetMode("segment", "top", 96, "norm")

	local wd = _makeBox(work_box, "lightyellow", "yellow", "black", "D")
		:geometrySetMode("segment", "bottom", 96, "norm")

	local wb = _makeBox(work_box, "lightcyan", "cyan", "black", "B")
		:geometrySetMode("segment", "right", 96, "norm")

	local we = _makeBox(work_box, "darkblue", "lightblue", "white", "E")
		:geometrySetMode("remaining")
end


return plan
