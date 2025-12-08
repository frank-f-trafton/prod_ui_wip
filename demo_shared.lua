local demoShared = {}


local pTable = require("prod_ui.lib.pile_table")
local uiAssert = require("prod_ui.ui_assert")
local uiRes = require("prod_ui.ui_res")


local function _openURL(self)
	assert(self.url, "no URL specified.")
	love.system.openURL(self.url)
	-- TODO: 'love.system.openURL' returns false when the URL couldn't be opened. Maybe this could be noted in an error log?
end


function demoShared.loadThemeDuplicateSkins(context, id)
	local theme = context:loadTheme(id)

	-- Duplicate skins so that demo widgets can be tweaked without
	-- affecting the rest of the program.
	if theme.skins then
		local dupes = {}
		for k, v in pairs(theme.skins) do
			if not dupes[k .. "_DEMO"] then
				dupes[k .. "_DEMO"] = pTable.deepCopy(v)
			end
		end
		for k, v in pairs(dupes) do
			theme.skins[k] = v
		end
	end

	return theme
end


local function _unskin(self)
	if self.skinner then
		self:skinRemove()
	end
end


local function _reskin(self)
	if self.skinner then
		self:skinSetRefs()
		self:skinInstall()
	end
end


-- @return true on successful change, nil if the scale and dpi are not different from existing values, false if the
--	change failed.
function demoShared.executeThemeUpdate(context, scale, dpi, id)
	-- A dirty hack to prevent attempting (and failing) to load non-existent sets of textures.
	-- TODO: Probably need to declare valid DPI numbers somewhere.
	local tex_dir = love.filesystem.getInfo(context.conf.prod_ui_path .. "resources/textures/" .. tostring(dpi), "directory")
	if not tex_dir then
		return false
	else
		local old_scale, old_dpi, old_id = context:getScale(), context:getDPI(), context:getThemeID()
		print("id", id, "old_id", old_id)
		if not (scale == old_scale and dpi == old_dpi and id == old_id) then
			context:setScale(scale)
			context:setDPI(dpi)

			local theme = demoShared.loadThemeDuplicateSkins(context, id)

			context.root:nodeForEach(true, _unskin)
			context:applyTheme(theme)
			context.root:nodeForEach(true, _reskin)
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
	if tag then
		text_block.tag = tag
	end

	text_block:setAutoSize("v")
	text_block:setFontID("h1")
	text_block:setText(text)
	text_block:geometrySetMode("segment", "top", 32)

	return text_block
end


function demoShared.makeParagraph(self, tag, text)
	local text_block = self:addChild("wimp/text_block")
	if tag then
		text_block.tag = tag
	end

	text_block:setAutoSize("v")
	text_block:setWrapping(true)
	text_block:setFontID("p")
	text_block:setText(text)
	text_block:geometrySetMode("segment", "top", 32)

	return text_block
end


function demoShared.makeHyperlink(self, tag, text, url)
	local text_block = self:addChild("wimp/text_block")
	if tag then
		text_block.tag = tag
	end

	text_block:setAutoSize("v")
	text_block:setWrapping(true)
	text_block:setFontID("p")
	text_block:setText(text)
	text_block:setURL(url)
	text_block.wid_buttonAction = _openURL
	text_block.wid_buttonAction3 = _openURL
	text_block:geometrySetMode("segment", "top", 32)

	return text_block
end


function demoShared.makeDialogBox(context, title, text, b1, b2, b3)
	uiAssert.type(2, title, "string")
	uiAssert.type(3, text, "string")
	uiAssert.typeEval(4, b1, "string")
	uiAssert.typeEval(5, b2, "string")
	uiAssert.typeEval(6, b3, "string")

	local root = context.root

	local dialog = root:newWindowFrame()
	dialog.w = 448
	dialog.h = 256

	dialog:setResizable(false)
	dialog:setMaximizeControlVisibility(false)
	dialog:setCloseControlVisibility(true)

	dialog:setFrameTitle(title)

	dialog:layoutSetBase("viewport")
	dialog:containerSetScrollRangeMode("zero")
	dialog:setScrollBars(false, false)


	root:setModalFrame(dialog)


	local text_block = dialog:addChild("wimp/text_block")
	text_block:setAutoSize("v")
	text_block:setWrapping(true)
	text_block:setFontID("p")
	text_block:setText(text)
	text_block:geometrySetMode("segment", "top", 32)

	local button_n = dialog:addChild("base/button")
	button_n:setLabel("No")
	button_n.wid_buttonAction = function(self)
		self:getUIFrame():closeFrame(true)
	end
	button_n:geometrySetMode("segment", "left", 160)

	local button_y = dialog:addChild("base/button")
	button_y:setLabel("Yes")
	button_y.wid_buttonAction = function(self)
		self:getUIFrame():closeFrame(true)
	end
	button_y:geometrySetMode("segment", "right", 160)

	local btn_w, btn_h = 96, 32

	dialog:center(true, true)

	root:setSelectedFrame(dialog)

	local try_host = dialog:getOpenThimble1DepthFirst()
	if try_host then
		try_host:takeThimble1()
	end

	dialog:reshape()

	return dialog
end


function demoShared.makeLabel(parent, x, y, w, h, text, label_mode)
	label_mode = label_mode or "single"

	local label = parent:addChild("base/label")
	label:setLabel(text, label_mode)
	label:geometrySetMode("static", x, y, w, h)

	return label
end


return demoShared
