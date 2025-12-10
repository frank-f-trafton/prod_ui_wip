
-- ProdUI
local demoShared = require("demo_shared")
local pTable = require("prod_ui.lib.pile_table")
local uiKeyboard = require("prod_ui.ui_keyboard")


local plan = {}


function plan.make(panel)
	local context = panel.context

	panel:layoutSetBase("viewport-width")
	panel:containerSetScrollRangeMode("auto")
	panel:setScrollBars(false, true)


	local function _updateButtons(panel)
		local tb = panel:findTag("demo_script_ed")
		if tb then
			local b_wrap = panel:findTag("demo_wrap")
			if b_wrap then
				b_wrap:setChecked(tb:getWrapMode())
			end

			-- TODO: This is unergonomic, to say the least.
			local b_align_l = panel:findTag("demo_align_l")
			if b_align_l then
				if b_align_l.usr_align == tb:getTextAlignment() then
					b_align_l:setChecked(true)
				end
			end

			local b_align_c = panel:findTag("demo_align_c")
			if b_align_c then
				if b_align_c.usr_align == tb:getTextAlignment() then
					b_align_c:setChecked(true)
				end
			end

			local b_align_r = panel:findTag("demo_align_r")
			if b_align_r then
				if b_align_r.usr_align == tb:getTextAlignment() then
					b_align_r:setChecked(true)
				end
			end
		end
	end

	local function setColorization(tb, enabled)
		tb:setColorization(not not enabled)
		--[[
		local DEMO_PURPLE = {1, 0, 1, 1}

		wid_text_box:resizeWidget(512, 256)
		wid_text_box.LE.fn_colorize = function(self, str, syntax_colors, syntax_work)

			-- i: byte offset in string
			-- j: the next byte offset
			-- k: code point index
			local i, j, k = 1, 1, 1
			while i <= #str do
				j = utf8.offset(str, 2, i)
				local code_point = string.sub(str, i, j - 1)
				if tonumber(code_point) then
					syntax_colors[k] = DEMO_PURPLE
				else
					syntax_colors[k] = false
				end
				i = j
				k = k + 1
			end

			return k
		end
		--]]
	end


	-- TODO, maybe with linked control widgets:
	-- * Toggle highlight
	-- * Toggle cut
	-- * Toggle copy
	-- * Toggle paste


	local shortcuts = {
		["+f5"] = function(self, key, scancode, isrepeat)
			local tb = panel:findTag("demo_script_ed")
			if tb then
				tb:setWrapMode(not tb:getWrapMode())
			end
			_updateButtons(panel)
		end,
		["+f2"] = function(self, key, scancode, isrepeat)
			local tb = panel:findTag("demo_script_ed")
			if tb then
				tb:setTextAlignment("left")
			end
			_updateButtons(panel)
		end,
		["+f3"] = function(self, key, scancode, isrepeat)
			local tb = panel:findTag("demo_script_ed")
			if tb then
				tb:setTextAlignment("center")
			end
			_updateButtons(panel)
		end,
		["+f4"] = function(self, key, scancode, isrepeat)
			local tb = panel:findTag("demo_script_ed")
			if tb then
				tb:setTextAlignment("right")
			end
			_updateButtons(panel)
		end,
	}

	local hook_pressed = function(self, tbl, key, scancode, isrepeat)
		local key_mgr = self.context.key_mgr
		local mod = key_mgr.mod

		local input_str = uiKeyboard.getKeyString(mod["ctrl"], mod["shift"], mod["alt"], mod["gui"], false, key)
		if shortcuts[input_str] then
			shortcuts[input_str](self, key, scancode, isrepeat)
			return true
		end
	end

	local ui_frame = assert(panel:getUIFrame(), "no UI Frame to hook into.")

	table.insert(ui_frame.KH_trickle_key_pressed, hook_pressed)
	panel.userDestroy = function(self)
		local ui_frame = panel:getUIFrame()
		if ui_frame then
			pTable.removeElement(ui_frame.KH_trickle_key_pressed, hook_pressed)
		end
	end

	local x1, y1 = 16, 16
	local xx, yy, ww, hh = x1, y1, 160, 32
	local w2, h2 = 168, 40

	local cbox_wrap = panel:addChild("base/checkbox")
		:geometrySetMode("static", xx, yy, ww, hh)
		:setTag("demo_wrap")
		:setLabel("Wrap (F5)", "single")
	cbox_wrap.wid_buttonAction = function(self)
		local tb = panel:findTag("demo_script_ed")
		if tb then
			tb:setWrapMode(self.checked)
		end
		_updateButtons(panel)
	end

	xx = x1
	yy = yy + h2

	local function radioAlignH(self)
		local tb = panel:findTag("demo_script_ed")
		if tb then
			tb:setTextAlignment(self.usr_align)
		end
		_updateButtons(panel)
	end

	local rdo_align

	rdo_align = panel:addChild("base/radio_button")
		:geometrySetMode("static", xx, yy, ww, hh)
		:setTag("demo_align_l")
		:setRadioGroup("align_h")
		:setLabel("Align Left (F2)", "single")
	rdo_align.usr_align = "left"
	rdo_align.wid_buttonAction = radioAlignH

	xx = xx + w2

	rdo_align = panel:addChild("base/radio_button")
		:geometrySetMode("static", xx, yy, ww, hh)
		:setTag("demo_align_c")
		:setRadioGroup("align_h")
		:setLabel("Align Center (F3)", "single")
	rdo_align.usr_align = "center"
	rdo_align.wid_buttonAction = radioAlignH

	xx = xx + w2

	rdo_align = panel:addChild("base/radio_button")
		:geometrySetMode("static", xx, yy, ww, hh)
		:setTag("demo_align_r")
		:setRadioGroup("align_h")
		:setLabel("Align Right (F4)", "single")
	rdo_align.usr_align = "right"
	rdo_align.wid_buttonAction = radioAlignH

	xx = x1
	yy = yy + h2 + math.floor(h2/2)


	local function stepperIllumination(self)
		local tb = panel:findTag("demo_script_ed")
		if tb then
			local str = self.options[self.index]
			if str then
				tb:setIlluminateCurrentLine(str)
			end
		end
	end

	demoShared.makeLabel(panel, xx, yy, ww, hh, "Line illumination:", "single")

	xx = xx + w2

	local stp_illum = panel:addChild("base/stepper")
		:geometrySetMode("static", xx, yy, ww * 2, hh)
		:setTag("demo_illum")

	stp_illum.wid_stepperChanged = stepperIllumination

	stp_illum:insertOption("always")
	stp_illum:insertOption("never")
	stp_illum:insertOption("no-highlight")

	xx = x1
	yy = yy + h2 + math.floor(h2/2)

	local ED_W, ED_H = 496, 350

	local script_ed = panel:addChild("input/script_editor")
		:geometrySetMode("static", xx, yy, ED_W, ED_H)
		:setTag("demo_script_ed")
		:setScrollBars(true, true)

	script_ed.LE_ghost_text = "Ghost text"

	script_ed:setAllowTab(true)
		:setAllowUntab(true)
		:setTabsToSpaces(false)
		:setAutoIndent(true)
		--:setAllowReplaceMode(false)
		:setIlluminateCurrentLine("always")

	-- Debug...
	--local quickPrint = require("lib.quick_print")
	--script_ed.DEBUG_qp = quickPrint.new()

	--[[
	local str = ""
	for i = 1, 100 do
		str = str .. i .. "\n"
	end
	script_ed:setText(str)
	--]]

	local demo_text = [=[
Hmm... this widget does not appear to be finished.]=]

	script_ed:setText(demo_text)

	xx = x1
	yy = yy + h2 + ED_H

	_updateButtons(panel)
end


return plan
