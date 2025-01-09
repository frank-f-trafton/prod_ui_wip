-- The main / old WIMP demo window.

-- ProdUI
local commonWimp = require("prod_ui.common.common_wimp")
local uiLayout = require("prod_ui.ui_layout")
local widShared = require("prod_ui.common.wid_shared")


local plan = {}


local function makeLabel(content, x, y, w, h, text, label_mode)
	label_mode = label_mode or "single"

	local label = content:addChild("base/label")
	label.x, label.y, label.w, label.h = x, y, w, h
	label:setLabel(text, label_mode)

	return label
end


function plan.make(parent)
	local context = parent.context

	local frame = parent:addChild("wimp/window_frame")

	frame.w = 640
	frame.h = 480

	frame:setFrameTitle("WIMP Demo")

	local content = frame:findTag("frame_content")
	if content then
		content.layout_mode = "resize"

		content:setScrollBars(false, false)

		content.DEBUG = "dimensions" -- XXX: see base/container.lua

		--local inspect = require("lib.test.inspect")
		--print("inspect frame:", inspect(frame))

		-- Light up the front window.
		-- XXX handle this properly (I guess by routing window creation through a root WIMP widget?)
		do
			local header = frame:findTag("frame_header")

			if header then
				header.selected = true
			end
		end

		frame.w = 640
		frame.h = 550

		frame:reshape(true)
		frame:center(false, true)

		-- Prompt Frame
		do
			local btn = content:addChild("base/button", {x=64, y=64, x=96, h=24})
			btn:setLabel("Prompt")
			btn.wid_buttonAction = function(self)
				local root = self:findTopWidgetInstance()

				-- Test pushing a new instance onto the stack
				--[=[
				local root2 = context:addWidget("wimp/root_wimp")
				--context:pushRoot(root2)
				context:setRoot(root2)
				local dialog = root2:addChild("wimp/window_frame")
				dialog.userDestroy = function(self)
					--self.context:popRoot()
					self.context:setRoot(root)
				end
				--]=]

				-- [==[
				local frame = commonWimp.getFrame(self)
				local header
				if frame then
					header = frame:findTag("frame_header")
				end

				local dialog = root:addChild("wimp/window_frame")

				if frame then

					--[=[
					-- Test frame-modal state.
					dialog:setModal(frame)
					--]=]

					-- Test root-modal state.
					-- [=[
					--dialog.sort_id = 4
					root:runStatement("rootCall_setModalFrame", dialog)
					--]=]
				end
				--]==]

				dialog.w = 320
				dialog.h = 224
				dialog:reshape(true)

				dialog:setFrameTitle("Sure about that?")

				local d_content = dialog:findTag("frame_content")
				if d_content then
					if d_content.scr_h then
						d_content.scr_h.auto_hide = true
					end
					if d_content.scr_v then
						d_content.scr_v.auto_hide = true
					end

					local text = dialog:addChild("base/text", {font = context.resources.fonts.p, x=0, y=32, w=d_content.w, h=64})
					text.align = "center"
					text.text = "Are you sure?"
					text:refreshText()

					local button_y = d_content:addChild("base/button", {x=32, y=d_content.h - 48, w=96, h=32})
					button_y:setLabel("Sure")

					local button_n = d_content:addChild("base/button", {x=256, y=d_content.h - 48, w=96, h=32})
					button_n:setLabel("Unsure")
				end
				dialog:center(true, true)
				local root = dialog:getTopWidgetInstance()
				root:setSelectedFrame(dialog)

				local try_host = dialog:getOpenThimbleDepthFirst()
				if try_host then
					try_host:takeThimble1()
				end
			end
		end

		-- Toast/Notification WIP
		do
			local button_close = content:addChild("base/button", {x=0, y=0, w=96, h=24})
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
			local checkbox = content:addChild("base/checkbox", {x=64, y=160, w=192, h=32})
			checkbox.checked = not not context.app.show_details
			checkbox.bijou_side = "right"
			checkbox:setLabel("Show state details")

			checkbox.wid_buttonAction = function(self)
				local app = self.context.app
				app.show_details = not not self.checked
			end
		end

		do
			local checkbox = content:addChild("base/checkbox",{x=64, y=192, w=192, h=32})
			checkbox.checked = not not context.app.show_perf
			checkbox.bijou_side = "right"
			checkbox:setLabel("Show perf info")

			checkbox.wid_buttonAction = function(self)
				local app = self.context.app
				app.show_perf = not not self.checked
			end
		end

		do
			local checkbox = content:addChild("base/checkbox",{x=64, y=224, w=192, h=32})
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

			local text_vsync = content:addChild("base/text", {font = context.resources.fonts.p})
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
			rad_btn = content:addChild("base/radio_button", {x=64, y=yy, w=192, h=hh})
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
			rad_btn = content:addChild("base/radio_button", {x=64, y=yy, w=192, h=hh})
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
			rad_btn = content:addChild("base/radio_button", {x=64, y=yy, w=192, h=hh})
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
			rad_btn = content:addChild("base/radio_button", {x=64, y=yy, w=192, h=hh})
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
			rad_btn = content:addChild("base/radio_button",{x=64, y=yy, w=192, h=hh})
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

		content.w, content.h = widShared.getChildrenPerimeter(content)
		content.doc_w, content.doc_h = content.w, content.h
	end

	frame:reshape(true)
	frame:center(true, true)

	return frame
end


return plan
