local plan = {}


-- ProdUI
local demoShared = require("demo_shared")


local function timeFormatted()
	return string.format("%.2f", tostring(love.timer.getTime()))
end


function plan.make(panel)
	--title("Stepper")

	panel:layoutSetBase("viewport-width")
	panel:setScrollRangeMode("auto")
	panel:setScrollBars(false, true)

	local stepper_h = panel:addChild("base/stepper")
	stepper_h:layoutSetMode("static", 32, 32, 240, 32)
		:layoutAdd()

	stepper_h:insertOption("Foobar")
	stepper_h:insertOption("Bazbop")
	local remove_test_i = stepper_h:insertOption("Remove Test")
	stepper_h:insertOption({text = "Dipdop"})

	stepper_h:removeOption(remove_test_i)

	stepper_h:reshape()


	local stepper_v = panel:addChild("base/stepper")
	stepper_v:layoutSetMode("static", 288, 32, 64, 128)
		:layoutAdd()
	stepper_v:insertOption("Foobar")
	stepper_v:insertOption("Bazbop")
	stepper_v:insertOption({text = "Dipdop"})

	stepper_v.vertical = true

	stepper_v:reshape()
end


return plan
