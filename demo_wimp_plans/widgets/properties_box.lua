
-- ProdUI
local demoShared = require("demo_shared")


local plan = {}


function plan.make(panel)
	--title("Properties Box Test")

	panel:layoutSetBase("viewport-width")
	panel:setScrollRangeMode("auto")
	panel:setScrollBars(false, true)

	local properties_box = panel:addChild("wimp/properties_box")
	properties_box:geometrySetMode("static", 0, 64, 400, 300)
	properties_box:setTag("demo_properties_box")

	-- (wid_id, text, pos, icon_id)
	local c1 = properties_box:addItem("wimp/embed/checkbox", "Foobar")
	local c2 = properties_box:addItem("wimp/embed/checkbox", "Cat")
	local c3 = properties_box:addItem("input/text_box_single", "Dog")
	--c3:setSelectAllOnThimble1Take(true)
	--c3:setDeselectAllOnThimble1Release(true)
	local c4 = properties_box:addItem("wimp/number_box", "Number")

	properties_box:setScrollBars(false, true)
	properties_box:reshape()
end


return plan
