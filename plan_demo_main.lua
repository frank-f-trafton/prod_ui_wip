-- The main / old WIMP demo window.

-- ProdUI
local commonWimp = require("prod_ui.common.common_wimp")
local uiLayout = require("prod_ui.ui_layout")
local widShared = require("prod_ui.common.wid_shared")


local plan = {}


local function makeLabel(frame, x, y, w, h, text, label_mode)
	label_mode = label_mode or "single"

	local label = frame:addChild("base/label")
	label.x, label.y, label.w, label.h = x, y, w, h
	label:initialize()
	label:setLabel(text, label_mode)

	return label
end


function plan.make(root)
	local context = root.context

	local frame = root:newWindowFrame()
	frame.w = 640
	frame.h = 480
	frame:initialize()
	frame:setFrameTitle("WIMP Demo")
	frame.auto_layout = true
	frame:setScrollBars(false, false)
	frame.DEBUG = "dimensions" -- XXX: see base/container.lua
	frame.w = 640
	frame.h = 550
	frame:reshape(true)
	frame:center(false, true)

	-- Root-modal frame test
	do
		local btn = frame:addChild("base/button")
		btn.x = 64
		btn.y = 64
		btn.w = 160
		btn.h = 24
		btn:initialize()
		btn:setLabel("Root-Modal Test")
		btn.wid_buttonAction = function(self)
			local root = self:getRootWidget()

			local frame, dialog
			frame = commonWimp.getFrame(self)

			if frame then
				dialog = root:newWindowFrame()
				dialog.w = 448
				dialog.h = 256
				dialog:initialize()
				root:sendEvent("rootCall_setModalFrame", dialog)
				dialog:reshape(true)
				dialog:setFrameTitle("Root-Modal Test")

				if dialog.scr_h then
					dialog.scr_h.auto_hide = true
				end
				if dialog.scr_v then
					dialog.scr_v.auto_hide = true
				end

				local text = dialog:addChild("base/text")
				text.font = context.resources.fonts.p
				text.x = 0
				text.y = 32
				text.w = dialog.w
				text.h = 64
				text:initialize()
				text.align = "center"
				text.text = "This frame should block interaction\nwith all other frames until it is dismissed."
				text:refreshText()

				local button_y = dialog:addChild("base/button")
				button_y.x = 32
				button_y.y = dialog.h - 72
				button_y.w = 96
				button_y.h = 32
				button_y:initialize()
				button_y:setLabel("O")
				button_y.wid_buttonAction = function(self)
					self:bubbleEvent("frameCall_close", true)
				end

				local button_n = dialog:addChild("base/button")
				button_n.x = 256
				button_n.y = dialog.h - 72
				button_n.w = 96
				button_n.h = 32
				button_n:initialize()
				button_n:setLabel("K")
				button_n.wid_buttonAction = function(self)
					self:bubbleEvent("frameCall_close", true)
				end

				dialog:center(true, true)
				local root = dialog:getRootWidget()
				root:setSelectedFrame(dialog)

				local try_host = dialog:getOpenThimbleDepthFirst()
				if try_host then
					try_host:takeThimble1()
				end
			end
		end
	end

	-- Frame-modal test
	do
		local btn = frame:addChild("base/button")
		btn.x = 64
		btn.y = 96
		btn.w = 160
		btn.h = 24
		btn:initialize()
		btn:setLabel("Frame-Modal Test")
		btn.wid_buttonAction = function(self)
			local root = self:getRootWidget()

			local frame, dialog
			frame = commonWimp.getFrame(self)

			if frame then
				dialog = root:newWindowFrame()
				dialog.w = 448
				dialog.h = 256
				dialog:initialize()
				dialog:setModal(frame)
				dialog:reshape(true)
				dialog:setFrameTitle("Frame-Modal test")

				if dialog.scr_h then
					dialog.scr_h.auto_hide = true
				end
				if dialog.scr_v then
					dialog.scr_v.auto_hide = true
				end

				local text = dialog:addChild("base/text")
				text.font = context.resources.fonts.p
				text.x = 0
				text.y = 32
				text.w = dialog.w
				text.h = 64
				text:initialize()
				text.align = "center"
				text.text = "This frame should block interaction with the frame\nthat invoked it, until dismissed. Other elements should\nbe accessible."
				text:refreshText()

				local button_y = dialog:addChild("base/button")
				button_y.x = 32
				button_y.y = dialog.h - 72
				button_y.w = 96
				button_y.h = 32
				button_y:initialize()
				button_y:setLabel("O")
				button_y.wid_buttonAction = function(self)
					self:bubbleEvent("frameCall_close", true)
				end

				local button_n = dialog:addChild("base/button")
				button_n.x = 256
				button_n.y = dialog.h - 72
				button_n.w = 96
				button_n.h = 32
				button_n:initialize()
				button_n:setLabel("K")
				button_n.wid_buttonAction = function(self)
					self:bubbleEvent("frameCall_close", true)
				end

				dialog:center(true, true)
				local root = dialog:getRootWidget()
				root:setSelectedFrame(dialog)

				local try_host = dialog:getOpenThimbleDepthFirst()
				if try_host then
					try_host:takeThimble1()
				end
			end
		end
	end


	do
		-- Test pushing a new instance onto the stack
		--[=[
		local root2 = context:addWidget("wimp/root_wimp")
		--context:pushRoot(root2)
		context:setRoot(root2)
		local dialog = root2:newWindowFrame()
		dialog.userDestroy = function(self)
			--self.context:popRoot()
			self.context:setRoot(root)
		end
		dialog:initialize()
		--]=]
	end


	-- Toast/Notification WIP
	do
		local button_close = frame:addChild("base/button")
		button_close.x = 0
		button_close.y = 0
		button_close.w = 96
		button_close.h = 24
		button_close:initialize()
		button_close:setLabel("Inspiration")
		button_close.str_tool_tip = "Click for an inspiring quote."

		button_close.wid_buttonAction = function(self)
			local frame = commonWimp.getFrame(self)
			if not frame then
				print("Demo Error: frame not found")
			else
				-- XXX hook up to an actual toast system at some point.
				local notif = self.context.app.notif
				notif.text = "\
A person who doubts himself is like a man who would enlist in the\
ranks of his enemies and bear arms against himself. He makes his\
failure certain by himself being the first person to be convinced\
of it.\
\
-Alexandre Dumas"
				notif.time = 0.0
			end
		end
	end

	do
		local checkbox = frame:addChild("base/checkbox")
		checkbox.x = 64
		checkbox.y = 160
		checkbox.w = 192
		checkbox.h = 32
		checkbox:initialize()
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
		rad_btn.checked = false
		rad_btn.bijou_side = "right"
		rad_btn.radio_group = "rg_vsync"
		rad_btn:setLabel("Adaptive")
		rad_btn.usr_vsync_mode = -1
		rad_btn.wid_buttonAction = r_action
		if current_vsync == rad_btn.usr_vsync_mode then
			rad_btn:setChecked(true)
		end

		-- 2 or larger will wait that many frames before syncing.
		yy=yy+hh
		rad_btn = frame:addChild("base/radio_button")
		rad_btn.x = 64
		rad_btn.y = yy
		rad_btn.w = 192
		rad_btn.h = hh
		rad_btn:initialize()
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

	frame.w, frame.h = widShared.getChildrenPerimeter(frame)
	frame.doc_w, frame.doc_h = frame.w, frame.h

	frame:reshape(true)
	frame:center(true, true)

	return frame
end

return plan
