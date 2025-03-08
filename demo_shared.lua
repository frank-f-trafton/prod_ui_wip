local demoShared = {}


function demoShared.launchWindowFrameFromPlan(root, plan_id, switch_to)
	-- If the frame already exists, just switch to it.
	local frame = root:findTag("FRAME:" .. plan_id)
	if not frame then
		local planWindowFrame = require("demo_wimp_plans." .. plan_id)
		frame = planWindowFrame.makeWindowFrame(root)
		frame.tag = "FRAME:" .. plan_id
	end

	if switch_to and frame.frame_is_selectable and not frame.frame_hidden then
		root:setSelectedFrame(frame, true)
	end

	return frame
end


function demoShared.makeLabel(parent, x, y, w, h, text, label_mode)
	label_mode = label_mode or "single"

	local label = parent:addChild("base/label")
	label.x, label.y, label.w, label.h = x, y, w, h
	label:initialize()
	label:register("static")
	label:setLabel(text, label_mode)

	return label
end


return demoShared
