
local plan = {}


function plan.make(root)
	local context = root.context

	local frame = root:newWindowFrame()
	frame.w, frame.h = 300, 300
	frame:initialize()
	frame:setFrameTitle("Frame Test")
	frame.auto_layout = true
	frame:setScrollBars(false, false)

	local bb_lbl = frame:addChild("barebones/label")
	bb_lbl.x = 0
	bb_lbl.y = 0
	bb_lbl.w = 256
	bb_lbl.h = 192
	bb_lbl:initialize()
	bb_lbl:setTag("countdown_label")

	frame.usr_time = 0.0
	frame.usr_time_max = 4.0

	frame.userUpdate = function(self, dt)
		self.usr_time = self.usr_time + dt
		local bb_lbl = frame:findTag("countdown_label")
		if bb_lbl then
			bb_lbl:setLabel(string.format("This frame will self-destruct, via userUpdate, in %.1f seconds.", self.usr_time_max - self.usr_time))
		end
		if self.usr_time >= self.usr_time_max then
			local commonWimp = require(context.conf.prod_ui_req .. "common.common_wimp")
			commonWimp.closeFrame(self)
			return true
		end
	end

	frame:reshape(true)
	frame:center(true, true)

	return frame
end


return plan
