
-- ProdUI
local demoShared = require("demo_shared")


local plan = {}


local function _assertNoThimble(self, inst)
	if self == inst then
		if self.context.thimble1 == self or self.context.thimble2 == self then
			error("this widget should not be capable of holding the thimble.")
		end
	end
end


function plan.makeWindowFrame(root)
	local unselectable = true
	local view_level = "high"
	local frame = root:newWindowFrame(nil, unselectable, view_level)
	frame.w = 320
	frame.h = 380
	frame:setFrameTitle("Unselectable Frame")

	frame:layoutSetBase("viewport-width")
	frame:containerSetScrollRangeMode("auto")
	frame:setScrollBars(false, false)

	frame.userUpdate = function(self, dt)
		if self.context.root.selected_frame == self then
			error("this frame should not be selectable.")
		end
	end
	frame.evt_thimble1Take = _assertNoThimble
	frame.evt_thimble2Take = _assertNoThimble

	demoShared.makeLabel(frame, 0, 0, 320, 190, "This frame can be manipulated with the mouse, but it cannot be selected (among other frames), and its controls should not be capable of taking keyboard focus.", "multi")

	local xx, yy = 0, 200
	local ww, hh = 224, 64

	local bb_button = frame:addChild("base/button")
	bb_button:geometrySetMode("static", xx, yy, ww, hh)

	bb_button.evt_thimble1Take = _assertNoThimble
	bb_button.evt_thimble2Take = _assertNoThimble

	bb_button.thimble_mode = 0

	bb_button:setLabel("Example Button")

	yy = yy + hh

	local bb_cbox = frame:addChild("base/checkbox")
	bb_cbox:geometrySetMode("static", xx, yy, ww, hh)

	bb_cbox.evt_thimble1Take = _assertNoThimble
	bb_cbox.evt_thimble2Take = _assertNoThimble

	bb_cbox.thimble_mode = 0

	bb_cbox:setLabel("Example Checkbox")

	frame:reshape()
	frame:center(true, true)

	return frame
end


return plan
