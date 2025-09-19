local plan = {}


local demoShared = require("demo_shared")
local pPath = require("prod_ui.lib.pile_path")


local function _configureInputBox(self)
	self:setSelectAllOnThimble1Take(true)
	self:setDeselectAllOnThimble1Release(true)
	self:setClearHistoryOnDeselect(true)
	self:setTextAlignment("center")
end


local function _updateScale(self)
	local context = self.context
	local btn = self.parent:findTag("btn_crt")
	if not btn then
		return
	end

	local scale, dpi, theme_id

	local in_scale = self.parent:findTag("in_scale")
	if in_scale then
		scale = tonumber(in_scale:getText())
	end
	local in_dpi = self.parent:findTag("in_dpi")
	if in_dpi then
		dpi = tonumber(in_dpi:getText())
	end

	local list_box = self.parent:findTag("themes_list")
	if list_box then
		local item = list_box.MN_items[list_box.MN_index]
		if item then
			theme_id = item.usr_dir_id
		end
	end

	if not scale then
		btn:setLabel("Bad scale")

	elseif not dpi then
		btn:setLabel("Bad DPI")

	elseif not theme_id then
		btn:setLabel("Bad/No theme")

	else
		local result = demoShared.executeThemeUpdate(context, scale, dpi, theme_id)
		if result == false then
			btn:setLabel("Unprovisioned DPI")
		else
			btn:setLabel("Update")
		end
	end
end


function plan.make(panel)
	local context = panel.context

	panel:layoutSetBase("viewport-width")
	panel:setScrollRangeMode("auto")
	panel:setScrollBars(false, true)

	demoShared.makeTitle(panel, nil, "Themes and Scale")

	demoShared.makeParagraph(panel, nil, "***Work in Progress***")

	demoShared.makeLabel(panel, 32, 96, 200, 32, "Theme", "single")
	local list_box = panel:addChild("wimp/list_box")
	list_box:geometrySetMode("static", 32, 96+40, 200, 96)
	list_box:setTag("themes_list")
	list_box.wid_action = _updateScale

	do
		local theme_ids = context:enumerateThemes()

		for i, id in ipairs(theme_ids) do
			local theme_details, err = context:getThemeInfo(id)
			if not theme_details then
				error(err)
			end

			if theme_details.present_to_user then
				local name = theme_details and theme_details.name or id
				local lb_item = list_box:addItem(name)

				-- in case the display name gets fluffed up:
				lb_item.usr_dir_id = id

				if id == context.theme_id then
					list_box:setSelection(lb_item)
				end
			end
		end
	end

	local xx, yy, ww, hh, h_pad = 32, 96+96+40+16, 160, 32, 8
	local input

	demoShared.makeLabel(panel, xx, yy, ww, hh, "Scale:", "single")

	yy = yy + hh + h_pad

	input = panel:addChild("input/text_box_single")
	input:geometrySetMode("static", xx, yy, ww, hh)
	_configureInputBox(input)
	input:setTag("in_scale")
	input:setText(tostring(context.scale))
	input.wid_action = _updateScale

	yy = yy + hh + h_pad

	demoShared.makeLabel(panel, xx, yy, ww, hh, "DPI:", "single")

	yy = yy + hh + h_pad

	input = panel:addChild("input/text_box_single")
	input:geometrySetMode("static", xx, yy, ww, hh)
	_configureInputBox(input)
	input:setTag("in_dpi")
	input:setText(tostring(context.dpi))
	input.wid_action = _updateScale

	yy = yy + hh + h_pad

	local btn = panel:addChild("base/button")
	btn:geometrySetMode("static", xx, yy, ww, hh)
	btn.tag = "btn_crt"
	btn:setLabel("Update")
	btn.wid_buttonAction = _updateScale

	yy = yy + hh + h_pad
end


return plan
