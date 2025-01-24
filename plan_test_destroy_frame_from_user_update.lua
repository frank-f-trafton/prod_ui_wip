
local plan = {}


function plan.make(parent)
	local context = parent.context

	local frame = parent:addChild("wimp/window_frame")
	frame.w, frame.h = 300, 300
	frame:setFrameTitle("Frame Test")

	local content = frame:findTag("frame_content")
	if content then
		content.layout_mode = "resize"

		content:setScrollBars(false, false)

		local bb_lbl = content:addChild("barebones/label", {x=0, y=0, w=256, h=192})
		bb_lbl:setTag("countdown_label")

		frame.usr_time = 0.0
		frame.usr_time_max = 4.0
	end

	frame.userUpdate = function(self, dt)
		self.usr_time = self.usr_time + dt
		local bb_lbl = content:findTag("countdown_label")
		if bb_lbl then
			bb_lbl:setLabel(string.format("This frame will self-destruct, via userUpdate, in %.1f seconds.", self.usr_time_max - self.usr_time))
		end
		if self.usr_time >= self.usr_time_max then
			local commonWimp = require(context.conf.prod_ui_req .. "common.common_wimp")
			commonWimp.closeWindowFrame(self)
			return true
		end
	end

	frame:reshape(true)
	frame:center(true, true)

	return frame
end


return plan
