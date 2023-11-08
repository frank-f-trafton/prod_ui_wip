
-- ProdUI
local commonMenu = require("lib.prod_ui.logic.common_menu")
local uiLayout = require("lib.prod_ui.ui_layout")
local widShared = require("lib.prod_ui.logic.wid_shared")


local plan = {}


function plan.make(parent)

	local context = parent.context

	local frame = parent:addChild("wimp/window_frame")

	frame.w = 640
	frame.h = 480

	frame:setFrameTitle("Button skin tests")

	local content = frame:findTag("frame_content")
	if content then

		content.layout_mode = "resize"

		content:setScrollBars(false, false)


		-- Make a one-off SkinDef Patch that we can adjust without changing all other buttons with the default skin.
		local resources = content.context.resources
		local patch = resources:newSkinDef("button1")
		resources:registerSkinDef(patch, patch, false)
		-- This patch is empty (except for an __index reference), so refreshSkinDef() isn't necessary in
		-- this specific case. You should call it whenever changing resources which need to be refreshed
		-- from the theme (prefixed with "*") or scaled (prefixed with "$").
		resources:refreshSkinDef(patch)

		local button_norm = content:addChild("base/button", {skin_id = patch})
		button_norm.x = 256
		button_norm.w = 224
		button_norm.h = 64
		button_norm:setLabel("Normal Skinned Button")

		local t_align_h = {"left", "center", "right", "justify"}
		local btn_label_align_h = content:addChild("barebones/button")
		btn_label_align_h.w = 224
		btn_label_align_h.h = 64
		btn_label_align_h:setLabel("label_align_h")

		btn_label_align_h.wid_buttonAction = function(self)

			button_norm.skin.label_align_h = t_align_h[love.math.random(1, 4)]
			self:setLabel("button_norm's label_align_h: " .. button_norm.skin.label_align_h)
			--[[
			self.label_align_v = "middle" -- "top", "middle", "bottom"
			--]]
		end

		local t_align_v = {"top", "middle", "bottom"}
		local btn_label_align_v = content:addChild("barebones/button")
		btn_label_align_v.y = 64
		btn_label_align_v.w = 224
		btn_label_align_v.h = 64
		btn_label_align_v.text = "label_align_v"

		btn_label_align_v.wid_buttonAction = function(self)

			button_norm.skin.label_align_v = t_align_v[love.math.random(1, 3)]
			self:setLabel("button_norm's label_align_v: " .. button_norm.skin.label_align_v)
		end

		local btn_rep = content:addChild("barebones/button_repeat")
		btn_rep.x = 256
		btn_rep.y = 64
		btn_rep.w = 128
		btn_rep.h = 64
		btn_rep:setLabel("Button (Rep)")
		btn_rep.usr_count = 0
		btn_rep.wid_buttonAction = function(self)
			self.usr_count = self.usr_count + 1
			self:setLabel(tostring(self.usr_count))
		end

		local bare_check = content:addChild("barebones/checkbox")
		bare_check.x = 256
		bare_check.y = 128
		bare_check.w = 128
		bare_check.h = 64
		bare_check:setLabel("Checkbox")

		local bare_radio
		bare_radio = content:addChild("barebones/radio_button")
		bare_radio.radio_group = "bare1"
		bare_radio.x = 256
		bare_radio.y = 192
		bare_radio.w = 128
		bare_radio.h = 64
		bare_radio:setLabel("Radio1")

		bare_radio = content:addChild("barebones/radio_button")
		bare_radio.radio_group = "bare1"
		bare_radio.x = 256
		bare_radio.y = 256
		bare_radio.w = 128
		bare_radio.h = 64
		bare_radio:setLabel("Radio2")

		local lbl
		lbl = content:addChild("base/label")
		lbl.enabled = true
		lbl.x = 32
		lbl.y = 128
		lbl.w = 192
		lbl.h = 48
		lbl:setLabel("Label (enabled)")

		lbl = content:addChild("base/label")
		lbl.enabled = false
		lbl.x = 32
		lbl.y = 128+48
		lbl.w = 192
		lbl.h = 48
		lbl:setLabel("Label (disabled)")

		lbl = content:addChild("barebones/label")
		lbl.enabled = true
		lbl.x = 32
		lbl.y = 128+48+48
		lbl.w = 192
		lbl.h = 48
		lbl:setLabel("Barebones Label (enabled)")

		lbl = content:addChild("barebones/label")
		lbl.enabled = false
		lbl.x = 32
		lbl.y = 128+48+48+48
		lbl.w = 192
		lbl.h = 48
		lbl:setLabel("Barebones Label (disabled)")

		local sl1 = content:addChild("barebones/slider_bar")
		sl1.x = 32
		sl1.y = 128+48+48+48+48
		sl1.w = 192
		sl1.h = 48
		sl1.trough_vertical = false
		sl1:setLabel("Barebones Slider Bar")

		sl1.slider_pos = 0
		sl1.slider_def = 0
		sl1.slider_max = 64

		local sl2 = content:addChild("barebones/slider_bar")
		sl2.x = 128
		sl2.y = 128+48+48+48+48+48
		sl2.w = 48
		sl2.h = 192
		sl2.trough_vertical = true
		sl2:setLabel("Vertical")

		sl2.slider_pos = 0
		sl2.slider_def = 0
		sl2.slider_max = 64

		local b_instant = content:addChild("barebones/button_instant")
		b_instant.x = 240
		b_instant.y = 128+48+48+48+48+48
		b_instant.w = 192
		b_instant.h = 48
		b_instant:setLabel("Instant-Action Button")
		b_instant.usr_n = 0

		b_instant.wid_buttonAction = function(self)
			self.usr_n = self.usr_n + 1
			self:setLabel("Activated! #" .. self.usr_n)
		end

		local b_stick = content:addChild("barebones/button_instant")
		b_stick.x = 240+200
		b_stick.y = 128+48+48+48+48+48
		b_stick.w = 192
		b_stick.h = 48
		b_stick:setLabel("Sticky Button")

		b_stick.wid_buttonAction = function(self)
			self:setLabel("Stuck!")
		end
	end

	frame:reshape(true)
	frame:center(true, true)

	return frame
end


return plan
