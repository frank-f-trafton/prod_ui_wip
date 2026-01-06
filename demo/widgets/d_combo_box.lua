
-- ProdUI
local demoShared = require("demo_shared")


local plan = {}


function plan.make(panel)
	--title("Combo Boxes")

	panel:layoutSetBase("viewport-width")
	panel:containerSetScrollRangeMode("zero")
	panel:setScrollBars(false, false)

	local combo_box = panel:addChild("wimp/combo_box")
	combo_box:geometrySetMode("static", 32, 96, 256, 32)
	combo_box:addItem("foo")
	combo_box:addItem("bar")
	combo_box:addItem("baz")
	combo_box:addItem("bop")

	for i = 1, 100 do
		combo_box:addItem(tostring(i))
	end

	combo_box:userCallbackSet("cb_inputChanged", function(self, str)
		print("ComboBox: Input changed: " .. str)
	end)
	combo_box:userCallbackSet("cb_action", function(self)
		print("ComboBox: user pressed enter")
	end)
	combo_box:userCallbackSet("cb_thimble1Release", function(self)
		print("ComboBox: user navigated away from this widget")
	end)
end


return plan
