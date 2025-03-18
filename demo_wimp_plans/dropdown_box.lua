
-- ProdUI
local demoShared = require("demo_shared")
local uiLayout = require("prod_ui.ui_layout")


local plan = {}


function plan.make(panel)
	--title("Dropdown Boxes")

	panel:setScrollBars(false, false)

	--demoShared.makeLabel(panel, 32, 0, 512, 32, "...", "single")
	local dropdown = panel:addChild("wimp/dropdown_box")
	dropdown.x = 32
	dropdown.y = 96
	dropdown.w = 256
	dropdown.h = 32
	dropdown:initialize()
	dropdown:register("static")

	dropdown:addItem("foo")
	dropdown:addItem("bar")
	dropdown:addItem("baz")
	dropdown:addItem("bop")

	for i = 1, 100 do
		dropdown:addItem(tostring(i))
	end

	dropdown.wid_chosenSelection = function(self, index, tbl)
		print("Dropdown: New chosen selection: #" .. index .. ", Text: " .. tostring(tbl.text))
	end
end


return plan
