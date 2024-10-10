
--[[
	A window frame with a text input box in it.
--]]

-- ProdUI
local commonWimp = require("prod_ui.logic.common_wimp")
local itemOps = require("prod_ui.logic.item_ops")
local keyCombo = require("prod_ui.lib.key_combo")
local uiLayout = require("prod_ui.ui_layout")


local plan = {}


function plan.make(parent)
	local context = parent.context

	local frame = parent:addChild("wimp/window_frame", {make_menu_bar = true})

	frame.w = 640--350
	frame.h = 480--240

	frame:setFrameTitle("LineEditor Test")

	local header = frame:findTag("frame_header")
	if header then
		--header.condensed = true
	end

	local content = frame:findTag("frame_content")
	if content then
		content.w = 640
		content.h = 480

		--content.layout_mode = "auto"
		content.layout_mode = "resize"

		content:setScrollBars(false, false)

		local c_bar = content:addChild("base/container")
		c_bar.h = 64

		c_bar.lc_func = uiLayout.fitTop
		uiLayout.register(content, c_bar)

		--[[
		local cbox_wrap = c_bar:addChild("base/checkbox")
		cbox_wrap.x = 0
		cbox_wrap.y = 0
		cbox_wrap.w = 160
		cbox_wrap.h = 40
		cbox_wrap:setLabel("Wrap Mode (F5)", "single")
		--]]

		local temp_instructions = c_bar:addChild("base/text", {font = context.resources.fonts.p})
		temp_instructions.x = 0
		temp_instructions.w = 512
		temp_instructions.h = c_bar.h
		temp_instructions.text = "F5: Wrap Mode\nF6/F7/F8: Align (L, C, R)"
		temp_instructions:refreshText()

		local text_box = content:addChild("input/text_box_multi", {font = context.resources.fonts.p})
		text_box:setTag("demo_text_box") -- Helps identify the widget from the main demo.
		text_box.x = 0
		text_box.y = 0
		text_box.w = 400
		text_box.h = 350
		text_box:setScrollBars(true, true)

		text_box.ghost_text = "Ghost text"

		--text_box.line_ed.allow_line_feed = false
		text_box.line_ed.allow_tab = true
		text_box.line_ed.allow_untab = true
		text_box.line_ed.tabs_to_spaces = false
		text_box.line_ed.auto_indent = true

		text_box:reshape()

		text_box.lc_func = uiLayout.fitRemaining
		uiLayout.register(content, text_box)
	end


	frame:reshape(true)
	frame:center(true, true)


	-- Set up menu
	local menu_bar = frame:findTag("frame_menu_bar")
	if menu_bar then
		local def_file = {
			{
				type = "command",
				text = "_N_ew",
				text_shortcut = "Ctrl+N",
				key_mnemonic = "n",
				key_shortcut = "KC n",
				callback = function(client, item) print("NEW!") end,
			},
			{
				type = "command",
				text = "_O_pen",
				text_shortcut = "Ctrl+O",
				key_mnemonic = "o",
				key_shortcut = "KC o",
				callback = function(client, item) print("OPEN!") end,
			},
			itemOps.def_separator,
			{
				type = "command",
				text = "_Q_uit",
				text_shortcut = "Ctrl+Q",
				callback = function(client, item) commonWimp.closeWindowFrame(client) end,
				key_mnemonic = "q",
				key_shortcut = "KC q",
			},
		}
		menu_bar:appendItem("category", {
			text = "_F_ile",
			key_mnemonic = "f",
			pop_up_def = def_file,
		})

		menu_bar:arrange()
		menu_bar:resize()
		menu_bar:reshape()
		menu_bar:menuChangeCleanup()

		-- Hook menu bar key commands to Window Frame
		local hook_pressed = {
			wid = menu_bar,
			func = menu_bar.widHook_pressed,
		}
		local hook_released = {
			wid = menu_bar,
			func = menu_bar.widHook_released,
		}

		table.insert(frame.hooks_key_pressed, hook_pressed)
		table.insert(frame.hooks_key_released, hook_released)
	end

	-- Hook shortcuts to Window Frame
	local shortcuts = {
		["KC q"] = function(self, key, scancode, isrepeat) commonWimp.closeWindowFrame(self) end,
	}
	local hook_pressed = {
		wid = frame,
		func = function(self, tbl, key, scancode, isrepeat)
			local key_mgr = self.context.key_mgr
			local mod = key_mgr.mod

			local input_str = keyCombo.getKeyString(false, mod["ctrl"], mod["shift"], mod["alt"], mod["gui"], key)
			if shortcuts[input_str] then
				shortcuts[input_str](self, key, scancode, isrepeat)
				return true
			end
		end,
	}
	table.insert(frame.hooks_key_pressed, hook_pressed)

	return frame
end

return plan
