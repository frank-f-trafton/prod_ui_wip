
local plan = {}


local uiRes = require("prod_ui.ui_res")


local function makeLabel(frame, x, y, w, h, text, label_mode)
	label_mode = label_mode or "single"

	local label = frame:addChild("base/label")
	label.x, label.y, label.w, label.h = x, y, w, h
	label:initialize()
	label:setLabel(text, label_mode)

	return label
end


local function _launchFrame(self, plan_name)
	local root = self:getRootWidget()
	-- If the frame already exists, just switch to it.
	local frame = root:findTag("FRAME:" .. plan_name)
	if not frame then
		local plan = uiRes.loadLuaFile("demo_wimp_plans/" .. plan_name .. ".lua")
		frame = plan.make(root)
		frame.tag = "FRAME:" .. plan_name
	end

	if frame.frame_is_selectable and not frame.frame_hidden then
		root:setSelectedFrame(frame, true)
	end

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


function plan.make(root)
	local context = root.context

	local frame = root:newWindowFrame()
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
	yy = yy + hh; bb_btn = _makeButton(frame, "demo_main", "Main Demo Window", xx, yy, ww, hh)
	yy = yy + hh

	yy = yy + hh; bb_btn = _makeButton(frame, "wimp_sash", "Sashes", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "number_box", "Number Box", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "properties_box", "Properties Box", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "combo_box", "Combo Box", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "dropdown_box", "Dropdown Box", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "text_box_single", "Textbox (Single-Line)", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "text_box_multi", "Textbox (Multi-Line)", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "button_skinners", "Button Skinners", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "barebones", "Barebones Widgets", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "wimp_tree_box", "Tree Box", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "wimp_list_box", "List Box", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "button_work", "Button work", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "button_split", "Split Button", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "progress_bar", "Progress Bar", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "stepper", "Stepper", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "label_test", "Label test", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "drag_box", "Drag Box", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "container_work", "Container work", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "slider_work", "Slider work", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "dial", "Dials", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "wimp_menu_tab", "Tabular Menu", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "wimp_file_select", "File Selector", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "wimp_g_list", "List of Globals", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "test_destroy_frame_from_user_update", "Test: Destroy Frame from userUpdate()", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "menu_test", "Menu Test", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "wimp_widget_tree", "Widget Tree View", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "wimp_frame", "WIMP Window Frame", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "test_canvas_layer", "Canvas Layering Test", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "frame_unselectable", "Unselectable Window Frame", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "wimp_workspaces", "Workspace Frames", xx, yy, ww, hh)
	yy = yy + hh; bb_btn = _makeButton(frame, "hidden_frame", "Hiding Window Frames", xx, yy, ww, hh)

	-- To launch a frame from the main demo file: frame:launch("path.to.file")
	frame.launch = _launchFrame

	frame:reshape(true)
	frame:center(true, true)

	return frame
end


return plan
