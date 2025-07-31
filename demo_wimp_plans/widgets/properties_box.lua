
-- ProdUI
local demoShared = require("demo_shared")


local plan = {}


function plan.make(panel)
	--title("Properties Box Test")

	panel:setLayoutBase("viewport-width")
	panel:setScrollRangeMode("auto")
	panel:setScrollBars(false, true)

	local properties_box = panel:addChild("wimp/properties_box")
	demoShared.setStaticLayout(panel, properties_box, 0, 64, 400, 300)

	properties_box:setTag("demo_properties_box")

	-- (wid_id, text, pos, icon_id)
	local c1 = properties_box:addControl("wimp/embed/checkbox", "Foobar")
	local c2 = properties_box:addControl("wimp/embed/checkbox", "Cat")
	local c3 = properties_box:addControl("input/text_box_single", "Dog")
	--c3.LE_select_all_on_thimble1_take = true
	--c3.LE_deselect_all_on_thimble1_release = true
	local c4 = properties_box:addControl("wimp/number_box", "Number")

	properties_box:setScrollBars(false, true)
	properties_box:reshape()
end


return plan
