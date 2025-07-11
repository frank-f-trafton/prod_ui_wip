local plan = {}


-- ProdUI
local demoShared = require("demo_shared")


local function timeFormatted()
	return string.format("%.2f", tostring(love.timer.getTime()))
end


function plan.make(panel)
	--title("Stepper")

	panel:setLayoutBase("viewport-width")
	panel:setScrollRangeMode("auto")
	panel:setScrollBars(false, true)

	local stepper_h = panel:addChild("base/stepper")
	demoShared.setStaticLayout(panel, stepper_h, 32, 32, 240, 32)

	stepper_h:insertOption("Foobar")
	stepper_h:insertOption("Bazbop")
	local remove_test_i = stepper_h:insertOption("Remove Test")
	stepper_h:insertOption({text = "Dipdop"})

	stepper_h:removeOption(remove_test_i)

	stepper_h:reshape()


	local stepper_v = panel:addChild("base/stepper")
	demoShared.setStaticLayout(panel, stepper_v, 288, 32, 64, 128)
	stepper_v:insertOption("Foobar")
	stepper_v:insertOption("Bazbop")
	stepper_v:insertOption({text = "Dipdop"})

	stepper_v.vertical = true

	stepper_v:reshape()
end


return plan
