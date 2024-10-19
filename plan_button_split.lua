
-- ProdUI
local commonMenu = require("prod_ui.logic.common_menu")
local uiLayout = require("prod_ui.ui_layout")
local widShared = require("prod_ui.logic.wid_shared")


local plan = {}


local function makeLabel(content, x, y, w, h, text, label_mode)
	label_mode = label_mode or "single"

	local label = content:addChild("base/label")
	label.x, label.y, label.w, label.h = x, y, w, h
	label:setLabel(text, label_mode)

	return label
end


function plan.make(parent)
	local context = parent.context

	local frame = parent:addChild("wimp/window_frame")

	frame.w = 640
	frame.h = 640

	frame:setFrameTitle("Split Button")

	local content = frame:findTag("frame_content")
	if content then
		content.layout_mode = "resize"
		content:setScrollBars(false, true)

		-- Split Button
		local btn_spl = content:addChild("wimp/button_split")
		btn_spl.x = 0
		btn_spl.y = 0
		btn_spl.w = 224
		btn_spl.h = 64

		btn_spl:setLabel("Split Button")

		--[[
		btn_spl.wid_buttonAction = function(self)

		end
		--]]

		makeLabel(content, 0, 80, 256, 64, "(WIP: A menu will appear when clicking the right-hand side of this button.)", "multi")
	end

	frame:reshape(true)
	frame:center(true, true)

	return frame
end


return plan
