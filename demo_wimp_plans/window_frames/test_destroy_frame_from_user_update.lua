local plan = {}


local demoShared = require("demo_shared")


function plan.makeWindowFrame(root)
	local context = root.context
	local frame = root:newWindowFrame()
	frame.w, frame.h = 300, 300
	frame:setFrameTitle("Frame Destroy Test")

	frame:setLayoutBase("viewport-width")
	frame:setScrollRangeMode("zero")
	frame:setScrollBars(false, false)

	local bb_lbl = frame:addChild("barebones/label")
	bb_lbl.x = 0
	bb_lbl.y = 0
	bb_lbl.w = 256
	bb_lbl.h = 192
	demoShared.setStaticLayout(frame, bb_lbl, 0, 0, 256, 192)
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
			local lgcWimp = self.context:getLua("shared/lgc_wimp")
			lgcWimp.closeFrame(self)
			return true
		end
	end

	frame:reshape()
	frame:center(true, true)

	return frame
end


return plan
