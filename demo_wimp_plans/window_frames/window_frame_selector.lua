
-- ProdUI
local uiLayout = require("prod_ui.ui_layout")


-- Demo-specific modules
local demoShared = require("demo_shared")


local plan = {}


local function _button_launchFrame(self)
	if type(self.usr_plan) ~= "string" then error("bad type or missing plan ID to launch") end

	return demoShared.launchWindowFrameFromPlan(self.context.root, self.usr_plan, true)
end


local function _makeButton(frame, id, label, x, y, w, h)
	assert(type(id) == "string")
	assert(type(label) == "string")

	local bb_btn = frame:addChild("base/button")
	bb_btn.x = x
	bb_btn.y = y
	bb_btn.w = w
	bb_btn.h = h
	bb_btn.wid_buttonAction = _button_launchFrame
	bb_btn:initialize()
	bb_btn:register("static")
	bb_btn:setLabel(label)
	bb_btn.usr_plan = id
	return bb_btn
end


function plan.makeWindowFrame(root)
	local xx, yy, ww, hh = 0, 0, 256, 40

	local frame = root:newWindowFrame()
	frame.w = ww + 18 -- TODO: account for scroll bar width...
	frame.h = 480
	frame:initialize()
	frame:setFrameTitle("Window Frame Selector")
	frame:setScrollBars(false, true)


	local bb_btn

	bb_btn = frame:addChild("base/button")
	bb_btn.x = xx
	bb_btn.y = yy
	bb_btn.w = ww
	bb_btn.h = hh
	bb_btn:initialize()
	bb_btn:register("static")
	bb_btn:setLabel("Open all")
	bb_btn.wid_buttonAction = function(self)
		local siblings = self:getParent().children
		for i, sib in ipairs(siblings) do
			if sib ~= self and type(sib.usr_plan) == "string" then
				_button_launchFrame(sib)
			end
		end
	end

	yy = yy + hh
	--[[ ]] yy = yy + hh; bb_btn = _makeButton(frame, "window_frames.wimp_menu_tab", "Tabular Menu", xx, yy, ww, hh)
	--[[ ]] yy = yy + hh; bb_btn = _makeButton(frame, "window_frames.wimp_file_select", "File Selector", xx, yy, ww, hh)
	--[[ ]] yy = yy + hh; bb_btn = _makeButton(frame, "window_frames.wimp_g_list", "List of Globals", xx, yy, ww, hh)
	--[[ ]] yy = yy + hh; bb_btn = _makeButton(frame, "window_frames.test_destroy_frame_from_user_update", "Test: destroy in userUpdate()", xx, yy, ww, hh)
	--[[ ]] yy = yy + hh; bb_btn = _makeButton(frame, "window_frames.wimp_frame", "WIMP Window Frame", xx, yy, ww, hh)
	--[[ ]] yy = yy + hh; bb_btn = _makeButton(frame, "window_frames.test_canvas_layer", "Canvas Layering Test", xx, yy, ww, hh)
	--[[ ]] yy = yy + hh; bb_btn = _makeButton(frame, "window_frames.frame_unselectable", "Unselectable Window Frame", xx, yy, ww, hh)
	--[[ ]] yy = yy + hh; bb_btn = _makeButton(frame, "window_frames.hidden_frame", "Hiding Window Frames", xx, yy, ww, hh)

	frame:reshape()
	frame:center(true, true)

	return frame
end


return plan
