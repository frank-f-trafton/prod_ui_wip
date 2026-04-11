local plan = {}


local pTable = require("prod_ui.lib.p_table")
local shared = require("demo.wimp.shared")
local uiKeyboard = require("prod_ui.ui_keyboard")


function plan.make(panel)
	panel:layoutSetBase("viewport-width")
	panel:containerSetScrollRangeMode("zero")
	panel:setScrollBars(false, false)


	local function _updateButtons(panel)
		local tb = panel:findTag("demo_text_box_s")
		if tb then
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

	local function setAlign(tb, align_mode)
		tb:setTextAlignment(align_mode)
	end

	local function _fn_alignLeft(self)
		local tb = panel:findTag("demo_text_box_s")
		if tb then
			setAlign(tb, "left")
		end
		_updateButtons(panel)
		return true
	end
	panel:keyShortcutSet("+f2", _fn_alignLeft)

	local function _fn_alignCenter(self)
		local tb = panel:findTag("demo_text_box_s")
		if tb then
			setAlign(tb, "center")
		end
		_updateButtons(panel)
		return true
	end
	panel:keyShortcutSet("+f3", _fn_alignCenter)

	local function _fn_alignRight(self)
		local tb = panel:findTag("demo_text_box_s")
		if tb then
			setAlign(tb, "right")
		end
		_updateButtons(panel)
		return true
	end
	panel:keyShortcutSet("+f4", _fn_alignRight)

	local ui_frame = assert(panel:getUIFrame(), "no UI Frame to hook shortcuts.")
	ui_frame:keyShortcutListAdd(panel)
	panel:userCallbackSet("cb_destroy", function(self)
		ui_frame:keyShortcutListRemove(self)
	end)


	local x1, y1 = 16, 16
	local xx, yy, ww, hh = x1, y1, 160, 32
	local w2, h2 = 168, 40

	local function radioAlignH(self)
		local tb = panel:findTag("demo_text_box_s")
		if tb then
			setAlign(tb, self.usr_align)
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

	local input_single = panel:addChild("input/text_box_single")
		:geometrySetMode("static", xx, yy, 256, 32)
		:setTag("demo_text_box_s")
		:setText("Single-Line Text Box")
		--:setAllowLineFeed(true)
		--:setTextAlignment("right")
		--:setGhostText("Ghost text")

	input_single:userCallbackSet("cb_action", function(self)
		print("input_single: The internal text is: " .. self:getText())
	end)

	--input_single:setMaxCodePoints(24) -- Test

	xx = x1
	yy = yy + h2 + math.floor(h2/2)

	local input_s_mask = panel:addChild("input/text_box_single")
		:geometrySetMode("static", xx, yy, 256, 32)
		:setTag("demo_text_box_s_masked")
		:setCharacterMasking(true)
		:setText("¡Silencio!")
		--:setGhostText("Ghost text")

	input_s_mask.LE_hist.enabled = false -- TODO: write up an actual method to do this
	input_s_mask:userCallbackSet("cb_action", function(self)
		print("input_s_mask: The unmasked text is: " .. self:getUnmaskedText())
	end)

	_updateButtons(panel)
end


return plan
