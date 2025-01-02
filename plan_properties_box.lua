
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

	frame:setFrameTitle("Properties Box Test")

	local content = frame:findTag("frame_content")
	if content then
		content.layout_mode = "resize"
		content:setScrollBars(false, true)

		makeLabel(content, 32, 0, 512, 32, "***Under Construction***", "single")

		local properties_box = content:addChild("wimp/properties_box")
		properties_box:setTag("demo_properties_box")

		properties_box.x = 0
		properties_box.y = 64
		properties_box.w = 400
		properties_box.h = 300

		properties_box:addItem("Foobar")
		properties_box:addItem("Cat")
		properties_box:addItem("Dog")

		local cbox = properties_box:addChild("base/checkbox")
		--local cbox = properties_box:addChild("wimp/embed/checkbox")
		cbox.x = 200
		cbox.y = 0
		cbox.w = 64
		cbox.h = 64

		properties_box:setScrollBars(false, true)
		properties_box:reshape()
	end

	frame:reshape(true)
	frame:center(true, true)

	return frame
end


return plan
