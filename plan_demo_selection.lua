
local plan = {}


local function makeLabel(frame, x, y, w, h, text, label_mode)
	label_mode = label_mode or "single"

	local label = frame:addChild("base/label")
	label.x, label.y, label.w, label.h = x, y, w, h
	label:initialize()
	label:setLabel(text, label_mode)

	return label
end


local function _launchFrame(self, req_path)
	local plan = require(req_path)
	local root = self:getRootWidget()
	local frame = plan.make(root)

	root:setSelectedFrame(frame, true)

	return frame
end


local function _button_launchFrame(self)
	if type(self.usr_plan) ~= "string" then error("bad type or missing plan ID to launch") end
	return _launchFrame(self, self.usr_plan)
end


local function _makeButton(frame, id, label, x, y, w, h)
	assert(type(id) == "string")
	assert(type(label) == "string")

	local bb_btn = frame:addChild("barebones/button")
	bb_btn.x = x
	bb_btn.y = y
	bb_btn.w = w
	bb_btn.h = h
	bb_btn.wid_buttonAction = _button_launchFrame
	bb_btn:initialize()
	bb_btn:setLabel(label)
	bb_btn.usr_plan = id
	return bb_btn
end


function plan.make(parent)
	local context = parent.context

	local frame = parent:addChild("wimp/window_frame")
	frame.w = 640
	frame.h = 480
	frame:initialize()

	frame:setFrameTitle("Plan launcher")

	frame.auto_layout = true

	frame:setScrollBars(false, true)

	local xx, yy, ww, hh = 0, 0, 256, 40

	local bb_btn

	bb_btn = frame:addChild("barebones/button")
	bb_btn.x = xx
	bb_btn.y = yy
	bb_btn.w = ww
	bb_btn.h = hh
	bb_btn:initialize()
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
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_demo_main", "Main Demo Window", xx, yy, ww, hh)
	yy = yy + hh

	yy = yy + hh; bb_btn = _makeButton(frame, "plan_wimp_sash", "Sashes", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_number_box", "Number Box", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_properties_box", "Properties Box", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_combo_box", "Combo Box", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_dropdown_box", "Dropdown Box", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_text_box_single", "Textbox (Single-Line)", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_text_box_multi", "Textbox (Multi-Line)", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_button_skinners", "Button Skinners", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_barebones", "Barebones Widgets", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_wimp_tree_box", "Tree Box", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_wimp_list_box", "List Box", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_button_work", "Button work", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_button_split", "Split Button", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_progress_bar", "Progress Bar", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_stepper", "Stepper", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_label_test", "Label test", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_drag_box", "Drag Box", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_container_work", "Container work", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_slider_work", "Slider work", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_dial", "Dials", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_wimp_menu_tab", "Tabular Menu", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_wimp_file_select", "File Selector", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_wimp_g_list", "List of Globals", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_test_destroy_frame_from_user_update", "Test: Destroy Frame from userUpdate()", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_menu_test", "Menu Test", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_wimp_widget_tree", "Widget Tree View", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_wimp_frame", "WIMP Window Frame", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "plan_test_canvas_layer", "Canvas Layering Test", xx, yy, ww, hh)

	-- To launch a frame from the main demo file: frame:launch("path.to.file")
	frame.launch = _launchFrame

	frame:reshape(true)
	frame:center(true, true)

	return frame
end


return plan
