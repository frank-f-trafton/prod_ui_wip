
-- ProdUI
local uiLayout = require("prod_ui.ui_layout")
local widShared = require("prod_ui.common.wid_shared")


local plan = {}


local function makeLabel(panel, x, y, w, h, text, label_mode)
	label_mode = label_mode or "single"

	local label = panel:addChild("base/label")
	label.x, label.y, label.w, label.h = x, y, w, h
	label:initialize()
	label:setLabel(text, label_mode)

	return label
end


function plan.make(panel)
	--title("Dropdown Boxes")

	panel.auto_layout = true
	panel:setScrollBars(false, false)

	--makeLabel(panel, 32, 0, 512, 32, "...", "single")
	local dropdown = panel:addChild("wimp/dropdown_box")
	dropdown.x = 32
	dropdown.y = 96
	dropdown.w = 256
	dropdown.h = 32
	dropdown:initialize()

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
