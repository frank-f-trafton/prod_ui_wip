local plan = {}


local pTable = require("prod_ui.lib.p_table")
local shared = require("demo.wimp.shared")
local uiKeyboard = require("prod_ui.ui_keyboard")


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

			local b_line_no_col = panel:findTag("demo_line_no")
			if b_line_no_col then
				b_line_no_col:setChecked(tb:getLineNumberColumn())
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

			local b_illum = panel:findTag("demo_illum")
			if b_illum then
				local mode = tb:getIlluminationMode()
				for i, option in ipairs(b_illum.MN_items) do
					print(i, option, option.text)
					if option.text == mode then
						b_illum:setSelectionByIndex(i)
						break
					end
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

	local function _fn_wrapMode(self)
		local tb = panel:findTag("demo_script_ed")
		if tb then
			tb:setWrapMode(not tb:getWrapMode())
		end
		_updateButtons(panel)
		return true
	end
	panel:keyShortcutSet("+f5", _fn_wrapMode)

	local function _fn_LineNumCol(self)
		local tb = panel:findTag("demo_script_ed")
		if tb then
			tb:setLineNumberColumn(not tb:getLineNumberColumn())
		end
		_updateButtons(panel)
		return true
	end
	panel:keyShortcutSet("+f6", _fn_LineNumCol)

	local function _textAlign(wid, side)
		local tb = panel:findTag("demo_script_ed")
		if tb then
			tb:setTextAlignment(side)
		end
	end

	local function _fn_textAlignLeft(self)
		_textAlign(self, "left")
		_updateButtons(panel)
		return true
	end
	panel:keyShortcutSet("+f2", _fn_textAlignLeft)

	local function _fn_textAlignCenter(self)
		_textAlign(self, "center")
		_updateButtons(panel)
		return true
	end
	panel:keyShortcutSet("+f3", _fn_textAlignCenter)

	local function _fn_textAlignRight(self)
		_textAlign(self, "right")
		_updateButtons(panel)
		return true
	end
	panel:keyShortcutSet("+f4", _fn_textAlignRight)

	local ui_frame = assert(panel:getUiFrame(), "no UI Frame to hook shortcuts.")
	ui_frame:keyShortcutListAdd(panel)
	panel:userCallbackSet("cb_destroy", function(self)
		ui_frame:keyShortcutListRemove(self)
	end)


	local x1, y1 = 16, 16
	local xx, yy, ww, hh = x1, y1, 160, 32
	local w2, h2 = 168, 40

	local cbox_wrap = panel:addChild("base/checkbox")
		:geometrySetMode("static", xx, yy, ww, hh)
		:setTag("demo_wrap")
		:setLabel("Wrap (F5)", "single")
	cbox_wrap:userCallbackSet("cb_buttonAction", function(self)
		local tb = panel:findTag("demo_script_ed")
		if tb then
			tb:setWrapMode(self.checked)
		end
		_updateButtons(panel)
	end)

	xx = x1
	yy = yy + h2


	local cbox_line_no = panel:addChild("base/checkbox")
		:geometrySetMode("static", xx, yy, ww*2, hh)
		:setTag("demo_line_no")
		:setLabel("Show line number column (F6)", "single")
	cbox_line_no:userCallbackSet("cb_buttonAction", function(self)
		local tb = panel:findTag("demo_script_ed")
		if tb then
			tb:setLineNumberColumn(self.checked)
		end
		_updateButtons(panel)
	end)

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
	rdo_align:userCallbackSet("cb_buttonAction", radioAlignH)

	xx = xx + w2

	rdo_align = panel:addChild("base/radio_button")
		:geometrySetMode("static", xx, yy, ww, hh)
		:setTag("demo_align_c")
		:setRadioGroup("align_h")
		:setLabel("Align Center (F3)", "single")
	rdo_align.usr_align = "center"
	rdo_align:userCallbackSet("cb_buttonAction", radioAlignH)

	xx = xx + w2

	rdo_align = panel:addChild("base/radio_button")
		:geometrySetMode("static", xx, yy, ww, hh)
		:setTag("demo_align_r")
		:setRadioGroup("align_h")
		:setLabel("Align Right (F4)", "single")
	rdo_align.usr_align = "right"
	rdo_align:userCallbackSet("cb_buttonAction", radioAlignH)

	xx = x1
	yy = yy + h2 + math.floor(h2/2)


	local function stepperIllumination(self, item, item_i)
		if item then
			local tb = panel:findTag("demo_script_ed")
			if tb then
				local str = item.text
				if str then
					print("???", str)
					tb:setIlluminateCurrentLine(str)
				end
			end
		end
	end

	shared.makeControlLabel(panel, xx, yy, ww, hh, false, "Line illumination:", "left", "middle", false)

	xx = xx + w2

	local stp_illum = panel:addChild("base/stepper")
		:geometrySetMode("static", xx, yy, ww * 2, hh)
		:setTag("demo_illum")

	stp_illum:userCallbackSet("cb_select", stepperIllumination)

	stp_illum:addItem("always")
	stp_illum:addItem("never")
	stp_illum:addItem("no-highlight")

	xx = x1
	yy = yy + h2 + math.floor(h2/2)

	local ED_W, ED_H = 496, 350

	local script_ed = panel:addChild("input/script_editor")
		:geometrySetMode("static", xx, yy, ED_W, ED_H)
		:setTag("demo_script_ed")
		:setScrollBars(true, true)
		--:setGhostText("Ghost text")

	script_ed:setAllowTab(true)
		:setAllowUntab(true)
		:setTabsToSpaces(false)
		:setAutoIndent(true)
		:setWrapMode(true)
		--:setAllowReplaceMode(false)
		:setIlluminateCurrentLine("always")
		:setLineNumberColumn(true)

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
-- Returns the sum of a list of numbers.
local function sum(...)
	local c = 0
	for i = 1, select("#", ...) do
		local v = select(i, ...)
		if type(v) ~= "number" then
			error("expected number")
		end
		c = c + v
	end
	return c
end

print(sum(1, 2, 3, 4, 5)) --> 15
]=]

	script_ed:setText(demo_text)

	--script_ed:setMaxCodePoints(24) -- Test

	xx = x1
	yy = yy + h2 + ED_H

	_updateButtons(panel)
end


return plan
