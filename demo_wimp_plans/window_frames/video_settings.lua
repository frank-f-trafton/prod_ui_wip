local plan = {}


-- WIMP Demo
local demoShared = require("demo_shared")


function plan.makeWindowFrame(root)
	local context = root.context
	local frame = root:newWindowFrame()
	frame.w = 640
	frame.h = 480
	frame:setFrameTitle("Video Settings")

	frame:setLayoutBase("viewport-width")
	frame:setScrollRangeMode("auto")
	frame:setScrollBars(false, true)

	do
		-- Note on VSync: adaptive (-1) and per-frame (2+) may not be supported by graphics drivers.
		-- Additionally, it's possible for the user and/or video drivers to override VSync settings.
		local current_vsync = love.window.getVSync()

		local yy, hh = 32, 32

		local text_vsync = frame:addChild("wimp/text_block")
		-- XXX work on syncing padding with embedded widget labels
		demoShared.setStaticLayout(frame, text_vsync, 64 + 9, yy, 192, hh)
		text_vsync:setText("VSync Mode")


		local r_action = function(self)
			-- https://love2d.org/wiki/love.window.setVSync
			love.window.setVSync(self.usr_vsync_mode)
		end

		local rad_btn

		yy=yy+hh
		rad_btn = frame:addChild("base/radio_button")
		demoShared.setStaticLayout(frame, rad_btn, 64, yy, 192, hh)
		rad_btn.checked = false
		rad_btn.radio_group = "rg_vsync"
		rad_btn:setLabel("On")
		rad_btn.usr_vsync_mode = 1
		rad_btn.wid_buttonAction = r_action
		if current_vsync == rad_btn.usr_vsync_mode then
			rad_btn:setChecked(true)
		end

		yy=yy+hh
		rad_btn = frame:addChild("base/radio_button")
		demoShared.setStaticLayout(frame, rad_btn, 64, yy, 192, hh)
		rad_btn.checked = false
		rad_btn.radio_group = "rg_vsync"
		rad_btn:setLabel("Adaptive")
		rad_btn.usr_vsync_mode = -1
		rad_btn.wid_buttonAction = r_action
		if current_vsync == rad_btn.usr_vsync_mode then
			rad_btn:setChecked(true)
		end

		-- A VSync number of 2 or larger will wait that many frames before syncing.
		yy=yy+hh
		rad_btn = frame:addChild("base/radio_button")
		demoShared.setStaticLayout(frame, rad_btn, 64, yy, 192, hh)
		rad_btn.checked = false
		rad_btn.radio_group = "rg_vsync"
		rad_btn:setLabel("Half")
		rad_btn.usr_vsync_mode = 2
		rad_btn.wid_buttonAction = r_action
		if current_vsync == rad_btn.usr_vsync_mode then
			rad_btn:setChecked(true)
		end

		yy=yy+hh
		rad_btn = frame:addChild("base/radio_button")
		demoShared.setStaticLayout(frame, rad_btn, 64, yy, 192, hh)
		rad_btn.checked = false
		rad_btn.radio_group = "rg_vsync"
		rad_btn:setLabel("Third")
		rad_btn.usr_vsync_mode = 3
		rad_btn.wid_buttonAction = r_action
		if current_vsync == rad_btn.usr_vsync_mode then
			rad_btn:setChecked(true)
		end

		yy=yy+hh
		rad_btn = frame:addChild("base/radio_button")
		demoShared.setStaticLayout(frame, rad_btn, 64, yy, 192, hh)
		rad_btn.checked = false
		rad_btn.radio_group = "rg_vsync"
		rad_btn:setLabel("Off")
		rad_btn.usr_vsync_mode = 0
		rad_btn.wid_buttonAction = r_action
		if current_vsync == rad_btn.usr_vsync_mode then
			rad_btn:setChecked(true)
		end
	end


	-- TODO: Move these old debug checkboxes.
	--[====[
	do
		local checkbox = frame:addChild("base/checkbox")
		demoShared.setStaticLayout(frame, checkbox, 64, 160, 192, 32)
		checkbox.tag = "wimp-demo-show-state-details"
		checkbox.checked = not not context.app.show_details
		checkbox:setLabel("Show state details")

		checkbox.wid_buttonAction = function(self)
			local app = self.context.app
			app.show_details = not not self.checked
		end
	end

	do
		local checkbox = frame:addChild("base/checkbox")
		demoShared.setStaticLayout(frame, checkbox, 64, 192, 192, 32)
		checkbox.tag = "wimp-demo-show-perf"
		checkbox.checked = not not context.app.show_perf
		checkbox:setLabel("Show perf info")

		checkbox.wid_buttonAction = function(self)
			local app = self.context.app
			app.show_perf = not not self.checked
		end
	end

	do
		local checkbox = frame:addChild("base/checkbox")
		demoShared.setStaticLayout(frame, checkbox, 64, 224, 192, 32)
		checkbox.tag = "wimp-demo-mouse-cross"
		checkbox.checked = not not context.app.show_mouse_cross
		checkbox:setLabel("Show cross at mouse location")

		checkbox.wid_buttonAction = function(self)
			local app = self.context.app
			app.show_mouse_cross = not not self.checked
		end
	end
	--]====]

	frame:reshape()
	frame:center(true, true)

	return frame
end


return plan
