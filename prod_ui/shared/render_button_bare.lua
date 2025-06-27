
-- Barebones renderers, available when debugging the other button skins.
-- Usage: assign function directly to `def.render`.


local context = select(1, ...)


local renderers = {}


local lgcLabelBare = context:getLua("shared/lgc_label_bare")
local pTable = require(context.conf.prod_ui_req .. "lib.pile_table")
local uiGraphics = require(context.conf.prod_ui_req .. "ui_graphics")


local base_data = {
	col_edge_enabled = {1.0, 1.0, 1.0, 1.0},
	col_edge_disabled = {0.75, 0.75, 0.75, 1.0},
	col_edge_pressed = {0.8, 0.8, 0.8, 1.0},
	col_edge_hover = {1.0, 1.0, 1.0, 1.0},
	col_accent = {0.8, 0.8, 0.8, 1.0},
	col_text = {1.0, 1.0, 1.0, 1.0}
}


local function _determineMainColor(self, inf)
	if not self.enabled then
		return inf.col_edge_disabled

	elseif self.pressed then
		return inf.col_edge_pressed

	elseif self.hover then
		return inf.col_edge_hover

	else -- enabled
		return inf.col_edge_enabled
	end
end


function renderers.buttons(self, ox, oy)
	local inf = pTable.resolve(self.context.resources, "info/barebones_info") or base_data
	love.graphics.push("all")

	-- Checkboxes, radio buttons
	if self.enabled and self.checked then
		love.graphics.setColor(inf.col_accent)
		if self.is_radio_button then
			love.graphics.ellipse("fill", self.w/2, self.h/2, self.w/2, self.h/2)
		else
			love.graphics.rectangle("fill", 0, 0, self.w, self.h)
		end
	end

	local col_main = _determineMainColor(self, inf)
	love.graphics.setColor(col_main)

	-- Outline
	love.graphics.setLineStyle("smooth")
	local line_width = math.max(1, math.floor(2 * self.context.scale))
	love.graphics.setLineWidth(line_width)
	love.graphics.setLineJoin("miter")
	love.graphics.rectangle("line", line_width/2, line_width/2, self.w - line_width, self.h - line_width)

	-- Label text -- single-line only, no underlines.
	lgcLabelBare.render(self, self.context.resources.fonts.internal, col_main[1], col_main[2], col_main[3], col_main[4])

	love.graphics.pop()
end


function renderers.inputBox(self, ox, oy)
	local inf = pTable.resolve(self.context.resources, "info/barebones_info") or base_data
	love.graphics.push("all")

	local scale = self.context.scale
	local font = self.context.resources.fonts.internal

	local line_w = math.floor(1.0 * scale)
	local caret_w = math.floor(2.0 * scale)
	local margin_w = math.floor(8.0 * scale)

	love.graphics.setColor(_determineMainColor(self, inf))

	-- Body.
	love.graphics.setLineStyle("smooth")
	love.graphics.setLineWidth(line_w)
	love.graphics.rectangle("line", 0.5, 0.5, self.w - 1, self.h - 1)

	uiGraphics.intersectScissor(ox + self.x, oy + self.y, self.w, self.h)

	-- Horizontal scroll offset. The caret should always be in view.
	local offset_x = -math.max(0, self.text_w + caret_w + margin_w*2 - self.w)

	-- Center text vertically.
	local font_h = math.floor(font:getHeight() * font:getLineHeight())
	local offset_y = math.floor(0.5 + (self.h - font_h) / 2)

	-- Text.
	love.graphics.setFont(font)
	love.graphics.print(self.text, margin_w + offset_x, offset_y) -- Alignment

	-- Caret.
	if self.context.thimble1 == self then
		love.graphics.rectangle("fill", margin_w + offset_x + self.text_w, offset_y, caret_w, font_h)
	end

	love.graphics.pop()
end


function renderers.label(self, ox, oy)
	local inf = pTable.resolve(self.context.resources, "info/barebones_info") or base_data
	local c = self.enabled and inf.col_edge_enabled or inf.col_edge_disabled
	local r, g, b, a = c[1], c[2], c[3], c[4]

	lgcLabelBare.render(self, self.context.resources.fonts.internal, r, g, b, a)
end


function renderers.slider(self, ox, oy)
	local inf = pTable.resolve(self.context.resources, "info/barebones_info") or base_data
	love.graphics.push("all")

	local col_main = _determineMainColor(self, inf)
	love.graphics.setColor(col_main)

	-- Outline
	love.graphics.setLineStyle("smooth")
	local line_width = math.max(1, math.floor(2 * self.context.scale))
	love.graphics.setLineWidth(line_width)
	love.graphics.setLineJoin("miter")
	love.graphics.rectangle("line", line_width/2, line_width/2, self.w - line_width, self.h - line_width)

	-- The trough is not rendered.

	-- Thumb
	love.graphics.setColor(inf.col_accent)
	love.graphics.rectangle(
		"fill",
		self.thumb_x,
		self.thumb_y,
		self.thumb_w,
		self.thumb_h
	)

	-- Label text -- single-line only, no underlines.
	love.graphics.setColor(col_main)
	lgcLabelBare.render(self, self.context.resources.fonts.internal, col_main[1], col_main[2], col_main[3], col_main[4])

	love.graphics.pop()
end


return renderers
