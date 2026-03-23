local plan = {}


-- ProdUI
local demoShared = require("demo_shared")


local function timeFormatted()
	return string.format("%.2f", tostring(love.timer.getTime()))
end


function plan.make(panel)
	--title("Stepper")

	panel:layoutSetBase("viewport-width")
	panel:containerSetScrollRangeMode("auto")
	panel:setScrollBars(false, true)

	local stepper_h = panel:addChild("base/stepper")
	stepper_h:geometrySetMode("static", 32, 32, 240, 32)
	stepper_h:addItem("Foobar")
	stepper_h:addItem("Bazbop")
	local remove_test_item = stepper_h:addItem("Remove Test")
	stepper_h:addItem("Dipdop")

	stepper_h:removeItem(remove_test_item)


	local stepper_v = panel:addChild("base/stepper")
	stepper_v:geometrySetMode("static", 288, 32, 64, 128)
	stepper_v:addItem("Foobar")
	stepper_v:addItem("Bazbop")
	stepper_v:addItem("Dipdop")

	stepper_v.vertical = true
end


return plan
