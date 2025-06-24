local plan = {}


local demoShared = require("demo_shared")


local function _configureInputBox(self)
	self.select_all_on_thimble1_take = true
	self.deselect_all_on_thimble1_release = true
	self.clear_history_on_deselect = true
end


local function _updateScale(self)
	local context = self.context
	local btn = self.parent:findTag("btn_crt")
	if not btn then
		return
	end

	local scale, dpi

	local in_scale = self.parent:findTag("in_scale")
	if in_scale then
		scale = tonumber(in_scale:getText())
	end
	local in_dpi = self.parent:findTag("in_dpi")
	if in_dpi then
		dpi = tonumber(in_dpi:getText())
	end

	if not scale then
		btn:setLabel("Bad scale.")

	elseif not dpi then
		btn:setLabel("Bad DPI.")

	else
		local result = demoShared.executeThemeUpdate(context, scale, dpi, "vacuum_dark")
		if result == false then
			btn:setLabel("Unprovisioned DPI")
		else
			btn:setLabel("Update")
		end
	end
end


function plan.make(panel)
	panel:setLayoutBase("viewport-width")
	panel:setScrollRangeMode("auto")
	panel:setScrollBars(false, true)

	demoShared.makeTitle(panel, nil, "Scaling")

	demoShared.makeParagraph(panel, nil, "***Work in Progress***")

	local input

	local xx1, xx2, yy, ww, hh, h_pad = 32, 192, 96, 160, 32, 8

	demoShared.makeLabel(panel, xx1, yy, ww, hh, "Scale:", "single")
	input = panel:addChild("input/text_box_single")
	input:initialize()
	demoShared.setStaticLayout(panel, input, xx2, yy, ww, hh)
	_configureInputBox(input)
	input:setTag("in_scale")
	input:setText(tostring(panel.context.scale))
	input.wid_action = _updateScale

	yy = yy + hh + h_pad

	demoShared.makeLabel(panel, 32, 128, 160, 32, "DPI:", "single")
	input = panel:addChild("input/text_box_single")
	input:initialize()
	demoShared.setStaticLayout(panel, input, xx2, yy, ww, hh)
	_configureInputBox(input)
	input:setTag("in_dpi")
	input:setText(tostring(panel.context.dpi))
	input.wid_action = _updateScale

	yy = yy + hh + h_pad

	--input:setText("Single-Line Text Box")

	local btn = panel:addChild("base/button")
	btn:initialize()
	demoShared.setStaticLayout(panel, btn, xx2, yy, ww, hh)
	btn.tag = "btn_crt"
	btn:setLabel("Update")
	btn.wid_buttonAction = _updateScale

	yy = yy + hh + h_pad
end


return plan
