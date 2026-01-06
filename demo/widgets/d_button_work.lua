
-- ProdUI
local demoShared = require("demo_shared")


local plan = {}


local function timeFormatted()
	return string.format("%.2f", tostring(love.timer.getTime()))
end


function plan.make(panel)
	local context = panel.context

	--title("Button Work")

	panel:layoutSetBase("viewport-width")
	panel:containerSetScrollRangeMode("auto")
	panel:setScrollBars(false, true)

	local b_rep = panel:addChild("base/button_repeat")
	b_rep:geometrySetMode("static", 0, 0, 128, 64)
	b_rep:setLabel("Button (Rep)")

	b_rep.usr_count = 0

	b_rep:userCallbackSet("cb_buttonAction", function(self)
		self.usr_count = self.usr_count + 1
		self:setLabel(tostring(self.usr_count))
	end)

	local chk = panel:addChild("base/checkbox")
	chk:geometrySetMode("static", 160, 0, 256, 64)

	chk:setLabel("CheckBox", "single")

	chk:userCallbackSet("cb_buttonAction", function(self)
		print("Activated checkbox!")
	end)


	local chk_m = panel:addChild("base/checkbox_multi")
	chk_m:geometrySetMode("static", 160, 96, 256, 64)
	chk_m:setLabel("Multi-State Checkbox", "single")
	chk_m:userCallbackSet("cb_buttonAction", function(self)
		print("Multi-Check state: " .. chk_m.value)
	end)

	-- Button with a quad graphic
	local btn_q = panel:addChild("base/button", "button_tq1")
	btn_q.graphic = context.resources.quads["checkbox_on"] -- TODO: fix
	btn_q:geometrySetMode("static", 64, 64, 64, 64)
	btn_q:setLabel("!?") -- XXX: was it intentional that this does not display?

	-- Radio buttons
	local py_plus = 48
	local px = 32
	local py = 200 - py_plus

	local rdo

	py=py+py_plus
	rdo = panel:addChild("base/radio_button")
	rdo:geometrySetMode("static", px, py, 192, py_plus)
	rdo.radio_group = "rg_a"
	rdo:setLabel("One (Group A)")
	--rdo:userCallbackSet("cb_buttonAction", nil)

	py=py+py_plus
	rdo = panel:addChild("base/radio_button")
	rdo:geometrySetMode("static", px, py, 192, py_plus)
	rdo.radio_group = "rg_a"
	rdo:setLabel("Two (Group A)")
	--rdo:userCallbackSet("cb_buttonAction", nil)

	py=py+py_plus
	rdo = panel:addChild("base/radio_button")
	rdo:geometrySetMode("static", px, py, 192, py_plus)
	rdo.radio_group = "rg_b"
	rdo:setLabel("Three (Group B)")
	--rdo:userCallbackSet("cb_buttonAction", nil)

	py=py+py_plus
	rdo = panel:addChild("base/radio_button")
	rdo:geometrySetMode("static", px, py, 192, py_plus)
	rdo.radio_group = "rg_b"
	rdo:setLabel("Four (Group B)")
	--rdo:userCallbackSet("cb_buttonAction", nil)


	local sticky = panel:addChild("base/button_sticky")
	sticky:geometrySetMode("static", 256, 192, 240, 32)
	sticky:setTag("button_sticky")
	sticky:setLabel("Sticky Button")

	sticky:userCallbackSet("cb_buttonAction", function(self)
		self:setLabel("Stuck! Time: " .. timeFormatted())

		local unsticker = self:findSiblingTag("button_unsticker")
		if unsticker then
			unsticker:setEnabled(true)
		end
	end)


	local b_unst = panel:addChild("base/button")
	b_unst:setTag("button_unsticker")
	b_unst:geometrySetMode("static", 256, 192+48, 240, 32)
	b_unst:setLabel("Unpress Sticky Button")
	b_unst:setEnabled(false)

	b_unst:userCallbackSet("cb_buttonAction", function(self)
		local sticky = self:findSiblingTag("button_sticky")
		if sticky then
			sticky:setPressed(false)
			sticky:setLabel("Sticky Button")

			self:setEnabled(false)
		end
	end)


	local b_immediate = panel:addChild("base/button_immediate")
	b_immediate:geometrySetMode("static", 256, 192+48+48, 240, 32)
	b_immediate:setLabel("Immediate Action Button.")

	b_immediate:userCallbackSet("cb_buttonAction", function(self)
		self:setLabel("Activated! Time: " .. timeFormatted())
	end)


	demoShared.makeLabel(panel, 256, 192+48+48+48, 240, 64, false, "Right-click, middle-click, or hit the 'application' key while the button is focused.", "multi")
	local b_secondary = panel:addChild("base/button")
	b_secondary:geometrySetMode("static", 256, 192+48+48+48+64, 240, 32)
	b_secondary:setLabel("Alt. Action Button.")

	b_secondary:userCallbackSet("cb_buttonAction", function(self)
		self:setLabel("Main action triggered.")
	end)

	b_secondary:userCallbackSet("cb_buttonAction2", function(self)
		self:setLabel("Secondary Action! Time: " .. timeFormatted())
	end)

	b_secondary:userCallbackSet("cb_buttonAction3", function(self)
		self:setLabel("Tertiary Action! Time: " .. timeFormatted())
	end)


	local btn_2c = panel:addChild("base/button_double_click")
	btn_2c:geometrySetMode("static", 256, 192+48+48+48+64+64, 256, 32)
	btn_2c.radio_group = "bare1"
	btn_2c:setLabel("Double-Click button")

	btn_2c:userCallbackSet("cb_buttonAction", function(self)
		self:setLabel("Double-clicked! Time: " .. timeFormatted())
	end)
end


return plan
