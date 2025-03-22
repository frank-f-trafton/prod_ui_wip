-- The main / old WIMP demo window.

-- ProdUI
local commonWimp = require("prod_ui.common.common_wimp")


local plan = {
	container_type = "base/container"
}


function plan.make(panel)
	local context = panel.context

	--title("WIMP Demo")
	do
		local text_block = panel:addChild("wimp/text_block")
		text_block:initialize()
		text_block:register("fit-top")
		text_block:setFontID("h1")
		text_block:setText("WIMP Demo")
		text_block:setAutoSize("v")
	end
	do
		local text_block = panel:addChild("wimp/text_block")
		text_block:initialize()
		text_block:register("fit-top")
		text_block:setFontID("p")
		text_block:setText("Test one two three")
		text_block:setAutoSize("v")
	end

	panel:setScrollBars(false, false)

	panel.DEBUG = "dimensions" -- XXX: see base/container.lua

	-- Modal frame test
	do
		local btn = panel:addChild("base/button")
		btn.x = 64
		btn.y = 64
		btn.w = 160
		btn.h = 24
		btn:initialize()
		btn:register("static")
		btn:setLabel("Modal Test")
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
				dialog:reshape()
				dialog:setFrameTitle("Modal Test")

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
				text:register("static")
				text.align = "center"
				text.text = "This frame should block interaction\nwith all other frames until it is dismissed."
				text:refreshText()

				local button_y = dialog:addChild("base/button")
				button_y.x = 32
				button_y.y = dialog.h - 72
				button_y.w = 96
				button_y.h = 32
				button_y:initialize()
				button_y:register("static")
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
				button_n:register("static")
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

	-- Frame-blocking test
	do
		local btn = panel:addChild("base/button")
		btn.x = 64
		btn.y = 96
		btn.w = 160
		btn.h = 24
		btn:initialize()
		btn:register("static")
		btn:setLabel("Frame-Blocking Test")
		btn.wid_buttonAction = function(self)
			local root = self:getRootWidget()

			local frame, dialog
			frame = commonWimp.getFrame(self)

			if frame then
				dialog = root:newWindowFrame()
				dialog.w = 448
				dialog.h = 256
				dialog:initialize()
				dialog:setFrameBlock(frame)
				dialog:reshape()
				dialog:setFrameTitle("Frame-Blocking test")

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
				text:register("static")
				text.align = "center"
				text.text = "This frame should block interaction with the frame\nthat invoked it, until dismissed. Other elements should\nbe accessible."
				text:refreshText()

				local button_y = dialog:addChild("base/button")
				button_y.x = 32
				button_y.y = dialog.h - 72
				button_y.w = 96
				button_y.h = 32
				button_y:initialize()
				button_y:register("static")
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
				button_n:register("static")
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
		local button_close = panel:addChild("base/button")
		button_close.x = 128
		button_close.y = 128
		button_close.w = 96
		button_close.h = 24
		button_close:initialize()
		button_close:register("static")
		button_close:setLabel("Inspiration")
		button_close.str_tool_tip = "Click for an inspiring quote."

		button_close.wid_buttonAction = function(self)
			local frame = commonWimp.getFrame(self)
			if not frame then
				print("Demo Error: frame not found")
			else
				-- XXX hook up to an actual toast system at some point.
				local notif = self.context.app.notif
				-- TODO: get a proper source for this quote.
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
end


return plan
