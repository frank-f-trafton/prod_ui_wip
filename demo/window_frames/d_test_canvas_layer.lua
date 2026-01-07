
local plan = {}


function plan.makeWindowFrame(root)
	local frame = root.context.root:newWindowFrame()
	frame.w = 300
	frame.h = 300
	frame:setFrameTitle("Canvas Layering Test")

	frame:layoutSetBase("viewport-width")
	frame:containerSetScrollRangeMode("zero")
	frame:setScrollBars(false, false)

	frame.ly_enabled = true

	frame.ly_r = 1
	frame.ly_g = 1
	frame.ly_b = 1
	frame.ly_a = 0.5

	frame.ly_x = 0
	frame.ly_y = 0
	frame.ly_angle = 0
	frame.ly_sx = 1
	frame.ly_sy = 1
	frame.ly_ox = 0
	frame.ly_oy = 0
	frame.ly_kx = 0
	frame.ly_ky = 0

	--[[
	frame.ly_use_quad = true
	frame.ly_qx = 32
	frame.ly_qy = 32
	frame.ly_qw = 256
	frame.ly_qh = 256
	--]]

	frame.ly_blend_mode = "alpha"

	frame.usr_time = 0.0

	frame:userCallbackSet("cb_update", function(self, dt)

		--[[
		self.ly_x = self.w/2
		self.ly_y = self.h/2
		self.ly_ox = self.w/2
		self.ly_oy = self.h/2
		self.ly_angle = self.ly_angle + dt
		--]]
		self.usr_time = self.usr_time + dt
		self.ly_a = 0.5 + math.sin(self.usr_time) / 2
		--self.ly_sx = self.usr_time / 10
	end)

	frame:reshape()
	frame:center(true, true)

	return frame
end


return plan
