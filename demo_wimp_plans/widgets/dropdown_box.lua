
-- ProdUI
local demoShared = require("demo_shared")


local plan = {}


function plan.make(panel)
	--title("Dropdown Boxes")

	panel:layoutSetBase("viewport-width")
	panel:setScrollRangeMode("zero")
	panel:setScrollBars(false, false)

	--demoShared.makeLabel(panel, 32, 0, 512, 32, "...", "single")
	local dropdown = panel:addChild("wimp/dropdown_box")
	dropdown:layoutSetMode("static", 32, 96, 256, 32)
		:layoutAdd()

	dropdown:writeSetting("show_icons", true)

	dropdown:addItem("foo", nil, "file")
	dropdown:addItem("bar", nil, "folder")
	dropdown:addItem("baz")
	dropdown:addItem("bop")

	-- [[
	for i = 1, 100 do
		dropdown:addItem(tostring(i))
	end
	--]]

	dropdown.wid_chosenSelection = function(self, index, tbl)
		print("Dropdown: New chosen selection: #" .. index .. ", Text: " .. tostring(tbl.text))
	end
end


return plan
