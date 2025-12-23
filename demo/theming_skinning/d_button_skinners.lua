
-- ProdUI
local demoShared = require("demo_shared")


local plan = {}


function plan.make(panel)
	--title("Button skin tests")

	panel:layoutSetBase("viewport-width")
	panel:containerSetScrollRangeMode("zero")
	panel:setScrollBars(false, false)

	local wid_id = "base/button"
	local skin_id = panel.context.widget_defs[wid_id].skin_id .. "_DEMO"
	local button_norm = panel:addChild(wid_id, skin_id)
		:geometrySetMode("static", 256, 0, 224, 64)
		:setLabel("Normal Skinned Button")

	local function buttonAlignH(self)
		button_norm.skin.label_align_h = self.usr_align
	end

	local function buttonAlignV(self)
		button_norm.skin.label_align_v = self.usr_align
	end

	local xx, yy, ww1, ww2, hh1, hh2 = 0, 0, 64, 192, 40, 64

	demoShared.makeLabel(panel, xx, yy, ww2, hh1, false, "skin.label_align_h", "single")

	yy = yy + hh1

	local bb_rdo
	bb_rdo = panel:addChild("base/button")
		:geometrySetMode("static", xx, yy, ww1, hh2)
		:setLabel("Left")
	bb_rdo.usr_align = "left"
	bb_rdo.wid_buttonAction = buttonAlignH

	xx = xx + ww1

	bb_rdo = panel:addChild("base/button")
		:geometrySetMode("static", xx, yy, ww1, hh2)
		:setLabel("Center")
	bb_rdo.usr_align = "center"
	bb_rdo.wid_buttonAction = buttonAlignH

	xx = xx + ww1

	bb_rdo = panel:addChild("base/button")
		:geometrySetMode("static", xx, yy, ww1, hh2)
		:setLabel("Right")
	bb_rdo.usr_align = "right"
	bb_rdo.wid_buttonAction = buttonAlignH

	xx = 0
	yy = yy + hh2

	bb_rdo = panel:addChild("base/button")
		:geometrySetMode("static", xx, yy, ww2, hh2)
		:setLabel("Justify")
	bb_rdo.usr_align = "justify"
	bb_rdo.wid_buttonAction = buttonAlignH

	yy = yy + hh2

	yy = yy + hh1

	demoShared.makeLabel(panel, xx, yy, ww2, hh1, false, "skin.label_align_v", "single")

	yy = yy + hh1

	bb_rdo = panel:addChild("base/button")
		:geometrySetMode("static", xx, yy, ww1, hh2)
		:setLabel("Top")
	bb_rdo.usr_align = "top"
	bb_rdo.wid_buttonAction = buttonAlignV

	xx = xx + ww1

	bb_rdo = panel:addChild("base/button")
		:geometrySetMode("static", xx, yy, ww1, hh2)
		:setLabel("Middle")
	bb_rdo.usr_align = "middle"
	bb_rdo.wid_buttonAction = buttonAlignV

	xx = xx + ww1

	bb_rdo = panel:addChild("base/button")
		:geometrySetMode("static", xx, yy, ww1, hh2)
		:setLabel("Bottom")
	bb_rdo.usr_align = "bottom"
	bb_rdo.wid_buttonAction = buttonAlignV

	xx = xx + ww1
end


return plan
