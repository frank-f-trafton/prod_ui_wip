local plan = {}


local demoShared = require("demo_shared")


local function _updateScale(self)
	local context = self.context
	local btn = self.parent:findTag("btn_crt")
	if not btn then
		return
	end
	local old_scale, old_dpi = context:getScale(), context:getDPI()
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
		self:setLabel("Bad scale.")

	elseif not dpi then
		self:setLabel("Bad DPI.")

	else
		-- A dirty hack to prevent attempting (and failing) to load non-existent sets of textures.
		-- TODO: Probably need to declare valid DPI numbers somewhere.
		local tex_dir = love.filesystem.getInfo(context.conf.prod_ui_path .. "resources/textures/" .. tostring(dpi), "directory")
		if not tex_dir then
			btn:setLabel("Unprovisioned DPI")
		else
			context:setScale(scale)
			context:setDPI(dpi)

			if not (scale == old_scale and dpi == old_dpi) then
				local theme = demoShared.loadTheme()

				context.root:forEach(function(self) if self.skinner then self:skinRemove() end end)
				context:applyTheme(theme)
				context.root:forEach(function(self) if self.skinner then self:skinSetRefs(); self:skinInstall() end end)
				context.root:reshape()
			end
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
	input.x, input.y, input.w, input.h = xx2, yy, ww, hh
	input:initialize()
	input:setTag("in_scale")
	input:setText(tostring(panel.context.scale))
	input.wid_action = _updateScale

	yy = yy + hh + h_pad

	demoShared.makeLabel(panel, 32, 128, 160, 32, "DPI:", "single")
	input = panel:addChild("input/text_box_single")
	input.x, input.y, input.w, input.h = xx2, yy, ww, hh
	input:initialize()
	input:setTag("in_dpi")
	input:setText(tostring(panel.context.dpi))
	input.wid_action = _updateScale

	yy = yy + hh + h_pad

	--input:setText("Single-Line Text Box")

	local btn = panel:addChild("base/button")
	btn.x, btn.y, btn.w, btn.h = xx2, yy, ww, hh
	btn:initialize()
	btn.tag = "btn_crt"
	btn:setLabel("Update")
	btn.wid_buttonAction = _updateScale

	yy = yy + hh + h_pad
end


return plan
