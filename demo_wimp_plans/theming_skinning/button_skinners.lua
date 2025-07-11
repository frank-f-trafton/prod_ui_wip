
-- ProdUI
local demoShared = require("demo_shared")


local plan = {}


function plan.make(panel)
	--title("Button skin tests")

	panel:setLayoutBase("viewport-width")
	panel:setScrollRangeMode("zero")
	panel:setScrollBars(false, false)

	local wid_id = "base/button"
	local skin_id = panel.context.widget_defs[wid_id].skin_id .. "_DEMO"
	local button_norm = panel:addChild(wid_id, nil, skin_id)
	demoShared.setStaticLayout(panel, button_norm, 256, 0, 224, 64)
	button_norm:setLabel("Normal Skinned Button")

	local function radioAlignH(self)
		button_norm.skin.label_align_h = self.usr_align
	end

	local function radioAlignV(self)
		button_norm.skin.label_align_v = self.usr_align
	end

	local xx, yy, ww1, ww2, hh1, hh2 = 0, 0, 64, 192, 40, 64

	demoShared.makeLabel(panel, xx, yy, ww2, hh1, "skin.label_align_h", "single")

	yy = yy + hh1

	local bb_rdo
	bb_rdo = panel:addChild("barebones/radio_button")
	demoShared.setStaticLayout(panel, bb_rdo, xx, yy, ww1, hh2)
	bb_rdo.radio_group = "align_h"
	bb_rdo.usr_align = "left"
	bb_rdo:setLabel("Left")
	bb_rdo.wid_buttonAction = radioAlignH

	xx = xx + ww1

	bb_rdo = panel:addChild("barebones/radio_button")
	demoShared.setStaticLayout(panel, bb_rdo, xx, yy, ww1, hh2)
	bb_rdo.radio_group = "align_h"
	bb_rdo.usr_align = "center"
	bb_rdo:setLabel("Center")
	bb_rdo.wid_buttonAction = radioAlignH

	xx = xx + ww1

	bb_rdo = panel:addChild("barebones/radio_button")
	demoShared.setStaticLayout(panel, bb_rdo, xx, yy, ww1, hh2)
	bb_rdo.radio_group = "align_h"
	bb_rdo.usr_align = "right"
	bb_rdo:setLabel("Right")
	bb_rdo.wid_buttonAction = radioAlignH

	xx = 0
	yy = yy + hh2

	bb_rdo = panel:addChild("barebones/radio_button")
	demoShared.setStaticLayout(panel, bb_rdo, xx, yy, ww2, hh2)
	bb_rdo.radio_group = "align_h"
	bb_rdo.usr_align = "justify"
	bb_rdo:setLabel("Justify")
	bb_rdo.wid_buttonAction = radioAlignH

	bb_rdo:setCheckedConditional("usr_align", button_norm.skin.label_align_h)

	yy = yy + hh2

	yy = yy + hh1

	demoShared.makeLabel(panel, xx, yy, ww2, hh1, "skin.label_align_v", "single")

	yy = yy + hh1

	local bb_rdo
	bb_rdo = panel:addChild("barebones/radio_button")
	demoShared.setStaticLayout(panel, bb_rdo, xx, yy, ww1, hh2)
	bb_rdo.radio_group = "align_v"
	bb_rdo.usr_align = "top"
	bb_rdo:setLabel("Top")
	bb_rdo.wid_buttonAction = radioAlignV

	xx = xx + ww1

	bb_rdo = panel:addChild("barebones/radio_button")
	demoShared.setStaticLayout(panel, bb_rdo, xx, yy, ww1, hh2)
	bb_rdo.radio_group = "align_v"
	bb_rdo.usr_align = "middle"
	bb_rdo:setLabel("Middle")
	bb_rdo.wid_buttonAction = radioAlignV

	xx = xx + ww1

	bb_rdo = panel:addChild("barebones/radio_button")
	demoShared.setStaticLayout(panel, bb_rdo, xx, yy, ww1, hh2)
	bb_rdo.radio_group = "align_v"
	bb_rdo.usr_align = "bottom"
	bb_rdo:setLabel("Bottom")
	bb_rdo.wid_buttonAction = radioAlignV

	bb_rdo:setCheckedConditional("usr_align", button_norm.skin.label_align_v)

	xx = xx + ww1
end


return plan
