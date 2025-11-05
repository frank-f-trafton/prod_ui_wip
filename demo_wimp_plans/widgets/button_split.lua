
-- ProdUI
local demoShared = require("demo_shared")
local uiPopUpMenu = require("prod_ui.ui_pop_up_menu")


local plan = {}


local function _dummy() end


-- A pop-up menu definition for when the aux part of the button is activated.
local _pop_up_proto
do
	local P = uiPopUpMenu.P

	_pop_up_proto = P.prototype {
		P.command()
			:setText("Pretend"),

		P.command()
			:setText("something"),

		P.command()
			:setText("cool"),

		P.command()
			:setText("just"),

		P.command()
			:setText("happened")
	}
end


local function _popUpDestroy(self)
	if self.wid_ref and not self.wid_ref._dead then
		self.wid_ref.aux_pressed = false
		self.wid_ref.pressed = false
	end
end


local function _createPopUpMenu(self)
	if self.aux_enabled then
		self.pressed = true
		self.aux_pressed = true

		_pop_up_proto:configure(self)

		local root = self:getRootWidget()
		local ax, ay = self:getAbsolutePosition()
		local menu_x
		local menu_y = ay + self.h
		if self.skin.aux_placement == "left" then
			menu_x = ax
		else
			menu_x = ax + self.w - self.vp3.w
		end

		local lgcWimp = self.context:getLua("shared/lgc_wimp")
		local pop_up = lgcWimp.makePopUpMenu(self, _pop_up_proto, menu_x, menu_y)
		root:sendEvent("rootCall_doctorCurrentPressed", self, pop_up, "menu-drag")

		pop_up:tryTakeThimble2()

		pop_up.userDestroy = _popUpDestroy

		-- Halt propagation
		return true
	end
end


local function _radioPlacement(self)
	local btn = self:findSiblingTag("demo_split_btn")
	if btn then
		btn.skin.aux_placement = self.usr_placement
		btn:reshape()
	end
end


function plan.make(panel)
	--title("Split Button")

	panel:layoutSetBase("viewport-width")
	panel:setScrollRangeMode("auto")
	panel:setScrollBars(false, true)

	-- Split Button
	local wid_id = "wimp/button_split"
	local skin_id = panel.context.widget_defs[wid_id].skin_id .. "_DEMO"
	local btn_spl = panel:addChild(wid_id, skin_id)
	btn_spl:geometrySetMode("static", 0, 0, 224, 64)
	btn_spl:setTag("demo_split_btn")

	btn_spl:setLabel("Split Button")
	btn_spl.wid_buttonAction = function(self)
		print("(Click)")
	end
	btn_spl.wid_buttonAction2 = _createPopUpMenu
	btn_spl.wid_buttonActionAux = _createPopUpMenu

	local xx, yy, ww, hh = 256, 0, 256, 48

	do
		local chk = panel:addChild("base/checkbox")
		chk:geometrySetMode("static", xx, yy, ww, hh)
		chk:setLabel("Aux Enabled")
		chk:setChecked(not not btn_spl.aux_enabled)
		chk.wid_buttonAction = function(self)
			local btn = self:findSiblingTag("demo_split_btn")
			if btn then
				btn:setAuxEnabled(self.checked)
			end
		end
		yy = yy + hh
	end

	demoShared.makeLabel(panel, xx, yy, ww, hh, "Aux Side", "single")
	yy = yy + hh

	do
		local rdo = panel:addChild("barebones/radio_button")
		rdo:geometrySetMode("static", xx, yy, ww, hh)
		rdo.radio_group = "split_placement"
		rdo.usr_placement = "right"
		rdo:setLabel("Right")
		rdo.wid_buttonAction = _radioPlacement
		if btn_spl.skin.aux_placement == rdo.usr_placement then
			rdo:setChecked(true)
		end
		yy = yy + hh
	end

	do
		local rdo = panel:addChild("barebones/radio_button")
		rdo:geometrySetMode("static", xx, yy, ww, hh)
		rdo.radio_group = "split_placement"
		rdo.usr_placement = "left"
		rdo:setLabel("Left")
		rdo.wid_buttonAction = _radioPlacement
		if btn_spl.skin.aux_placement == rdo.usr_placement then
			rdo:setChecked(true)
		end
		yy = yy + hh
	end

	do
		local rdo = panel:addChild("barebones/radio_button")
		rdo:geometrySetMode("static", xx, yy, ww, hh)
		rdo.radio_group = "split_placement"
		rdo.usr_placement = "top"
		rdo:setLabel("Top")
		rdo.wid_buttonAction = _radioPlacement
		if btn_spl.skin.aux_placement == rdo.usr_placement then
			rdo:setChecked(true)
		end
		yy = yy + hh
	end

	do
		local rdo = panel:addChild("barebones/radio_button")
		rdo:geometrySetMode("static", xx, yy, ww, hh)
		rdo.radio_group = "split_placement"
		rdo.usr_placement = "bottom"
		rdo:setLabel("Bottom")
		rdo.wid_buttonAction = _radioPlacement
		if btn_spl.skin.aux_placement == rdo.usr_placement then
			rdo:setChecked(true)
		end
		yy = yy + hh
	end

	yy = yy + math.floor(hh/2)

	do
		local sld = panel:addChild("barebones/slider_bar")
		sld:geometrySetMode("static", xx, yy, ww, hh)
		sld.trough_vertical = false
		sld:setLabel("Aux Size")
		sld.slider_def = btn_spl.skin.aux_size
		sld.slider_pos = sld.slider_def
		sld.slider_max = 224
		sld.wid_actionSliderChanged = function(self)
			local btn = self:findSiblingTag("demo_split_btn")
			if btn then
				btn.skin.aux_size = math.floor(self.slider_pos)
				btn:reshape()
			end
		end
	end
end


return plan
