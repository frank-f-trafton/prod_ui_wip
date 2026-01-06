
local plan = {}


-- ProdUI
local demoShared = require("demo_shared")


function plan.makeWindowFrame(root)
	local frame = root:newWindowFrame()
	frame.w = 640
	frame.h = 480
	frame:setFrameTitle("Hiding Window Frames")

	frame:layoutSetBase("viewport-width")
	frame:containerSetScrollRangeMode("auto")
	frame:setScrollBars(false, true)

	local xx, yy, ww, hh = 16, 16, 192, 32


	-- Button: Hide this frame
	do
		local btn = frame:addChild("base/button")
		btn:geometrySetMode("static", xx, yy, 250, hh)

		btn.usr_time = 0.0
		btn.usr_time_max = 5.0
		btn:setLabel("Hide for " .. btn.usr_time_max .. " seconds")
		btn:userCallbackSet("cb_buttonAction", function(self)
			local frame = self:nodeFindKeyAscending(true, "frame_type", "window")
			if frame then
				frame:setFrameHidden(true)
				self.usr_time = self.usr_time_max
			end
		end)

		local function _asyncUnhide(frame, params, dt)
			frame:setFrameHidden(false)
			frame:bringWindowToFront()
			frame.context.root:setSelectedFrame(frame)
		end

		btn.userUpdate = function(self, dt)
			if self.usr_time > 0 then
				self.usr_time = self.usr_time - dt
				if self.usr_time <= 0 then
					self.context:appendAsyncAction(frame, _asyncUnhide)
				end
			end
		end

		yy = yy + hh
	end

	frame:reshape()
	frame:center(true, true)

	return frame
end


return plan
