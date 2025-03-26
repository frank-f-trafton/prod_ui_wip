
--[[
	A window frame with a text input box in it.
--]]

-- ProdUI
local commonWimp = require("prod_ui.common.common_wimp")
local itemOps = require("prod_ui.common.item_ops")
local keyMgr = require("prod_ui.lib.key_mgr")


local plan = {
	container_type = "base/container"
}


function plan.make(panel)
	local context = panel.context

	--title("LineEditor Test")

	panel:setScrollBars(false, false)

	local c_bar = panel:addChild("base/container")
	c_bar.h = 64
	c_bar:initialize()
	c_bar:register("fit-top")

	--[[
	local cbox_wrap = c_bar:addChild("base/checkbox")
	cbox_wrap.x = 0
	cbox_wrap.y = 0
	cbox_wrap.w = 160
	cbox_wrap.h = 40
	cbox_wrap:initialize()
	cbox_wrap:setLabel("Wrap Mode (F5)", "single")
	--]]

	local temp_instructions = c_bar:addChild("base/text")
	temp_instructions.font = context.resources.fonts.p
	temp_instructions.x = 0
	temp_instructions.w = 512
	temp_instructions.h = c_bar.h
	temp_instructions:initialize()
	temp_instructions.text = "F5: Wrap Mode\nF6/F7/F8: Align (L, C, R)"
	temp_instructions:refreshText()

	local text_box = panel:addChild("input/text_box_multi")
	text_box.font = context.resources.fonts.p
	text_box.x = 0
	text_box.y = 0
	text_box.w = 400
	text_box.h = 350
	text_box:initialize()
	text_box:register("fit-remaining")
	text_box:setTag("demo_text_box") -- Helps identify the widget from the main demo.
	text_box:setScrollBars(true, true)

	text_box.ghost_text = "Ghost text"

	--text_box.line_ed.allow_line_feed = false
	text_box.line_ed.allow_tab = true
	text_box.line_ed.allow_untab = true
	text_box.line_ed.tabs_to_spaces = false
	text_box.line_ed.auto_indent = true
end


return plan
