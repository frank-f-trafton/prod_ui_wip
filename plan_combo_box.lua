
-- ProdUI
local uiLayout = require("prod_ui.ui_layout")
local widShared = require("prod_ui.common.wid_shared")


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
	frame.h = 480

	frame:setFrameTitle("Combo Boxes")

	local content = frame:findTag("frame_content")
	if content then
		content.layout_mode = "resize"
		content:setScrollBars(false, false)

		makeLabel(content, 32, 0, 512, 32, "**Under Construction** This widget doesn't work correctly yet.", "single")
		local combo_box = content:addChild("wimp/combo_box")

		combo_box.x = 32
		combo_box.y = 96
		combo_box.w = 256
		combo_box.h = 32

		combo_box:addItem("foo")
		combo_box:addItem("bar")
		combo_box:addItem("baz")
		combo_box:addItem("bop")

		for i = 1, 100 do
			combo_box:addItem(tostring(i))
		end

		combo_box.wid_inputChanged = function(self, str)
			print("ComboBox: Input changed: " .. str)
		end
		combo_box.wid_action = function(self)
			print("ComboBox: user pressed enter")
		end
		combo_box.wid_thimbleOff = function(self)
			print("ComboBox: user navigated away from this widget")
		end
	end

	frame:reshape(true)
	frame:center(true, true)

	return frame
end


return plan
