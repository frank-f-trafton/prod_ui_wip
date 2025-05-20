local plan = {}


local demoShared = require("demo_shared")


function plan.make(panel)
	panel:setLayoutBase("viewport-width")
	panel:setScrollRangeMode("auto")
	panel:setScrollBars(false, true)

	demoShared.makeTitle(panel, nil, "Scaling")

	demoShared.makeParagraph(panel, nil, "***Under construction*** --> This feature doesn't work yet.")

	local input

	local xx1, xx2, yy, ww, hh, h_pad = 32, 192, 96, 160, 32, 8

	demoShared.makeLabel(panel, xx1, yy, ww, hh, "Scale:", "single")
	input = panel:addChild("input/text_box_single")
	input.x, input.y, input.w, input.h = xx2, yy, ww, hh
	input:initialize()
	input:setTag("in_scale")
	input:setText(tostring(panel.context.scale))

	input.wid_action = function(self)
		-- …
	end

	yy = yy + hh + h_pad

	demoShared.makeLabel(panel, 32, 128, 160, 32, "DPI:", "single")
	input = panel:addChild("input/text_box_single")
	input.x, input.y, input.w, input.h = xx2, yy, ww, hh
	input:initialize()
	input:setTag("in_dpi")
	input:setText(tostring(panel.context.dpi))

	input.wid_action = function(self)
		-- …
	end

	yy = yy + hh + h_pad

	--input:setText("Single-Line Text Box")

	local btn = panel:addChild("base/button")
	btn.x, btn.y, btn.w, btn.h = xx2, yy, ww, hh
	btn:initialize()
	btn.tag = "btn_crt"
	btn:setLabel("Update")
	btn.wid_buttonAction = function(self)
		local context = self.context

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
			if scale ~= old_scale then
				context:setScale(scale)
			end
			if dpi ~= old_dpi then
				context:setDPI(dpi)
			end
			if not (scale == old_scale and dpi == old_dpi) then
				self.context.root:reshape()
			end
		end
	end

	yy = yy + hh + h_pad
end


return plan
