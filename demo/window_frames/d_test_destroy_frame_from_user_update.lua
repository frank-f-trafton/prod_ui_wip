local plan = {}


local demoShared = require("demo_shared")


function plan.makeWindowFrame(root)
	local context = root.context
	local frame = root:newWindowFrame()
	frame.w, frame.h = 300, 300
	frame:setFrameTitle("Frame Destroy Test")

	--frame:layoutSetBase("viewport-width")
	frame:layoutSetBase("viewport")
	frame:containerSetScrollRangeMode("zero")
	frame:setScrollBars(false, false)

	local bb_lbl = frame:addChild("base/control_label")
		:geometrySetMode("segment-unit", "top", 1.0)
		:setHorizontalAlignment("center")
		:setVerticalAlignment("middle")
		:setWrapMode(true)
		:setTag("countdown_label")

	frame.usr_time = 0.0
	frame.usr_time_max = 4.0

	frame:userCallbackSet("cb_update", function(self, dt)
		self.usr_time = self.usr_time + dt
		local bb_lbl = frame:findTag("countdown_label")
		if bb_lbl then
			bb_lbl:setText(string.format("This frame will self-destruct, via cb_update, in %.1f seconds.", self.usr_time_max - self.usr_time))
		end
		if self.usr_time >= self.usr_time_max then
			local wcWimp = self.context:getLua("shared/wc/wc_wimp")
			wcWimp.closeFrame(self)
			return true
		end
	end)

	frame:reshape()
	frame:center(true, true)

	return frame
end


return plan
