
-- A barebones renderer, available when debugging the other button skins.
-- Usage: assign directly to `def.render`.


local context = select(1, ...)


local lgcLabelBare = context:getLua("shared/lgc_label_bare")


return function(self, ox, oy)
	love.graphics.push("all")

	-- Checkboxes, radio buttons
	if self.enabled and self.checked then
		love.graphics.setColor(0.5, 0.5, 0.5, 1.0)
		if self.is_radio_button then
			love.graphics.ellipse("fill", self.w/2, self.h/2, self.w/2, self.h/2)
		else
			love.graphics.rectangle("fill", 0, 0, self.w, self.h)
		end
	end

	-- Outline
	if not self.enabled then
		love.graphics.setColor(0.5, 0.5, 0.5, 1.0)

	elseif self.pressed then
		love.graphics.setColor(0.25, 0.25, 0.25, 1.0)

	elseif self.hover then
		love.graphics.setColor(0.9, 0.9, 0.9, 1.0)

	else -- enabled
		love.graphics.setColor(0.8, 0.8, 0.8, 1.0)
	end

	love.graphics.setLineStyle("smooth")
	local line_width = math.max(1, math.floor(2 * self.context.scale))
	love.graphics.setLineWidth(line_width)
	love.graphics.setLineJoin("miter")
	love.graphics.rectangle("line", line_width/2, line_width/2, self.w - line_width, self.h - line_width)

	-- Label text -- single-line only, no underlines.
	lgcLabelBare.render(self, self.context.resources.fonts.internal, 1, 1, 1, 1)

	love.graphics.pop()
end
