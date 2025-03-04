
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
	--title("Properties Box Test")
	panel.auto_layout = true
	panel:setScrollBars(false, true)

	makeLabel(panel, 32, 0, 512, 32, "***Under Construction***", "single")

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
