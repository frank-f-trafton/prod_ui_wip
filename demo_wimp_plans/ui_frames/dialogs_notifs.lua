local plan = {}


-- WIMP Demo
local demoShared = require("demo_shared")


local function _makeFrameBlock2(self)
	local root = self:getRootWidget()
	local frame, dialog
	frame = demoShared.getUIFrame(self)

	if frame then
		dialog = root:newWindowFrame()
		dialog.w = 448
		dialog.h = 256
		dialog:setScrollRangeMode("zero")
		dialog:setScrollBars(false, false)
		dialog:setFrameBlock(frame)
		dialog:setFrameTitle("The Frame That Blocks")

		demoShared.makeParagraph(dialog, nil, [[
This Window Frame should block interaction with the UI Frame that invoked it, until it is dismissed. Other elements ought to remain accessible.]])


		local button_close = dialog:addChild("base/button")
		button_close.x = 32
		button_close.y = dialog.h - 72
		button_close.w = 160
		button_close.h = 32
		button_close:setLabel("All right, close it")
		button_close.wid_buttonAction = function(self)
			self:bubbleEvent("frameCall_close", true)
		end

		dialog:center(true, true)

		-- hack: move the second window a bit
		dialog.x = dialog.x + 32
		dialog.y = dialog.y + 32

		local root = dialog:getRootWidget()
		root:setSelectedFrame(dialog)

		local try_host = dialog:getOpenThimble1DepthFirst()
		if try_host then
			try_host:takeThimble1()
		end

		dialog:reshape()
	end
end


local function _makeFrameBlock1(self)
	local root = self:getRootWidget()
	local frame, dialog
	frame = demoShared.getUIFrame(self)

	if frame then
		dialog = root:newWindowFrame()
		dialog.w = 448
		dialog.h = 256
		dialog:setScrollRangeMode("zero")
		dialog:setScrollBars(false, false)
		dialog:setFrameTitle("The Frame That Is Blocked")

		demoShared.makeParagraph(dialog, nil, [[
Click the button to make a blocking UI Frame.
]])


		local button_make = dialog:addChild("base/button")
		button_make.x = 32
		button_make.y = dialog.h - 72
		button_make.w = 160
		button_make.h = 32
		button_make:setLabel("Make blocking frame")
		button_make.wid_buttonAction = function(self)
			_makeFrameBlock2(self)
		end

		dialog:center(true, true)
		local root = dialog:getRootWidget()
		root:setSelectedFrame(dialog)

		local try_host = dialog:getOpenThimble1DepthFirst()
		if try_host then
			try_host:takeThimble1()
		end

		dialog:reshape()
	end
end


function plan.make(panel)
	panel:layoutSetBase("viewport-width")
	panel:setScrollRangeMode("zero")
	panel:setScrollBars(false, false)

	demoShared.makeTitle(panel, nil, "Dialogs and Notifications")

	panel.DEBUG = "dimensions" -- XXX: see base/container.lua

	-- (Modal) Dialog box test
	do
		local btn = panel:addChild("base/button")
		btn:geometrySetMode("static", 64, 64, 160, 28)
		btn:setLabel("Modal Dialog Box")
		btn.wid_buttonAction = function(self)
			demoShared.makeDialogBox(panel.context, "It's a dialog box", [[
This frame is modal; while present, it should block interaction with any other part of the interface.

Click a button below (or the 'X' in the header bar) to dismiss it.]]
)
		end
	end

	-- Frame-blocking test
	do
		local btn = panel:addChild("base/button")
		btn:geometrySetMode("static", 64, 96, 160, 28)
		btn:setLabel("Frame-Blocking Test")
		btn.wid_buttonAction = function(self)
			_makeFrameBlock1(self)
		end
	end


	-- Toast/Notification WIP
	do
		local button_quote = panel:addChild("base/button")
		button_quote:geometrySetMode("static", 128, 128, 96, 28)
		button_quote:setLabel("Inspiration")
		button_quote.str_tool_tip = "Click for an inspiring quote."

		button_quote.wid_buttonAction = function(self)
			local frame = demoShared.getUIFrame(self)
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
