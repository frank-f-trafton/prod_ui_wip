
local plan = {}


local commonWimp = require("prod_ui.common.common_wimp")


function plan.make(root)
	local context = root.context

	local frame = root:newWindowFrame()
	frame.w = 640
	frame.h = 480
	frame:initialize()
	frame:setFrameTitle("Hiding Window Frames")
	frame.auto_layout = true
	frame:setScrollBars(false, true)

	local xx, yy, ww, hh = 16, 16, 192, 32


	-- Button: Hide this frame
	do
		local btn = frame:addChild("base/button")
		btn.x = xx
		btn.y = yy
		btn.w = 250
		btn.h = hh
		btn:initialize()
		btn.usr_time = 0.0
		btn.usr_time_max = 5.0
		btn:setLabel("Hide for " .. btn.usr_time_max .. " seconds")
		btn.wid_buttonAction = function(self)
			local frame = self:findAscendingKeyValue("frame_type", "window")
			if frame then
				frame:setFrameHidden(true)
				self.usr_time = self.usr_time_max
			end
		end

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

	frame:reshape(true)
	frame:center(true, true)

	return frame
end


return plan
