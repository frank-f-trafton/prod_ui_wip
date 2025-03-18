local demoShared = {}


local uiShared = require("prod_ui.ui_shared")


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


function demoShared.makeLabel(parent, x, y, w, h, text, label_mode)
	label_mode = label_mode or "single"

	local label = parent:addChild("base/label")
	label.x, label.y, label.w, label.h = x, y, w, h
	label:initialize()
	label:register("static")
	label:setLabel(text, label_mode)

	return label
end


local function _openURL(self)
	assert(self.url, "no URL specified.")
	love.system.openURL(self.url)
	-- TODO: 'love.system.openURL' returns false when the URL couldn't be opened. Maybe this could be note in an error log?
end


function demoShared.makeTitle(self, tag, text)
	local text_block = self:addChild("wimp/text_block")
	text_block:initialize()
	if tag then
		text_block.tag = tag
	end
	text_block:register("fit-top")
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
	text_block:register("fit-top")
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
	text_block:register("fit-top")
	text_block:setAutoSize("v")
	text_block:setWrapping(true)
	text_block:setFontID("p")
	text_block:setText(text)
	text_block:setURL(url)
	text_block.wid_buttonAction = _openURL
	text_block.wid_buttonAction3 = _openURL

	return text_block
end


return demoShared
