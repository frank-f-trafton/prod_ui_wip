

-- ProdUI
local uiLayout = require("prod_ui.ui_layout")
local widShared = require("prod_ui.common.wid_shared")


local plan = {}


local function makeLabel(frame, x, y, w, h, text, label_mode)
	label_mode = label_mode or "single"

	local label = frame:addChild("base/label")
	label.x, label.y, label.w, label.h = x, y, w, h
	label:initialize()
	label:setLabel(text, label_mode)

	return label
end


function plan.make(root)
	local context = root.context

	local frame = root:newWindowFrame()
	frame.w = 640
	frame.h = 480
	frame:initialize()
	frame:setFrameTitle("Number Box")
	frame.auto_layout = true
	frame:setScrollBars(false, false)

	-- [=[
	local num_box = frame:addChild("wimp/number_box")
	num_box.x = 32
	num_box.y = 96
	num_box.w = 256
	num_box.h = 32

	num_box.wid_action = function(self)
		-- WIP
	end

	num_box:initialize()
	--]=]

	frame:reshape(true)
	frame:center(true, true)

	return frame
end


return plan
