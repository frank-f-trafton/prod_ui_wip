local wimpWorks = {}


local uiShared = require("prod_ui.ui_shared")


function wimpWorks.makeDialogBox(context, title, text, b1, b2, b3)
	uiShared.type1(2, title, "string")
	uiShared.type1(3, text, "string")
	uiShared.typeEval1(4, b1, "string")
	uiShared.typeEval1(5, b2, "string")
	uiShared.typeEval1(6, b3, "string")

	local root = context.root

	local dialog = root:newWindowFrame()
	dialog.w = 448
	dialog.h = 256
	dialog:initialize()

	dialog:setResizable(false)
	dialog:setMaximizeControlVisibility(false)
	dialog:setCloseControlVisibility(true)

	dialog:setFrameTitle(title)

	dialog:setLayoutBase("viewport")
	dialog:setScrollRangeMode("zero")
	dialog:setScrollBars(false, false)


	root:sendEvent("rootCall_setModalFrame", dialog)


	local text_block = dialog:addChild("wimp/text_block")
	text_block:initialize()

	local nt = dialog.layout_tree:newNode()
	nt:setMode("slice", "px", "top", 32)
	dialog:setLayoutNode(text_block, nt)

	text_block:setAutoSize("v")
	text_block:setWrapping(true)
	text_block:setFontID("p")
	text_block:setText(text)

	local node_buttons = dialog.layout_tree:newNode()
	node_buttons:setMode("slice", "px", "bottom", 64)

	local node_button1 = node_buttons:newNode()
	node_button1:setMode("slice", "px", "left", 160)

	local node_button2 = node_buttons:newNode()
	node_button2:setMode("slice", "px", "right", 160)

	local btn_w, btn_h = 96, 32

	local button_y = dialog:addChild("base/button")
	button_y:initialize()
	dialog:setLayoutNode(button_y, node_button2)

	button_y:setLabel("Yes")
	button_y.wid_buttonAction = function(self)
		self:bubbleEvent("frameCall_close", true)
	end

	local button_n = dialog:addChild("base/button")
	button_n:initialize()
	dialog:setLayoutNode(button_n, node_button1)

	button_n:setLabel("No")
	button_n.wid_buttonAction = function(self)
		self:bubbleEvent("frameCall_close", true)
	end

	dialog:center(true, true)

	root:setSelectedFrame(dialog)

	local try_host = dialog:getOpenThimbleDepthFirst()
	if try_host then
		try_host:takeThimble1()
	end

	dialog:reshape()

	local nb1 = node_button1
	print("node_button1 xywh:", nb1.x, nb1.y, nb1.w, nb1.h)

	return dialog
end


return wimpWorks