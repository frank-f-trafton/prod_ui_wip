
-- ProdUI
local demoShared = require("demo_shared")


local plan = {
	container_type = "base/container"
}


function plan.make(panel)
	--title("Properties Box Test")
	panel:setScrollBars(false, true)

	demoShared.makeLabel(panel, 32, 0, 512, 32, "***Under Construction***", "single")

	local properties_box = panel:addChild("wimp/properties_box")
	properties_box.x = 0
	properties_box.y = 64
	properties_box.w = 400
	properties_box.h = 300
	properties_box:initialize()

	properties_box:setTag("demo_properties_box")

	-- (wid_id, text, pos, bijou_id)
	local c1 = properties_box:addControl("wimp/embed/checkbox", "Foobar")
	local c2 = properties_box:addControl("wimp/embed/checkbox", "Cat")
	local c3 = properties_box:addControl("input/text_box_single", "Dog")
	--c3.select_all_on_thimble1_take = true
	--c3.deselect_all_on_thimble1_release = true
	local c4 = properties_box:addControl("wimp/number_box", "Number")

	properties_box:setScrollBars(false, true)
	properties_box:reshape()
end


return plan
