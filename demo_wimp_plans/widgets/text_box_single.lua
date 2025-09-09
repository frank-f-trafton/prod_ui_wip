
-- ProdUI
local demoShared = require("demo_shared")
local uiKeyboard = require("prod_ui.ui_keyboard")
local pTable = require("prod_ui.lib.pile_table")


local plan = {}


function plan.make(panel)
	panel:setLayoutBase("viewport-width")
	panel:setScrollRangeMode("zero")
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

	local shortcuts = {
		["+f2"] = function(self, key, scancode, isrepeat)
			local tb = panel:findTag("demo_text_box_s")
			if tb then
				setAlign(tb, "left")
			end
			_updateButtons(panel)
		end,
		["+f3"] = function(self, key, scancode, isrepeat)
			local tb = panel:findTag("demo_text_box_s")
			if tb then
				setAlign(tb, "center")
			end
			_updateButtons(panel)
		end,
		["+f4"] = function(self, key, scancode, isrepeat)
			local tb = panel:findTag("demo_text_box_s")
			if tb then
				setAlign(tb, "right")
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

	local ui_frame = assert(demoShared.getUIFrame(panel), "no UI Frame to hook into.")

	table.insert(ui_frame.hooks_trickle_key_pressed, hook_pressed)
	panel.userDestroy = function(self)
		local ui_frame = demoShared.getUIFrame(panel)
		if ui_frame then
			pTable.removeElement(ui_frame.hooks_trickle_key_pressed, hook_pressed)
		end
	end

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

	rdo_align = panel:addChild("barebones/radio_button")
	demoShared.setStaticLayout(panel, rdo_align, xx, yy, ww, hh)
	rdo_align:setTag("demo_align_l")
	rdo_align.radio_group = "align_h"
	rdo_align.usr_align = "left"
	rdo_align:setLabel("Align Left (F2)", "single")
	rdo_align.wid_buttonAction = radioAlignH

	xx = xx + w2

	rdo_align = panel:addChild("barebones/radio_button")
	demoShared.setStaticLayout(panel, rdo_align, xx, yy, ww, hh)
	rdo_align:setTag("demo_align_c")
	rdo_align.radio_group = "align_h"
	rdo_align.usr_align = "center"
	rdo_align:setLabel("Align Center (F3)", "single")
	rdo_align.wid_buttonAction = radioAlignH

	xx = xx + w2

	rdo_align = panel:addChild("barebones/radio_button")
	demoShared.setStaticLayout(panel, rdo_align, xx, yy, ww, hh)
	rdo_align:setTag("demo_align_r")
	rdo_align.radio_group = "align_h"
	rdo_align.usr_align = "right"
	rdo_align:setLabel("Align Right (F4)", "single")
	rdo_align.wid_buttonAction = radioAlignH

	xx = x1
	yy = yy + h2 + math.floor(h2/2)

	-- [=[
	local input_single = panel:addChild("input/text_box_single")
	demoShared.setStaticLayout(panel, input_single, xx, yy, 256, 32)

	input_single:setTag("demo_text_box_s")
	input_single:setText("Single-Line Text Box")

	--input_single:setAllowLineFeed(true)
	--input_single:setTextAlignment("right")

	input_single.wid_action = function(self)
		print("input_single: The internal text is: " .. self:getText())
	end
	--]=]

	xx = x1
	yy = yy + h2 + math.floor(h2/2)

	local input_s_mask = panel:addChild("input/text_box_single")
	demoShared.setStaticLayout(panel, input_s_mask, xx, yy, 256, 32)

	input_s_mask:setTag("demo_text_box_s_masked")

	input_s_mask.LE_hist.enabled = false -- TODO: write up an actual method to do this
	input_s_mask:setCharacterMasking(true)
	input_s_mask:setText("¡Silencio!")

	input_s_mask.wid_action = function(self)
		print("input_s_mask: The unmasked text is: " .. self:getUnmaskedText())
	end

	--demoShared.makeLabel(panel, xx, yy, 512, 96, "foobar", "multi")

	_updateButtons(panel)
end


return plan
