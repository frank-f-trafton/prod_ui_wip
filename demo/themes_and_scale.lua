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


local function _pollTextureDPIs(tex_path)
	-- Gets a list of valid texture DPIs by scanning the 'textures' directory
	-- for subdirectories whose names are made up of digits.
	local ls = love.filesystem.getDirectoryItems(tex_path)
	local list = {}
	for i, name in ipairs(ls) do
		local info = love.filesystem.getInfo(tex_path .. "/" .. name)
		if info then
			if (info.type == "directory") and name:match("^%d+$") and tonumber(name) then
				table.insert(list, tonumber(name))
			end
		end
	end

	table.sort(list)
	for i, n in ipairs(list) do
		list[i] = tostring(n)
	end

	return list
end


function plan.make(panel)
	local context = panel.context

	panel:layoutSetBase("viewport-width")
	panel:containerSetScrollRangeMode("auto")
	panel:setScrollBars(false, true)

	demoShared.makeTitle(panel, nil, "Themes and Scale")

	local dpi_list = _pollTextureDPIs(context.conf.prod_ui_path .. "resources/textures")
	demoShared.makeParagraph(panel, nil, "(Valid DPIs are: " .. table.concat(dpi_list, ", ") .. ")")

	demoShared.makeLabel(panel, 32, 96, 200, 32, false, "Theme", "single")
	local list_box = panel:addChild("wimp/list_box")
	list_box:geometrySetMode("static", 32, 96+40, 200, 96)
		:setTag("themes_list")
		:userCallbackSet("cb_action", _updateScale)

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

	demoShared.makeLabel(panel, xx, yy, ww, hh, false, "Scale:", "single")

	yy = yy + hh + h_pad

	input = panel:addChild("input/text_box_single")
	input:geometrySetMode("static", xx, yy, ww, hh)
	_configureInputBox(input)
	input:setTag("in_scale")
		:setText(tostring(context.scale))
		:userCallbackSet("cb_action", _updateScale)

	yy = yy + hh + h_pad

	demoShared.makeLabel(panel, xx, yy, ww, hh, false, "DPI:", "single")

	yy = yy + hh + h_pad

	input = panel:addChild("input/text_box_single")
	input:geometrySetMode("static", xx, yy, ww, hh)
	_configureInputBox(input)
	input:setTag("in_dpi")
		:setText(tostring(context.dpi))
		:userCallbackSet("cb_action", _updateScale)

	yy = yy + hh + h_pad

	local btn = panel:addChild("base/button")
	btn:geometrySetMode("static", xx, yy, ww, hh)
		:setTag("btn_crt")
		:setLabel("Update")
		:userCallbackSet("cb_buttonAction", _updateScale)

	yy = yy + hh + h_pad
end


return plan
