

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
	--title("Number Box")

	panel.auto_layout = true
	panel:setScrollBars(false, false)

	-- [=[
	local num_box = panel:addChild("wimp/number_box")
	num_box.x = 32
	num_box.y = 96
	num_box.w = 256
	num_box.h = 32

	num_box.wid_action = function(self)
		-- WIP
	end

	num_box:initialize()
	--]=]
end


return plan
