-- ProdUI
local demoShared = require("demo_shared")


local plan = {}


function plan.make(panel)
	--title("Scroll bars")

	local context = panel.context

	panel:layoutSetBase("viewport-width")
	panel:containerSetScrollRangeMode("zero")
	panel:setScrollBars(false, false)

	demoShared.makeTitle(panel, nil, "Scroll Bars")
	demoShared.makeParagraph(panel, nil, "***This panel is buggy***")

	local box_w, box_h = 72, 72
	local boxes_x, boxes_y = 8, 8
	local doc_w, doc_h = box_w * boxes_x, box_h * boxes_y

	local cont = panel:addChild("base/container")
		:geometrySetMode("static", 16, 16, 256, 256, true)
		:setTag("scr_container")
		:containerSetScrollRangeMode("manual")
		:containerSetDocumentDimensions(doc_w, doc_h)
		:setScrollBars(true, true)

	-- See: demoShared.loadThemeDuplicateSkins()
	cont.scr_style = context.resources.scroll_bar_styles.norm_DEMO

	local colors = {"lightblue", "lightcyan", "lightgreen"}
	local color_i = 0

	for y = 0, boxes_y-1 do
		for x = 0, boxes_x-1 do
			cont:addChild("test/colorful_box")
				:geometrySetMode("static", x * box_w, y * box_h, box_w, box_h)
				:setColor(colors[color_i + 1], "darkgrey", "white")
				:setText(string.char(65 + x) .. tostring(y + 1))

				color_i = (color_i + 1) % #colors
		end
	end

	local function _updateNormScroll(self)
		-- NOTE: 'self' is any of the sibling controls.
		local norm = context.resources.scroll_bar_styles.norm_DEMO
		if not norm then
			error("missing expected scroll bar style ('norm_DEMO')")
		end

		local c_btns = self:findSiblingTag("scr_has_buttons")
		if c_btns then
			norm.has_buttons = c_btns:getChecked()
		end

		local c_trgh = self:findSiblingTag("scr_trough_enabled")
		if c_trgh then
			norm.trough_enabled = c_trgh:getChecked()
		end

		local c_thmb = self:findSiblingTag("scr_thumb_enabled")
		if c_thmb then
			norm.thumb_enabled = c_thmb:getChecked()
		end

		local c_v_near = self:findSiblingTag("scr_v_near_side")
		if c_v_near then
			norm.v_near_side = c_v_near:getChecked()
		end

		local c_h_near = self:findSiblingTag("scr_h_near_side")
		if c_h_near then
			norm.h_near_side = c_h_near:getChecked()
		end

		local c_bar_sz = self:findSiblingTag("scr_bar_size")
		if c_bar_sz then
			local v = c_bar_sz:getValue()
			if v then
				norm.bar_size = math.max(0, v)
			else
				print("WARNING: couldn't read 'bar_size' from control")
			end
		end

		local c_btn_sz = self:findSiblingTag("scr_button_size")
		if c_btn_sz then
			local v = c_bar_sz:getValue()
			if v then
				norm.button_size = math.max(0, v)
			else
				print("WARNING: couldn't read 'button_size' from control")
			end
		end

		local c_v_b1 = self:findSiblingTag("scr_v_button1_enabled")
		if c_v_b1 then
			norm.v_button1_enabled = c_v_b1:getChecked()
		end

		local c_v_b2 = self:findSiblingTag("scr_v_button2_enabled")
		if c_v_b2 then
			norm.v_button2_enabled = c_v_b2:getChecked()
		end

		local c_h_b1 = self:findSiblingTag("scr_h_button1_enabled")
		if c_h_b1 then
			norm.h_button1_enabled = c_h_b1:getChecked()
		end

		local c_h_b2 = self:findSiblingTag("scr_h_button2_enabled")
		if c_h_b2 then
			norm.h_button2_enabled = c_h_b2:getChecked()
		end

		local cont = self.parent:findTag("scr_container")
		if cont then
			cont:setScrollBars(true, true)
			cont:reshape()
		end
	end

	local xx, yy = 288, 16
	local ww, hh = 200, 32
	local half_ww = math.floor(ww / 2)
	local h_space = 8

	local norm = context.resources.scroll_bar_styles.norm_DEMO
	if not norm then
		error("missing expected scroll bar style ('norm_DEMO')")
	end

	do
		--has_buttons
		local chk = panel:addChild("base/checkbox")
			:geometrySetMode("static", xx, yy, ww, hh, true)
			:setTag("scr_has_buttons")
			:setLabel("Buttons")
			:userCallbackSet("cb_buttonAction", _updateNormScroll)
			:setChecked(norm.has_buttons)

		yy = yy + hh + h_space
	end

	do
		--trough_enabled
		local chk = panel:addChild("base/checkbox")
			:geometrySetMode("static", xx, yy, ww, hh, true)
			:setTag("scr_trough_enabled")
			:setLabel("Trough")
			:userCallbackSet("cb_buttonAction", _updateNormScroll)
			:setChecked(norm.trough_enabled)

		yy = yy + hh + h_space
	end

	do
		--thumb_enabled
		local chk = panel:addChild("base/checkbox")
			:geometrySetMode("static", xx, yy, ww, hh, true)
			:setTag("scr_thumb_enabled")
			:setLabel("Thumb")
			:userCallbackSet("cb_buttonAction", _updateNormScroll)
			:setChecked(norm.thumb_enabled)

		yy = yy + hh + h_space
	end

	do
		--v_near_side
		local chk = panel:addChild("base/checkbox")
			:geometrySetMode("static", xx, yy, ww, hh, true)
			:setTag("scr_v_near_side")
			:setLabel("Right Side")
			:userCallbackSet("cb_buttonAction", _updateNormScroll)
			:setChecked(norm.v_near_side)

		yy = yy + hh + h_space
	end

	do
		--h_near_side
		local chk = panel:addChild("base/checkbox")
			:geometrySetMode("static", xx, yy, ww, hh, true)
			:setTag("scr_h_near_side")
			:setLabel("Bottom Side")
			:userCallbackSet("cb_buttonAction", _updateNormScroll)
			:setChecked(norm.h_near_side)

		yy = yy + hh + h_space
	end

	do
		--bar_size
		demoShared.makeLabel(panel, xx, yy, ww, hh, true, "Bar Size", "single")
		yy = yy + hh + h_space

		local nbx = panel:addChild("wimp/number_box")
			:geometrySetMode("static", xx, yy, ww, hh, true)
			:setTag("scr_bar_size")
			:userCallbackSet("cb_action", _updateNormScroll)
			:setValue(norm.bar_size)

		yy = yy + hh + h_space
	end

	do
		--button_size
		demoShared.makeLabel(panel, xx, yy, ww, hh, true, "Button Size", "single")
		yy = yy + hh + h_space

		local nbx = panel:addChild("wimp/number_box")
			:geometrySetMode("static", xx, yy, ww, hh, true)
			:setTag("scr_button_size")
			:userCallbackSet("cb_action", _updateNormScroll)
			:setValue(norm.bar_size)

		yy = yy + hh + h_space
	end

	-- TODO…
	--thumb_size_min = 16,
	--thumb_size_max = 2^16,

	do
		--v_button1_enabled
		local c1 = panel:addChild("base/checkbox")
			:geometrySetMode("static", xx, yy, half_ww, hh, true)
			:setTag("scr_v_button1_enabled")
			:setLabel("'^'")
			:userCallbackSet("cb_buttonAction", _updateNormScroll)
			:setChecked(norm.v_button1_enabled)

		--v_button2_enabled
		local c2 = panel:addChild("base/checkbox")
			:geometrySetMode("static", half_ww + xx, yy, half_ww, hh, true)
			:setTag("scr_v_button2_enabled")
			:setLabel("'v'")
			:userCallbackSet("cb_buttonAction", _updateNormScroll)
			:setChecked(norm.v_button2_enabled)

		yy = yy + hh + h_space
	end

	do
		--h_button1_enabled
		local c1 = panel:addChild("base/checkbox")
			:geometrySetMode("static", xx, yy, half_ww, hh, true)
			:setTag("scr_h_button1_enabled")
			:setLabel("'<'")
			:userCallbackSet("cb_buttonAction", _updateNormScroll)
			:setChecked(norm.h_button1_enabled)

		--h_button2_enabled
		local c2 = panel:addChild("base/checkbox")
			:geometrySetMode("static", half_ww + xx, yy, half_ww, hh, true)
			:setTag("scr_h_button2_enabled")
			:setLabel("'>'")
			:userCallbackSet("cb_buttonAction", _updateNormScroll)
			:setChecked(norm.h_button2_enabled)

		yy = yy + hh + h_space
	end

	-- Some settings are omitted, because the demo cannot sufficiently illustrate them, or they
	-- clutter up the control space, or they are inscrutable to passers-by without more context:

	--v_auto_hide = false
	--v_button1_mode = "pend-cont",
	--v_button2_mode = "pend-cont",
	--h_auto_hide = false,
	--h_button1_mode = "pend-cont",
	--h_button2_mode = "pend-cont",

	-- Library users can experiment with these settings by directly editing the theme.
	-- See: scroll_bar_styles, scroll_bar_data.
end


return plan
