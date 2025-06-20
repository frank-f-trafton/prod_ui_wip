local demoShared = {}


local pTable = require("prod_ui.lib.pile_table")
local uiRes = require("prod_ui.ui_res")
local uiShared = require("prod_ui.ui_shared")


local function _openURL(self)
	assert(self.url, "no URL specified.")
	love.system.openURL(self.url)
	-- TODO: 'love.system.openURL' returns false when the URL couldn't be opened. Maybe this could be noted in an error log?
end


function demoShared.loadTheme()
	local theme = uiRes.loadDirectoryAsTable("prod_ui/theme")

	-- Duplicate skins so that demo widgets can be tweaked without
	-- affecting the rest of the program.
	if theme.skins then
		local dupes = {}
		for k, v in pairs(theme.skins) do
			dupes[k .. "_DEMO"] = pTable.deepCopy(v)
		end
		for k, v in pairs(dupes) do
			theme.skins[k] = v
		end
	end

	return theme
end


-- @return true on successful change, nil if the scale and dpi are not different from existing values, false if the
--	change failed.
function demoShared.executeThemeUpdate(context, scale, dpi)
	-- A dirty hack to prevent attempting (and failing) to load non-existent sets of textures.
	-- TODO: Probably need to declare valid DPI numbers somewhere.
	local tex_dir = love.filesystem.getInfo(context.conf.prod_ui_path .. "resources/textures/" .. tostring(dpi), "directory")
	if not tex_dir then
		return false
	else
		local old_scale, old_dpi = context:getScale(), context:getDPI()
		if not (scale == old_scale and dpi == old_dpi) then
			context:setScale(scale)
			context:setDPI(dpi)

			local theme = demoShared.loadTheme()

			context.root:forEach(function(self) if self.skinner then self:skinRemove() end end)
			context:applyTheme(theme)
			context.root:forEach(function(self) if self.skinner then self:skinSetRefs(); self:skinInstall() end end)
			context.root:reshape()

			return true
		end
	end
end


function demoShared.launchWindowFrameFromPlan(root, plan_id, switch_to)
	-- If the frame already exists, just switch to it.
	local frame = root:findTag("FRAME:" .. plan_id)
	if not frame then
		local planWindowFrame = require("demo_wimp_plans." .. plan_id)
		frame = planWindowFrame.makeWindowFrame(root)
		frame.tag = "FRAME:" .. plan_id
	end

	if switch_to and frame.frame_is_selectable and not frame.frame_hidden then
		root:setSelectedFrame(frame, true)
	end

	return frame
end


function demoShared.makeTitle(self, tag, text)
	local text_block = self:addChild("wimp/text_block")
	text_block:initialize()
	if tag then
		text_block.tag = tag
	end

	local node = self.layout_tree:newNode()
	node:setMode("slice", "px", "top", 32)
	self:setLayoutNode(text_block, node)

	text_block:setAutoSize("v")
	text_block:setFontID("h1")
	text_block:setText(text)

	return text_block
end


function demoShared.makeParagraph(self, tag, text)
	local text_block = self:addChild("wimp/text_block")
	text_block:initialize()
	if tag then
		text_block.tag = tag
	end

	local node = self.layout_tree:newNode()
	node:setMode("slice", "px", "top", 32)
	self:setLayoutNode(text_block, node)

	text_block:setAutoSize("v")
	text_block:setWrapping(true)
	text_block:setFontID("p")
	text_block:setText(text)

	return text_block
end


function demoShared.makeHyperlink(self, tag, text, url)
	local text_block = self:addChild("wimp/text_block")
	text_block:initialize()
	if tag then
		text_block.tag = tag
	end

	local node = self.layout_tree:newNode()
	node:setMode("slice", "px", "top", 32)
	self:setLayoutNode(text_block, node)

	text_block:setAutoSize("v")
	text_block:setWrapping(true)
	text_block:setFontID("p")
	text_block:setText(text)
	text_block:setURL(url)
	text_block.wid_buttonAction = _openURL
	text_block.wid_buttonAction3 = _openURL

	return text_block
end


function demoShared.makeDialogBox(context, title, text, b1, b2, b3)
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


function demoShared.makeLabel(parent, x, y, w, h, text, label_mode)
	label_mode = label_mode or "single"

	local label = parent:addChild("base/label")
	label:initialize()
	demoShared.setStaticLayout(parent, label, x, y, w, h)
	label:setLabel(text, label_mode)

	return label
end


function demoShared.setStaticLayout(parent, child, x, y, w, h)
	local node = parent.layout_tree:newNode()
	node:setMode("static", x, y, w, h)
	parent:setLayoutNode(child, node)

	return node
end


-- Looks up the hierarchy for a UI Frame, starting at this widget.
-- @param self Any descendent of a UI Frame, or the UI Frame itself.
-- @return The UI Frame, or nil if no UI Frame was found.
function demoShared.getUIFrame(self)
	local wid = self
	while wid do
		if wid.frame_type then
			return wid
		end
		wid = wid.parent
	end
end


return demoShared
