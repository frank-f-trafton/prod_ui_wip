
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


local function _frame_launchFrame(self, id)

end


local function _button_launchFrame(self)
	if type(self.usr_plan) ~= "string" then error("bad type or missing plan ID to launch") end
	local plan = require(self.usr_plan)
	local root = self:getTopWidgetInstance()
	local frame = plan.make(root)
	return frame
end


local function _makeButton(content, id, label, x, y, w, h)
	assert(type(id) == "string")
	assert(type(label) == "string")

	local bb_btn = content:addChild("barebones/button", {x=x, y=y, w=w, h=h})
	bb_btn.wid_buttonAction = _button_launchFrame
	bb_btn:setLabel(label)
	bb_btn.usr_plan = id
	return bb_btn
end


function plan.make(parent)
	local context = parent.context

	local frame = parent:addChild("wimp/window_frame")

	frame.w = 640
	frame.h = 480

	frame:setFrameTitle("Plan launcher")

	local content = frame:findTag("frame_content")
	if content then
		content.layout_mode = "resize"

		content:setScrollBars(false, false)

		local xx, yy, ww, hh = 0, 0, 192, 40

		local bb_btn

		bb_btn = content:addChild("barebones/button", {x=xx, y=yy, w=ww, h=hh})
		bb_btn:setLabel("Open all (slow)")
		bb_btn.wid_buttonAction = function(self)
			local siblings = self:getParent().children
			for i, sib in ipairs(siblings) do
				if sib ~= self and type(sib.usr_plan) == "string" then
					_button_launchFrame(sib)
				end
			end
		end

		yy = yy + hh

		yy = yy + hh; bb_btn = _makeButton(content, "plan_number_box", "Number Box", xx, yy, ww, hh)
		yy = yy + hh; bb_btn = _makeButton(content, "plan_properties_box", "Properties Box", xx, yy, ww, hh)
		yy = yy + hh; bb_btn = _makeButton(content, "plan_combo_box", "Combo Box", xx, yy, ww, hh)
		yy = yy + hh; bb_btn = _makeButton(content, "plan_dropdown_box", "Dropdown Box", xx, yy, ww, hh)
		yy = yy + hh; bb_btn = _makeButton(content, "plan_text_box_single", "Textbox (Single-Line)", xx, yy, ww, hh)
		yy = yy + hh; bb_btn = _makeButton(content, "plan_text_box_multi", "Textbox (Multi-Line)", xx, yy, ww, hh)
		yy = yy + hh; bb_btn = _makeButton(content, "plan_button_skinners", "Button Skinners", xx, yy, ww, hh)
		yy = yy + hh; bb_btn = _makeButton(content, "plan_barebones", "Barebones Widgets", xx, yy, ww, hh)
		yy = yy + hh; bb_btn = _makeButton(content, "plan_wimp_tree_box", "Tree Box", xx, yy, ww, hh)
		yy = yy + hh; bb_btn = _makeButton(content, "plan_wimp_list_box", "List Box", xx, yy, ww, hh)
		yy = yy + hh; bb_btn = _makeButton(content, "plan_button_work", "Button work", xx, yy, ww, hh)
		yy = yy + hh; bb_btn = _makeButton(content, "plan_progress_bar", "Progress Bar", xx, yy, ww, hh)
		yy = yy + hh; bb_btn = _makeButton(content, "plan_stepper", "Stepper", xx, yy, ww, hh)
		yy = yy + hh; bb_btn = _makeButton(content, "plan_label_test", "Label test", xx, yy, ww, hh)
		yy = yy + hh; bb_btn = _makeButton(content, "plan_drag_box", "Drag Box", xx, yy, ww, hh)
		yy = yy + hh; bb_btn = _makeButton(content, "plan_container_work", "Container work", xx, yy, ww, hh)
		yy = yy + hh; bb_btn = _makeButton(content, "plan_slider_work", "Slider work", xx, yy, ww, hh)
		--yy = yy + hh; bb_btn = _makeButton(content, "", "", xx, yy, ww, hh)
		--yy = yy + hh; bb_btn = _makeButton(content, "", "", xx, yy, ww, hh)
		--yy = yy + hh; bb_btn = _makeButton(content, "", "", xx, yy, ww, hh)

--[=====[


--]=====]

	end

	frame:reshape(true)
	frame:center(true, true)

	frame.launch = _frame_launchFrame

	return frame
end


return plan
