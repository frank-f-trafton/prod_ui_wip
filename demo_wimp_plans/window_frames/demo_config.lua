
-- ProdUI
local uiLayout = require("prod_ui.ui_layout")


-- Demo-specific modules
local demoShared = require("demo_shared")


local plan = {}


function plan.makeWindowFrame(root)
	local context = root.context
	local frame = root:newWindowFrame()
	frame.w = 640
	frame.h = 480
	frame:initialize()
	frame:setFrameTitle("Demo Config")
	frame.auto_layout = true
	frame:setScrollBars(false, true)

	do
		local checkbox = frame:addChild("base/checkbox")
		checkbox.x = 64
		checkbox.y = 160
		checkbox.w = 192
		checkbox.h = 32
		checkbox:initialize()
		checkbox:register("static")
		checkbox.tag = "wimp-demo-show-state-details"
		checkbox.checked = not not context.app.show_details
		checkbox.bijou_side = "right"
		checkbox:setLabel("Show state details")

		checkbox.wid_buttonAction = function(self)
			local app = self.context.app
			app.show_details = not not self.checked
		end
	end

	do
		local checkbox = frame:addChild("base/checkbox")
		checkbox.x = 64
		checkbox.y = 192
		checkbox.w = 192
		checkbox.h = 32
		checkbox:initialize()
		checkbox:register("static")
		checkbox.tag = "wimp-demo-show-perf"
		checkbox.checked = not not context.app.show_perf
		checkbox.bijou_side = "right"
		checkbox:setLabel("Show perf info")

		checkbox.wid_buttonAction = function(self)
			local app = self.context.app
			app.show_perf = not not self.checked
		end
	end

	do
		local checkbox = frame:addChild("base/checkbox")
		checkbox.x = 64
		checkbox.y = 224
		checkbox.w = 192
		checkbox.h = 32
		checkbox:initialize()
		checkbox:register("static")
		checkbox.tag = "wimp-demo-mouse-cross"
		checkbox.checked = not not context.app.show_mouse_cross
		checkbox.bijou_side = "right"
		checkbox:setLabel("Show cross at mouse location")

		checkbox.wid_buttonAction = function(self)
			local app = self.context.app
			app.show_mouse_cross = not not self.checked
		end
	end

	do
		-- Note on VSync: adaptive (-1) and per-frame (2+) may not be supported by graphics drivers.
		-- Additionally, it's possible for the user and/or video drivers to override VSync settings.
		local current_vsync = love.window.getVSync()

		local yy, hh = 292, 32

		local text_vsync = frame:addChild("base/text")
		text_vsync.font = context.resources.fonts.p
		text_vsync:initialize()
		text_vsync:register("static")
		text_vsync.text = "VSync Mode"
		text_vsync.x = 64 + 9 -- XXX work on syncing padding with embedded widget labels
		text_vsync.y = yy
		text_vsync:refreshText()

		local r_action = function(self)
			-- https://love2d.org/wiki/love.window.setVSync
			love.window.setVSync(self.usr_vsync_mode)
		end

		local rad_btn

		yy=yy+hh
		rad_btn = frame:addChild("base/radio_button")
		rad_btn.x = 64
		rad_btn.y = yy
		rad_btn.w = 192
		rad_btn.h = hh
		rad_btn:initialize()
		rad_btn:register("static")
		rad_btn.checked = false
		rad_btn.bijou_side = "right"
		rad_btn.radio_group = "rg_vsync"
		rad_btn:setLabel("On")
		rad_btn.usr_vsync_mode = 1
		rad_btn.wid_buttonAction = r_action
		if current_vsync == rad_btn.usr_vsync_mode then
			rad_btn:setChecked(true)
		end

		yy=yy+hh
		rad_btn = frame:addChild("base/radio_button")
		rad_btn.x = 64
		rad_btn.y = yy
		rad_btn.w = 192
		rad_btn.h = hh
		rad_btn:initialize()
		rad_btn:register("static")
		rad_btn.checked = false
		rad_btn.bijou_side = "right"
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
		rad_btn.x = 64
		rad_btn.y = yy
		rad_btn.w = 192
		rad_btn.h = hh
		rad_btn:initialize()
		rad_btn:register("static")
		rad_btn.checked = false
		rad_btn.bijou_side = "right"
		rad_btn.radio_group = "rg_vsync"
		rad_btn:setLabel("Half")
		rad_btn.usr_vsync_mode = 2
		rad_btn.wid_buttonAction = r_action
		if current_vsync == rad_btn.usr_vsync_mode then
			rad_btn:setChecked(true)
		end

		yy=yy+hh
		rad_btn = frame:addChild("base/radio_button")
		rad_btn.x = 64
		rad_btn.y = yy
		rad_btn.w = 192
		rad_btn.h = hh
		rad_btn:initialize()
		rad_btn:register("static")
		rad_btn.checked = false
		rad_btn.bijou_side = "right"
		rad_btn.radio_group = "rg_vsync"
		rad_btn:setLabel("Third")
		rad_btn.usr_vsync_mode = 3
		rad_btn.wid_buttonAction = r_action
		if current_vsync == rad_btn.usr_vsync_mode then
			rad_btn:setChecked(true)
		end

		yy=yy+hh
		rad_btn = frame:addChild("base/radio_button")
		rad_btn.x = 64
		rad_btn.y = yy
		rad_btn.w = 192
		rad_btn.h = hh
		rad_btn:initialize()
		rad_btn:register("static")
		rad_btn.checked = false
		rad_btn.bijou_side = "right"
		rad_btn.radio_group = "rg_vsync"
		rad_btn:setLabel("Off")
		rad_btn.usr_vsync_mode = 0
		rad_btn.wid_buttonAction = r_action
		if current_vsync == rad_btn.usr_vsync_mode then
			rad_btn:setChecked(true)
		end
	end

	frame:reshape()
	frame:center(true, true)

	return frame
end


return plan
