
-- ProdUI
local demoShared = require("demo_shared")


local plan = {}


local function timeFormatted()
	return string.format("%.2f", tostring(love.timer.getTime()))
end


function plan.make(panel)
	local context = panel.context

	--title("Button Work")

	panel:setLayoutBase("viewport-width")
	panel:setScrollRangeMode("auto")
	panel:setScrollBars(false, true)

	-- Repeat-Button
	local b_rep = panel:addChild("base/button_repeat")
	b_rep:initialize()
	demoShared.setStaticLayout(panel, b_rep, 0, 0, 128, 64)

	b_rep:setLabel("Button (Rep)")

	b_rep.usr_count = 0

	b_rep.wid_buttonAction = function(self)
		self.usr_count = self.usr_count + 1
		self:setLabel(tostring(self.usr_count))
	end


	-- Checkbox
	local chk = panel:addChild("base/checkbox")
	chk:initialize()
	demoShared.setStaticLayout(panel, chk, 160, 0, 256, 64)

	-- Test checkbox text label scissor-box.
	local silly_string = "CheckBox CheckBox CheckBox CheckBox CheckBox CheckBox CheckBox CheckBox CheckBox CheckBox CheckBox CheckBox"
	chk:setLabel(silly_string, "multi")

	chk.wid_buttonAction = function(self)
		print("Check it!")
	end

	-- Multi-state checkbox
	local chk_m = panel:addChild("base/checkbox_multi")
	chk_m:initialize()
	demoShared.setStaticLayout(panel, chk_m, 160, 96, 256, 64)
	chk_m:setLabel("Multi-State Checkbox", "single")
	chk_m.wid_buttonAction = function(self)
		print("Multi-Check state: " .. chk_m.value)
	end

	-- Button with a quad graphic
	local btn_q = panel:addChild("base/button")
	btn_q.skin_id = "button_tq1"
	btn_q.graphic = context.resources.quads["atlas"]["checkbox_on"] -- TODO: fix
	btn_q:initialize()
	demoShared.setStaticLayout(panel, btn_q, 64, 64, 64, 64)

	btn_q:setLabel("!?") -- XXX: was it intentional that this does not display?


	-- Radio buttons
	local py_plus = 48
	local px = 32
	local py = 200 - py_plus

	local rdo

	py=py+py_plus
	rdo = panel:addChild("base/radio_button")
	rdo:initialize()
	demoShared.setStaticLayout(panel, rdo, px, py, 192, py_plus)
	rdo.radio_group = "rg_a"
	rdo:setLabel("One (Group A)")
	--rdo.wid_buttonAction

	py=py+py_plus
	rdo = panel:addChild("base/radio_button")
	rdo:initialize()
	demoShared.setStaticLayout(panel, rdo, px, py, 192, py_plus)
	rdo.radio_group = "rg_a"
	rdo:setLabel("Two (Group A)")
	--rdo.wid_buttonAction

	py=py+py_plus
	rdo = panel:addChild("base/radio_button")
	rdo:initialize()
	demoShared.setStaticLayout(panel, rdo, px, py, 192, py_plus)
	rdo.radio_group = "rg_b"
	rdo:setLabel("Three (Group B)")
	--radio.wid_buttonAction

	py=py+py_plus
	rdo = panel:addChild("base/radio_button")
	rdo.x = px
	rdo.y = py
	rdo.w = 192
	rdo.h = py_plus
	rdo:initialize()
	demoShared.setStaticLayout(panel, rdo, px, py, 191, py_plus)
	rdo.radio_group = "rg_b"
	rdo:setLabel("Four (Group B)")
	--rdo.wid_buttonAction


	-- Sticky Button.
	local sticky = panel:addChild("base/button_sticky")
	sticky:initialize()
	demoShared.setStaticLayout(panel, sticky, 256, 192, 240, 32)
	sticky:setTag("button_sticky")
	sticky:setLabel("Sticky Button")

	sticky.wid_buttonAction = function(self)
		self:setLabel("Stuck! Time: " .. timeFormatted())

		local unsticker = self:findSiblingTag("button_unsticker")
		if unsticker then
			unsticker:setEnabled(true)
		end
	end


	-- A normal button that unpresses the sticky button.
	local b_unst = panel:addChild("base/button")
	b_unst:setTag("button_unsticker")
	b_unst:initialize()
	demoShared.setStaticLayout(panel, b_unst, 256, 192+48, 240, 32)
	b_unst:setLabel("Unpress Sticky Button")
	b_unst:setEnabled(false)

	b_unst.wid_buttonAction = function(self)
		local sticky = self:findSiblingTag("button_sticky")
		if sticky then
			sticky:setPressed(false)
			sticky:setLabel("Sticky Button")

			self:setEnabled(false)
		end
	end

	-- An instant-action button. Fires on click-down, without continuous action (at least from holding the mouse button).
	local b_instant = panel:addChild("base/button_instant")
	b_instant:initialize()
	demoShared.setStaticLayout(panel, b_instant, 256, 192+48+48, 240, 32)

	b_instant:setLabel("Instant Action Button.")

	b_instant.wid_buttonAction = function(self)
		self:setLabel("Instant Activate! Time: " .. timeFormatted())
	end


	-- A button with a secondary action.
	demoShared.makeLabel(panel, 256, 192+48+48+48, 240, 64, "Right-click, middle-click, or hit the 'application' key while the button is focused.", "multi")
	local b_secondary = panel:addChild("base/button")
	b_secondary:initialize()
	demoShared.setStaticLayout(panel, b_secondary, 256, 192+48+48+48+64, 240, 32)


	b_secondary:setLabel("Alt. Action Button.")

	b_secondary.wid_buttonAction = function(self)
		self:setLabel("Main action triggered.")
	end

	b_secondary.wid_buttonAction2 = function(self)
		self:setLabel("Secondary Action! Time: " .. timeFormatted())
	end

	b_secondary.wid_buttonAction3 = function(self)
		self:setLabel("Tertiary Action! Time: " .. timeFormatted())
	end


	local btn_2c = panel:addChild("base/button_double_click")
	btn_2c:initialize()
	demoShared.setStaticLayout(panel, btn_2c, 256, 192+48+48+48+64+64, 256, 32)
	btn_2c.radio_group = "bare1"
	btn_2c:setLabel("Double-Click button")

	btn_2c.wid_buttonAction = function(self)
		self:setLabel("Double-clicked! Time: " .. timeFormatted())
	end
end


return plan
